--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local MobTypes = require(ReplicatedStorage.Shared.Types.MobTypes)
local MobConfigs = require(ReplicatedStorage.Shared.Configs.MobConfigs)

local Physics = require(ReplicatedStorage.Shared.Utils.Physics)
local Assets = require(ReplicatedStorage.Shared.Utils.Assets)

type MobData = MobTypes.MobData
type MobConfig = MobTypes.MobConfig
type MobState = MobTypes.MobState
type MobMutation = MobTypes.MobMutation

local MobClient = {}
MobClient.__index = MobClient

export type MobClient = {
	Data: MobData,
	Config: MobConfig,
	Model: Model?,

	_billboard: BillboardGui?,
	_animator: Animator?,
	_animations: { [string]: AnimationTrack }?,
	_wanderConnection: RBXScriptConnection?,
	_carryConnection: RBXScriptConnection?,
	_destroyed: boolean,

	Spawn: (self: MobClient) -> (),
	UpdateData: (self: MobClient, newData: MobData) -> (),
	UpdatePosition: (self: MobClient, position: Vector3) -> (),
	UpdateState: (self: MobClient, newState: MobState) -> (),
	TakeDamage: (self: MobClient, damage: number) -> (),
	Despawn: (self: MobClient) -> (),
	Destroy: (self: MobClient) -> (),
}

type MobClientInternal = MobClient & {
	_createModel: (self: MobClientInternal) -> Model?,
	_setupBillboard: (self: MobClientInternal) -> (),
	_setupAnimations: (self: MobClientInternal) -> (),
	_applyMutations: (self: MobClientInternal) -> (),
	_startWandering: (self: MobClientInternal) -> (),
	_stopWandering: (self: MobClientInternal) -> (),
	_startCarrying: (self: MobClientInternal) -> (),
	_stopCarrying: (self: MobClientInternal) -> (),
	_updateBillboard: (self: MobClientInternal) -> (),
	_resetPhysicsForWandering: (self: MobClientInternal) -> (),
	_startReturning: (self: MobClientInternal) -> (),
	_stopReturning: (self: MobClientInternal) -> (),
}

function MobClient.new(mobData: MobData): MobClient
	local self = setmetatable({} :: any, MobClient) :: MobClientInternal

	local config: MobConfig? = MobConfigs.Get(mobData.TypeId)
	if not config then
		error(`[MobClient] Config not found for type: {mobData.TypeId}`)
	end

	self.Data = mobData
	self.Config = config
	self.Model = nil
	self._billboard = nil
	self._animator = nil
	self._animations = {}
	self._wanderConnection = nil
	self._carryConnection = nil
	self._destroyed = false

	return self
end

function MobClient._createModel(self: MobClientInternal): Model?
	local model: Model? = Assets:Get("Mobs", self.Config.Model, true) :: Model?
	if not model then
		warn(`[MobClient] Model not found: {self.Config.Model}`)
		return nil
	end

	model.Name = `Mob_{self.Data.Id}`

	if self.Data.Size ~= 1.0 then
		local scale: NumberValue = Instance.new("NumberValue")
		scale.Name = "ScaleValue"
		scale.Value = self.Data.Size
		scale.Parent = model

		local hrp: BasePart = model:FindFirstChild("HumanoidRootPart") :: BasePart
		if hrp then
			local scaleMultiplier: number = self.Data.Size
			for _, part: Instance in ipairs(model:GetDescendants()) do
				if part:IsA("BasePart") and part ~= hrp then
					part.Size = part.Size * scaleMultiplier
				end
			end
		end
	end

	Physics:SetCollisionGroup(model, "Mobs")

	local humanoid: Humanoid? = model:FindFirstChildOfClass('Humanoid')
	if humanoid then
		Physics:DisableHumanoidStates(humanoid)
		humanoid.WalkSpeed = self.Config.BaseSpeed
	end

	model:PivotTo(CFrame.new(self.Data.Position))
	model.Parent = workspace.Mobs

	return model
end

function MobClient._setupBillboard(self: MobClientInternal): ()
	if not self.Model or not self.Model.PrimaryPart then
		return
	end
end

function MobClient._setupAnimations(self: MobClientInternal): ()
	if not self.Model then
		return
	end

	local humanoid: Humanoid? = self.Model:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	local animator: any = humanoid:FindFirstChildOfClass("Animator") :: any
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end

	self._animator = animator
	self._animations = {}
