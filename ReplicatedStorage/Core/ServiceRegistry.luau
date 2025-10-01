--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ClientInitializer = require(script.Parent.ClientInitializer)

export type MobData = {
	Id: string,
	TypeId: string,
	State: string,
	Health: number,
	MaxHealth: number,
	Position: Vector3,
	BasePosition: { X: number, Z: number },
	WanderRadius: number,
	Mutations: { any },
	CarriedBy: Player?,
	SpawnedAt: number,
	Lifetime: number,
	Size: number,
}

export type MobsServiceClient = {
	GetAllMobsData: () -> { MobData },
	RequestCarryMob: (mobId: string) -> boolean,
	StopCarryingMob: (mobId: string, delivered: boolean) -> boolean,
	DamageMob: (mobId: string, damage: number) -> boolean,
}

local ServiceRegistry = {}

local fireProxies: { [string]: any } = {}
local invokeProxies: { [string]: any } = {}

function ServiceRegistry.MobsService(): MobsServiceClient
	if not fireProxies["MobsService"] then
		fireProxies["MobsService"] = ClientInitializer._CreateServiceProxy("MobsService")
	end
	return fireProxies["MobsService"] :: MobsServiceClient
end

function ServiceRegistry.MobsServiceAsync(): MobsServiceClient
	if not invokeProxies["MobsService"] then
		invokeProxies["MobsService"] = ClientInitializer._CreateServiceProxyAsync("MobsService")
	end
	return invokeProxies["MobsService"] :: MobsServiceClient
end

--[[
Example how to add new services

function ServiceRegistry.MyService(): MyServiceClient
    if not fireProxies["MyService"] then
        fireProxies["MyService"] = ClientInitializer._CreateServiceProxy("MyService")
    end
    return fireProxies["MyService"] :: MyServiceClient
end

function ServiceRegistry.MyServiceAsync(): MyServiceClient
    if not invokeProxies["MyService"] then
        invokeProxies["MyService"] = ClientInitializer._CreateServiceProxyAsync("MyService")
    end
    return invokeProxies["MyService"] :: MyServiceClient
end
]]

return ServiceRegistry