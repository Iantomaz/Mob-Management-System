--!strict
export type MobId = string

export type MobState = "Wandering" | "BeingCarried" | "Returning" | "Dead"

export type Vector2D = {
	X: number,
	Z: number,
}

export type MobMutation = {
	Type: string, -- "Size", "Color", "Speed", "Glow", etc
	Value: any,
}

export type MobData = {
	Id: MobId,
	TypeId: string,
	State: MobState,
	Health: number,
	MaxHealth: number,
	Position: Vector3,
	BasePosition: Vector2D,
	WanderRadius: number,
	Mutations: { MobMutation },
	CarriedBy: Player?,
	SpawnedAt: number,
	Lifetime: number,
	Size: number,
}

export type MobConfig = {
	TypeId: string,
	BaseHealth: number,
	BaseSpeed: number,
	BaseSize: number,
	WanderRadius: number,
	DefaultLifetime: number,
	Model: string,
	CanBeMutated: boolean,
	MutationChance: number,
	PossibleMutations: { string },
	CarrySlowdown: number,
	DropOnDamage: boolean,
}

export type SpawnZone = {
	Name: string,
	Center: Vector3,
	Size: Vector3,
	MaxMobs: number,
	SpawnInterval: number,
	MobTypes: { string },
	Seed: number?,
}

-- Network Events
export type MobSpawnEvent = {
	action: "spawn",
	mobData: MobData,
}

export type MobUpdateEvent = {
	action: "update",
	mobId: MobId,
	position: Vector3?,
	state: MobState?,
	health: number?,
	carriedBy: Player?,
}

export type MobDespawnEvent = {
	action: "despawn",
	mobId: MobId,
	reason: "timeout" | "killed" | "delivered",
}

export type MobDamageEvent = {
	action: "damage",
	mobId: MobId,
	damage: number,
	newHealth: number,
}

return {}