end

function MobClient._applyMutations(self: MobClientInternal): ()
	if not self.Model then
		return
	end

	for _, mutation: MobMutation in ipairs(self.Data.Mutations) do
		if mutation.Type == "Color" then
			for _, part: Instance in ipairs(self.Model:GetDescendants()) do
				if part:IsA("BasePart") then
					part.Color = mutation.Value :: Color3
				end
			end

		elseif mutation.Type == "Glow" then
			for _, part: Instance in ipairs(self.Model:GetDescendants()) do
				if part:IsA("BasePart") then
					part.Material = Enum.Material.Neon
				end
			end
		elseif mutation.Type == "Speed" then
			local humanoid: Humanoid? = self.Model:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.WalkSpeed = self.Config.BaseSpeed * (mutation.Value :: number)
			end
		end
	end
end

function MobClient._resetPhysicsForWandering(self: MobClientInternal): ()
	if not self.Model then
		return
	end

	for _, part: Instance in ipairs(self.Model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = true
		end
	end

	local humanoid: Humanoid? = self.Model:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.PlatformStand = false
		humanoid.WalkSpeed = self.Config.BaseSpeed

		for _, mutation: MobMutation in ipairs(self.Data.Mutations) do
			if mutation.Type == "Speed" then
				humanoid.WalkSpeed = self.Config.BaseSpeed * (mutation.Value :: number)
				break
			end
		end
	end
end

function MobClient._startWandering(self: MobClientInternal): ()
	if self._wanderConnection then
		return
	end

	if not self.Model or not self.Model.PrimaryPart then
		return
	end

	local humanoid: Humanoid? = self.Model:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	self:_resetPhysicsForWandering()

	self._wanderConnection = RunService.Heartbeat:Connect(function()
		if self._destroyed or not self.Model or not self.Model.PrimaryPart then
			return
		end

		if not humanoid or humanoid.Health <= 0 then
			return
		end

		local targetPos: Vector3 = self.Data.Position
		local currentPos: Vector3 = self.Model.PrimaryPart.Position

		local direction2D: Vector3 = Vector3.new(
			targetPos.X - currentPos.X,
			0,
			targetPos.Z - currentPos.Z
		)

		local distance: number = direction2D.Magnitude

		if distance > 1.5 then
			local moveDirection: Vector3 = direction2D.Unit
			humanoid:Move(moveDirection)
		else
			humanoid:Move(Vector3.zero)
		end
	end)
end

function MobClient._stopWandering(self: MobClientInternal): ()
	if self._wanderConnection then
		self._wanderConnection:Disconnect()
		self._wanderConnection = nil
	end

	if self.Model then
		local humanoid: Humanoid? = self.Model:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid:Move(Vector3.zero)
		end
	end
end

function MobClient._startReturning(self: MobClientInternal): ()
	if self._wanderConnection then
		return
	end

	if not self.Model or not self.Model.PrimaryPart then
		return
	end

	local humanoid: Humanoid? = self.Model:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	self:_resetPhysicsForWandering()

	self._wanderConnection = RunService.Heartbeat:Connect(function()
		if self._destroyed or not self.Model or not self.Model.PrimaryPart then
			return
		end

		if not humanoid or humanoid.Health <= 0 then
			return
		end

		local targetPos: Vector3 = self.Data.Position
		local currentPos: Vector3 = self.Model.PrimaryPart.Position

		local direction2D: Vector3 = Vector3.new(
			targetPos.X - currentPos.X,
			0,
			targetPos.Z - currentPos.Z
		)

		local distance: number = direction2D.Magnitude

		if distance > 1.5 then
			local moveDirection: Vector3 = direction2D.Unit
			humanoid:Move(moveDirection)
		else
			humanoid:Move(Vector3.zero)
		end
	end)
end

function MobClient._stopReturning(self: MobClientInternal): ()
	if self._wanderConnection then
		self._wanderConnection:Disconnect()
		self._wanderConnection = nil
	end

	if self.Model then
		local humanoid: Humanoid? = self.Model:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid:Move(Vector3.zero)
		end
	end
end

function MobClient._startCarrying(self: MobClientInternal): ()
	if not self.Data.CarriedBy then
		return
	end

	if self._carryConnection then
		return
	end

	if not self.Model or not self.Model.PrimaryPart then
		return
	end

	local player: Player? = self.Data.CarriedBy
	if not player then
		return
	end

	local character: Model = player.Character or player.CharacterAdded:Wait()
	if not character then
		return
	end

	local hrp: BasePart = character:WaitForChild("HumanoidRootPart", 5) :: BasePart
	if not hrp then
		return
	end

	local mobPrimaryPart: BasePart = self.Model.PrimaryPart

	for _, part: Instance in ipairs(self.Model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = false
		end
	end

	local humanoid: Humanoid? = self.Model:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.PlatformStand = true
		humanoid:Move(Vector3.zero)
	end

	local targetCFrame: CFrame = hrp.CFrame * CFrame.new(0, 1, -3)
	mobPrimaryPart.CFrame = targetCFrame

	task.wait(0.1)

	local existingWeld: Weld = mobPrimaryPart:FindFirstChild("CarryWeld") :: Weld
	if existingWeld then
		existingWeld:Destroy()
	end

	local weld: Weld = Instance.new("Weld")
	weld.Name = "CarryWeld"
	weld.Part0 = hrp
	weld.Part1 = mobPrimaryPart
	weld.C0 = CFrame.new(0, 1, -3)
	weld.C1 = CFrame.new(0, 0, 0)
	weld.Parent = mobPrimaryPart

	self._carryConnection = RunService.Heartbeat:Connect(function()
		if self._destroyed or not self.Model or not self.Model.PrimaryPart then
			return
		end

		if not player or not player.Parent or not player.Character then
			self:_stopCarrying()
		end
	end)
end

function MobClient._stopCarrying(self: MobClientInternal): ()
	if self._carryConnection then
		self._carryConnection:Disconnect()
		self._carryConnection = nil
	end

	if not self.Model or not self.Model.PrimaryPart then
		return
	end

	local weld: Weld = self.Model.PrimaryPart:FindFirstChild("CarryWeld") :: Weld
	if weld then
		weld:Destroy()
	end

	self:_resetPhysicsForWandering()
end

function MobClient._updateBillboard(self: MobClientInternal): ()
	if not self._billboard then
		return
	end
end

function MobClient.Spawn(self: MobClientInternal): ()
	if self.Model then
		return
	end

	self.Model = self:_createModel()

	if not self.Model then
		warn(`[MobClient] Failed to create model for {self.Data.Id}`)
		return
	end

	self:_setupBillboard()
	self:_setupAnimations()
	self:_applyMutations()

	if self.Data.State == "Wandering" then
		self:_startWandering()
	elseif self.Data.State == "BeingCarried" then
		self:_startCarrying()
	elseif self.Data.State == "Returning" then
		self:_startReturning()
	end
end

function MobClient.UpdateData(self: MobClientInternal, newData: MobData): ()
	self.Data = newData
	self:_updateBillboard()
end

function MobClient.UpdatePosition(self: MobClientInternal, position: Vector3): ()
	self.Data.Position = position
end

function MobClient.UpdateState(self: MobClientInternal, newState: MobState): ()
	local oldState: MobState = self.Data.State

	if oldState == newState then
		return
	end

	self.Data.State = newState

	if oldState == "Wandering" then
		self:_stopWandering()
	elseif oldState == "BeingCarried" then
		self:_stopCarrying()
	elseif oldState == "Returning" then
		self:_stopReturning()
	end

	if newState == "Wandering" then
		self:_startWandering()
	elseif newState == "BeingCarried" then
		task.wait()
		self:_startCarrying()
	elseif newState == "Returning" then
		self:_startReturning()
	end
end

function MobClient.TakeDamage(self: MobClientInternal, damage: number): ()
	self.Data.Health = math.max(0, self.Data.Health - damage)
	self:_updateBillboard()
end

function MobClient.Despawn(self: MobClientInternal): ()
	self:Destroy()
end

function MobClient.Destroy(self: MobClientInternal): ()
	if self._destroyed then
		return
	end

	self._destroyed = true

	self:_stopWandering()
	self:_stopReturning()
	self:_stopCarrying()

	if self.Model then
		self.Model:Destroy()
		self.Model = nil
	end

	if self._animations then
		for _, track: AnimationTrack in pairs(self._animations) do
			track:Stop()
		end
		table.clear(self._animations)
	end

	table.clear(self)
	setmetatable(self, nil)
end

return MobClient