--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")

local Network = require(ReplicatedStorage.Library.Network)
local MobTypes = require(ReplicatedStorage.Shared.Types.MobTypes)
local MobClass = require(ServerStorage.Classes.Mob)
local SpawnZoneClass = require(ServerStorage.Classes.SpawnZone)

type Mob = MobClass.Mob
type SpawnZone = SpawnZoneClass.SpawnZoneInstance
type MobData = MobTypes.MobData
type MobState = MobTypes.MobState

local MobsService = {
	Name = "MobsService",
	Client = {},
}

local activeMobs: { [string]: Mob } = {}
local spawnZones: { [string]: SpawnZone } = {}
local updateInterval: number = 0.5
local lastUpdate: number = 0

local function broadcastMobSpawn(mob: Mob): ()
	Network.FireAll("MobsService:MobSpawned", {
		action = "spawn",
		mobData = mob.Data,
	})
end

local function broadcastMobUpdate(mobId: string, updateData: any): ()
	Network.FireAll("MobsService:MobUpdated", updateData)
end

local function broadcastMobDespawn(mobId: string, reason: "timeout" | "killed" | "delivered"): ()
	Network.FireAll("MobsService:MobDespawned", {
		action = "despawn",
		mobId = mobId,
		reason = reason,
	})
end

local function findGroundPosition(position: Vector3): Vector3
	local rayOrigin: Vector3 = Vector3.new(position.X, position.Y + 50, position.Z)
	local rayDirection: Vector3 = Vector3.new(0, -100, 0)

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude

	local mobsFolder = workspace:FindFirstChild("Mobs")
	if mobsFolder then
		raycastParams.FilterDescendantsInstances = { mobsFolder }
	else
		raycastParams.FilterDescendantsInstances = {}
	end

	local result = workspace:Raycast(rayOrigin, rayDirection, raycastParams)

	if result then
		return result.Position + Vector3.new(0, 3, 0)
	end

	return Vector3.new(position.X, position.Y, position.Z)
end

function MobsService:SpawnMob(typeId: string, position: Vector3, extraOptions: { [string]: any }?): Mob?
	position = findGroundPosition(position)

	local mob: Mob? = MobClass.new(typeId, position, extraOptions)

	if not mob then
		return nil
	end

	activeMobs[mob.Data.Id] = mob
	print(`[MobsService] Mob spawned: {mob.Data.TypeId} ({mob.Data.Id})`)

	broadcastMobSpawn(mob)

	return mob
end

function MobsService:GetMob(mobId: string): Mob?
	return activeMobs[mobId]
end

function MobsService:GetAllMobs(): { [string]: Mob }
	return activeMobs
end

function MobsService:DespawnMob(mobId: string, reason: "timeout" | "killed" | "delivered"): ()
	local mob: Mob? = activeMobs[mobId]

	if not mob then
		return
	end

	for _, zone: SpawnZone in pairs(spawnZones) do
		zone:UnregisterMob(mobId)
	end

	broadcastMobDespawn(mobId, reason)

	mob:Destroy()
	activeMobs[mobId] = nil
end

function MobsService:CreateSpawnZone(config: MobTypes.SpawnZone): SpawnZone
	local zone: SpawnZone = SpawnZoneClass.new(config)
	spawnZones[config.Name] = zone

	zone:Start(function(typeId: string, position: Vector3)
		local mob: Mob? = self:SpawnMob(typeId, position)

		if mob then
			zone:RegisterMob(mob.Data.Id)
		end
	end)

	return zone
end

function MobsService:RemoveSpawnZone(zoneName: string): ()
	local zone: SpawnZone? = spawnZones[zoneName]

	if zone then
		zone:Destroy()
		spawnZones[zoneName] = nil
	end
end

