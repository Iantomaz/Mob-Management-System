local module = {}

function module:SetCollisionGroup(model: Model, collisionGroup: string): ()
	for index, basePart: BasePart in model:GetDescendants() do
		if not basePart:IsA("BasePart") then continue end
		basePart.CollisionGroup = collisionGroup
	end
end

function module:DisableAllPhysics(model: Model, collisionGroup: string?): ()
	collisionGroup = collisionGroup or 'PartNotCollide'

	for index, basePart: BasePart in model:GetDescendants() do
		if not basePart:IsA("BasePart") then continue end
		basePart.CanCollide = false
		basePart.CanQuery = false
		basePart.CanTouch = false
		basePart.Massless = true
		basePart.CollisionGroup = collisionGroup
	end
end

function module:DisableHumanoidStates(humanoid: Humanoid?): ()
	if not humanoid then return end

	local statesToDisable = {
		Enum.HumanoidStateType.FallingDown,
		Enum.HumanoidStateType.Ragdoll,
		Enum.HumanoidStateType.GettingUp,
		Enum.HumanoidStateType.Jumping,
		Enum.HumanoidStateType.Freefall,
		Enum.HumanoidStateType.Climbing,
		Enum.HumanoidStateType.Flying,
		Enum.HumanoidStateType.Seated,
		Enum.HumanoidStateType.PlatformStanding,
		Enum.HumanoidStateType.Swimming,
		Enum.HumanoidStateType.Physics
	}

	for index, state in statesToDisable do
		humanoid:SetStateEnabled(state, false)
	end
end

function module:EnableHumanoidStates(humanoid: Humanoid?): ()
	if not humanoid then return end

	local statesToDisable = {
		Enum.HumanoidStateType.FallingDown,
		Enum.HumanoidStateType.Ragdoll,
		Enum.HumanoidStateType.GettingUp,
		Enum.HumanoidStateType.Jumping,
		Enum.HumanoidStateType.Freefall,
		Enum.HumanoidStateType.Climbing,
		Enum.HumanoidStateType.Flying,
		Enum.HumanoidStateType.Seated,
		Enum.HumanoidStateType.PlatformStanding,
		Enum.HumanoidStateType.Swimming,
		Enum.HumanoidStateType.Physics
	}

	for index, state in statesToDisable do
		humanoid:SetStateEnabled(state, true)
	end
end

function module:CreateWeld(part0: BasePart, part1: BasePart, offset: CFrame?, name: string?): Weld
	local weld: Weld = Instance.new("Weld")
	weld.Name = name or "Weld"
	weld.Part0 = part0
	weld.Part1 = part1
	weld.C0 = offset or CFrame.new()
	weld.C1 = CFrame.new()
	weld.Parent = part1

	return weld
end

function module:RemoveWeld(part: BasePart, weldName: string): ()
	local weld: Weld? = part:FindFirstChild(weldName) :: Weld?
	if weld then
		weld:Destroy()
	end
end

return module