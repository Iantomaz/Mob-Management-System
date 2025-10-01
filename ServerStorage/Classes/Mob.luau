--!strict
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MobTypes = require(ReplicatedStorage.Shared.Types.MobTypes)
local MobConfigs = require(ReplicatedStorage.Shared.Configs.MobConfigs)

type MobData = MobTypes.MobData
type MobConfig = MobTypes.MobConfig
type MobState = MobTypes.MobState
type MobMutation = MobTypes.MobMutation
type Vector2D = MobTypes.Vector2D

local Mob = {}
Mob.__index = Mob

export type Mob = {
	Data: MobData,
	Config: MobConfig,

	_wanderTarget: Vector3?,
	_wanderCooldown: number,
	_lastUpdate: number,
	_despawnScheduled: boolean,

	Damage: (self: Mob, damage: number, attacker: Player?) -> (),
	StartCarrying: (self: Mob, player: Player) -> boolean,
	StopCarrying: (self: Mob, delivered: boolean) -> (),
	UpdatePosition: (self: Mob, position: Vector3) -> (),
	UpdateState: (self: Mob, newState: MobState) -> (),
	GetWanderTarget: (self: Mob) -> Vector3?,
	GetReturnTarget: (self: Mob) -> Vector3,
	ShouldDespawn: (self: Mob) -> boolean,
	Despawn: (self: Mob, reason: "timeout" | "killed" | "delivered") -> (),
	Destroy: (self: Mob) -> (),
}

type MobInternal = Mob & {
	_generateMutations: (self: MobInternal) -> { MobMutation },
	_notifyUpdate: (self: MobInternal, updateData: any) -> (),
}

local function randomInRadius(center: Vector2D, radius: number): Vector3
	local angle: number = math.random() * math.pi * 2
	local distance: number = math.random() * radius

	local x: number = center.X + math.cos(angle) * distance
	local z: number = center.Z + math.sin(angle) * distance

	return Vector3.new(x, 0, z)
end

function Mob.new(typeId: string, spawnPosition: Vector3, extraOptions: { [string]: any }?): Mob?
	local config: MobConfig? = MobConfigs.Get(typeId)
	if not config then
		warn(`[Mob] Invalid Type: {typeId}`)
		return nil
	end

	local self = setmetatable({} :: any, Mob) :: MobInternal

	local mobId: string = HttpService:GenerateGUID(false)

	local size: number = config.BaseSize
	local lifetime: number = config.DefaultLifetime

	if extraOptions then
		size = extraOptions.Size or size
		lifetime = extraOptions.Lifetime or lifetime
	end

	self.Data = {
		Id = mobId,
		TypeId = typeId,
		State = "Wandering",
		Health = config.BaseHealth,
		MaxHealth = config.BaseHealth,
		Position = spawnPosition,
		BasePosition = {
			X = spawnPosition.X,
			Z = spawnPosition.Z,
		},
		WanderRadius = config.WanderRadius,
		Mutations = {},
		CarriedBy = nil,
		SpawnedAt = os.time(),
		Lifetime = lifetime,
		Size = size,
	}

	self.Config = config

	self._wanderTarget = nil
	self._wanderCooldown = 0
	self._lastUpdate = os.clock()
	self._despawnScheduled = false

	if config.CanBeMutated and math.random() < config.MutationChance then
		self.Data.Mutations = self:_generateMutations()
	end

	return self :: Mob
end

function Mob._generateMutations(self: MobInternal): { MobMutation }
	local mutations: { MobMutation } = {}
	local possibleMutations: { string } = self.Config.PossibleMutations

	local mutationCount: number = math.random(1, 2)

	for i = 1, mutationCount do
		if #possibleMutations == 0 then
			break
		end

		local mutationType: string = possibleMutations[math.random(#possibleMutations)]

		local mutationValue: any = nil

		if mutationType == "Size" then
			mutationValue = math.random(70, 150) / 100
			self.Data.Size *= mutationValue

		elseif mutationType == "Color" then
			mutationValue = Color3.fromHSV(math.random(), 0.6 + math.random() * 0.4, 0.8 + math.random() * 0.2)

		elseif mutationType == "Speed" then
			mutationValue = math.random(80, 120) / 100

		elseif mutationType == "Glow" then
			mutationValue = true
		end

		table.insert(mutations, {
			Type = mutationType,
			Value = mutationValue,
		})
	end

	return mutations
end

function Mob._notifyUpdate(self: MobInternal, updateData: any): ()
end

function Mob.Damage(self: MobInternal, damage: number, attacker: Player?): ()
	if self.Data.State == "Dead" then
		return
	end

	self.Data.Health = math.max(0, self.Data.Health - damage)

	if self.Data.State == "BeingCarried" and self.Config.DropOnDamage then
		self:StopCarrying(false)
	end

	if self.Data.Health <= 0 then
		self:UpdateState("Dead")
		task.delay(2, function()
			self:Despawn("killed")
		end)
	end
end

function Mob.StartCarrying(self: MobInternal, player: Player): boolean
	if self.Data.State ~= "Wandering" then
		return false
	end

	self.Data.CarriedBy = player
	self:UpdateState("BeingCarried")

	return true
end

function Mob.StopCarrying(self: MobInternal, delivered: boolean): ()
	if self.Data.State ~= "BeingCarried" then
		return
	end

	self.Data.CarriedBy = nil

	if delivered then
		self:Despawn("delivered")
	else
		self:UpdateState("Returning")

		task.delay(2, function()
			if not (self.Data.State == "BeingCarried") 
				and self.Data.State == "Returning" then
				self:UpdateState("Wandering")
			end
		end)
	end
end

function Mob.UpdatePosition(self: MobInternal, position: Vector3): ()
	self.Data.Position = position
	self._lastUpdate = os.clock()
end

function Mob.UpdateState(self: MobInternal, newState: MobState): ()
	if self.Data.State == newState then
		return
	end

	local oldState: MobState = self.Data.State
	self.Data.State = newState
end

function Mob.GetWanderTarget(self: MobInternal): Vector3?
	if self._wanderTarget and self._wanderCooldown > os.clock() then
		return self._wanderTarget
	end

	self._wanderTarget = randomInRadius(self.Data.BasePosition, self.Data.WanderRadius)
	self._wanderCooldown = os.clock() + math.random(3, 8)

	return self._wanderTarget
end

function Mob.GetReturnTarget(self: MobInternal): Vector3
	return Vector3.new(self.Data.BasePosition.X, self.Data.Position.Y, self.Data.BasePosition.Z)
end

function Mob.ShouldDespawn(self: MobInternal): boolean
	local aliveTime: number = os.time() - self.Data.SpawnedAt
	return aliveTime >= self.Data.Lifetime
end

function Mob.Despawn(self: MobInternal, reason: "timeout" | "killed" | "delivered"): ()
	if self._despawnScheduled then
		return
	end

	self._despawnScheduled = true
end

function Mob.Destroy(self: MobInternal): ()
	table.clear(self.Data)
	table.clear(self)
	setmetatable(self, nil)
end

return Mob