function MobsService:UpdateMobs(deltaTime: number): ()
	for mobId: string, mob: Mob in pairs(activeMobs) do
		if mob:ShouldDespawn() and mob.Data.State ~= "BeingCarried" then
			self:DespawnMob(mobId, "timeout")
			continue
		end

		if not (mob.Data.State == "BeingCarried") 
			and mob.Data.State == "Wandering" then
			local target: Vector3? = mob:GetWanderTarget()

			if target then
				target = findGroundPosition(target)

				mob:UpdatePosition(target)

				broadcastMobUpdate(mobId, {
					action = "update",
					mobId = mobId,
					position = target,
				})
			end
		elseif not (mob.Data.State == "BeingCarried") 
			and mob.Data.State == "Returning" then
			local target: Vector3 = mob:GetReturnTarget()
			target = findGroundPosition(target)

			mob:UpdatePosition(target)

			broadcastMobUpdate(mobId, {
				action = "update",
				mobId = mobId,
				position = target,
			})
		end
	end
end

function MobsService.Client:GetAllMobsData(player: Player): { MobData }

	local mobsData: { MobData } = {}

	for _, mob: Mob in pairs(activeMobs) do
		table.insert(mobsData, mob.Data)
	end

	return mobsData
end

function MobsService.Client:RequestCarryMob(player: Player, mobId: string): boolean
	if typeof(mobId) ~= "string" then
		mobId = tostring(mobId)
	end

	local mob: Mob? = activeMobs[mobId]

	if not mob then
		for id, _ in pairs(activeMobs) do
			warn(`{id}`)
		end
		return false
	end

	if mob.Data.State ~= "Wandering" then
		return false
	end

	local character: Model? = player.Character
	if not character then
		return false
	end

	local humanoidRootPart: BasePart = character:FindFirstChild("HumanoidRootPart") :: BasePart
	if not humanoidRootPart then
		return false
	end

	local distance: number = (humanoidRootPart.Position - mob.Data.Position).Magnitude
	if distance > 15 then
		return false
	end

	local success: boolean = mob:StartCarrying(player)

	if success then
		broadcastMobUpdate(mobId, {
			action = "update",
			mobId = mobId,
			state = "BeingCarried",
			carriedBy = player,
		})
	else
		warn(`[MobsService] Error on {mobId}`)
	end

	return success
end

function MobsService.Client:StopCarryingMob(player: Player, mobId: string, delivered: boolean): boolean
	if typeof(mobId) ~= "string" then
		mobId = tostring(mobId)
	end

	local mob: Mob? = activeMobs[mobId]

	if not mob then
		return false
	end

	if mob.Data.CarriedBy ~= player then
		return false
	end

	mob:StopCarrying(delivered)

	if delivered then
		print(`[MobsService] {player.Name} delivered {mobId}`)
	else
		broadcastMobUpdate(mobId, {
			action = "update",
			mobId = mobId,
			state = "Returning",
			carriedBy = nil,
		})
	end

	return true
end

function MobsService.Client:DamageMob(player: Player, mobId: string, damage: number): boolean
	if typeof(mobId) ~= "string" then
		mobId = tostring(mobId)
	end

	local mob: Mob? = activeMobs[mobId]

	if not mob then
		return false
	end

	if damage <= 0 or damage > 100 then
		return false
	end

	mob:Damage(damage, player)

	return true
end

function MobsService:Init(): () end

function MobsService:Start(): ()
	if not workspace:FindFirstChild("Mobs") then
		local mobsFolder: Folder = Instance.new("Folder")
		mobsFolder.Name = "Mobs"
		mobsFolder.Parent = workspace
	end

	task.wait(2)

	MobsService:CreateSpawnZone({
		Name = "TestArea",
		Center = Vector3.new(0, 50, 0),
		Size = Vector3.new(50, 0, 50),
		MaxMobs = 2,
		SpawnInterval = 5,
		MobTypes = { "Generic" },
		Seed = 12345,
	})

	RunService.Heartbeat:Connect(function(deltaTime: number)
		local currentTime: number = os.clock()

		if currentTime - lastUpdate >= updateInterval then
			self:UpdateMobs(deltaTime)
			lastUpdate = currentTime
		end
	end)
end

return MobsService