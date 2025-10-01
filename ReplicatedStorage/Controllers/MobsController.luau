--!strict

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local NetworkAPI = require(ReplicatedStorage.Library.NetworkAPI)
local ServiceRegistry = require(ReplicatedStorage.Core.ServiceRegistry)
local MobClientClass = require(ReplicatedStorage.Classes.MobClient)
local MobTypes = require(ReplicatedStorage.Shared.Types.MobTypes)

type MobClient = MobClientClass.MobClient
type MobData = MobTypes.MobData
type MobState = MobTypes.MobState

local MobsController = {
	Name = "MobsController",
}

local player: Player = Players.LocalPlayer
local activeMobs: { [string]: MobClient } = {}
local carryingMob: string? = nil
local proximityPrompts: { [string]: ProximityPrompt } = {}

local function createProximityPrompt(mob: MobClient): ProximityPrompt?
	if not mob.Model or not mob.Model.PrimaryPart then
		warn(`[MobsController] Cannot create prompt: Model or PrimaryPart missing`)
		return nil
	end

	local existingPrompt: ProximityPrompt = mob.Model.PrimaryPart:FindFirstChild("CarryPrompt") :: ProximityPrompt
	if existingPrompt then
		existingPrompt:Destroy()
	end

	local prompt: ProximityPrompt = Instance.new("ProximityPrompt")
	prompt.Name = "CarryPrompt"
	prompt.ActionText = `Carry {mob.Data.TypeId}`
	prompt.ObjectText = mob.Data.TypeId
	prompt.MaxActivationDistance = 10
	prompt.HoldDuration = 1
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.Enabled = true
	prompt.Parent = mob.Model.PrimaryPart

	local connection: RBXScriptConnection = prompt.Triggered:Connect(function(playerWhoTriggered: Player)
		if playerWhoTriggered ~= player then
			return
		end

		if carryingMob then
			warn("[MobsController] Already carrying a mob")
			return
		end

		local MobsService = ServiceRegistry.MobsServiceAsync()
		local success: boolean = MobsService.RequestCarryMob(mob.Data.Id)

		if success then
			carryingMob = mob.Data.Id
			print(`[MobsController] Carrying mob: {mob.Data.Id}`)

			prompt.Enabled = false
		else
			warn(`[MobsController] Failed to carry mob: {mob.Data.Id}`)
		end
	end)

	return prompt
end

local function removeProximityPrompt(mobId: string): ()
	local prompt: ProximityPrompt? = proximityPrompts[mobId]
	if prompt then
		prompt:Destroy()
		proximityPrompts[mobId] = nil
	end

	local mob: MobClient? = activeMobs[mobId]
	if mob and mob.Model and mob.Model.PrimaryPart then
		local existingPrompt: ProximityPrompt = mob.Model.PrimaryPart:FindFirstChild("CarryPrompt") :: ProximityPrompt
		if existingPrompt then
			existingPrompt:Destroy()
		end
	end
end

local function ensureProximityPrompt(mobId: string): ()
	local mob: MobClient? = activeMobs[mobId]
	if not mob then
		return
	end

	if mob.Data.State ~= "Returning" 
		and mob.Data.State ~= "Wandering" then
		return
	end

	if proximityPrompts[mobId] then
		local prompt: ProximityPrompt = proximityPrompts[mobId]
		if prompt.Parent then
			prompt.Enabled = true
			return
		else
			proximityPrompts[mobId] = nil
		end
	end

	local prompt: ProximityPrompt? = createProximityPrompt(mob)
	if prompt then
		proximityPrompts[mobId] = prompt
	end
end

function MobsController:GetMob(mobId: string): MobClient?
	return activeMobs[mobId]
end

function MobsController:SpawnMob(mobData: MobData): ()
	if activeMobs[mobData.Id] then
		warn(`[MobsController] {mobData.Id} already exists`)
		return
	end

	local mobClient: MobClient = MobClientClass.new(mobData)
	mobClient:Spawn()

	activeMobs[mobData.Id] = mobClient

	if mobData.State == "Wandering" then
		task.wait(0.1)
		ensureProximityPrompt(mobData.Id)
	end
end

function MobsController:UpdateMob(mobId: string, updateData: any): ()
	local mob: MobClient? = activeMobs[mobId]
	if not mob then
		return
	end

	if updateData.position then
		mob:UpdatePosition(updateData.position)
	end

	if updateData.state then
		if updateData.carriedBy then
			mob.Data.CarriedBy = updateData.carriedBy
		end

		task.wait(0.1)
		mob:UpdateState(updateData.state)

		if updateData.state == "Wandering" or
			updateData.state == "Returning"
		then
			task.wait(0.2)
			ensureProximityPrompt(mobId)
		else
			removeProximityPrompt(mobId)
		end
	end

	if updateData.health then
		mob.Data.Health = updateData.health
	end
end

function MobsController:DamageMob(mobId: string, damage: number): ()
	local mob: MobClient? = activeMobs[mobId]
	if not mob then
		return
	end

	mob:TakeDamage(damage)
end

function MobsController:DespawnMob(mobId: string): ()
	local mob: MobClient? = activeMobs[mobId]
	if not mob then
		return
	end

	removeProximityPrompt(mobId)

	mob:Despawn()
	activeMobs[mobId] = nil

	if carryingMob == mobId then
		carryingMob = nil
	end
end

function MobsController:StopCarrying(delivered: boolean): ()
	if not carryingMob then
		return
	end

	local MobsService = ServiceRegistry.MobsService()
	MobsService.StopCarryingMob(carryingMob, delivered)

	print(`[MobsController] Stopped carrying (delivered: {delivered})`)
	carryingMob = nil
end

function MobsController:Init(): () end

function MobsController:Start(): ()
	NetworkAPI.Fired("MobsService:MobSpawned"):Connect(function(data: any)
		if data.action == "spawn" then
			MobsController:SpawnMob(data.mobData)
		end
	end)

	NetworkAPI.Fired("MobsService:MobUpdated"):Connect(function(updateData: any)
		if updateData.action == "update" then
			MobsController:UpdateMob(updateData.mobId, updateData)
		elseif updateData.action == "damage" then
			MobsController:DamageMob(updateData.mobId, updateData.damage)
		end
	end)

	NetworkAPI.Fired("MobsService:MobDespawned"):Connect(function(data: any)
		if data.action == "despawn" then
			MobsController:DespawnMob(data.mobId)
		end
	end)

	task.spawn(function()
		task.wait(2)

		local MobsService = ServiceRegistry.MobsServiceAsync()
		local mobsData: { MobData | any } = MobsService.GetAllMobsData()

		print(`[MobsController] Loading {#mobsData} mobs`)

		for _, mobData: MobData in ipairs(mobsData) do
			MobsController:SpawnMob(mobData)
		end
	end)

	UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
		if gameProcessed then
			return
		end

		if input.KeyCode == Enum.KeyCode.X and carryingMob then
			MobsController:StopCarrying(false)
		end
	end)
end

return MobsController