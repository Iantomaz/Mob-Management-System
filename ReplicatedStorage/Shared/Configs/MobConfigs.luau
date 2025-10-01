--!strict

local MobTypes = require(script.Parent.Parent.Types.MobTypes)
type MobConfig = MobTypes.MobConfig

local MobConfigs: { [string]: MobConfig } = {}

MobConfigs["Generic"] = {
	TypeId = "Generic",
	BaseHealth = 100,
	BaseSpeed = 8,
	BaseSize = 1.0,
	WanderRadius = 20,
	DefaultLifetime = 300,
	Model = "Rig",
	CanBeMutated = true,
	MutationChance = 0.15,
	PossibleMutations = { "Size", "Color", "Speed", "Glow" },
	CarrySlowdown = 0.6,
	DropOnDamage = true,
}

local MobConfigsModule = {}

function MobConfigsModule.Get(typeId: string): MobConfig?
	return MobConfigs[typeId]
end

function MobConfigsModule.GetAllTypes(): { string }
	local types: { string } = {}
	for typeId in pairs(MobConfigs) do
		table.insert(types, typeId)
	end
	return types
end

function MobConfigsModule.Exists(typeId: string): boolean
	return MobConfigs[typeId] ~= nil
end

return MobConfigsModule