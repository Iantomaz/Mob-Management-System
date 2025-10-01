--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MobTypes = require(ReplicatedStorage.Shared.Types.MobTypes)

type SpawnZone = MobTypes.SpawnZone

local SpawnZoneClass = {}
SpawnZoneClass.__index = SpawnZoneClass

export type SpawnZoneInstance = {
	Config: SpawnZone,
	ActiveMobs: { [string]: boolean }, -- mobId -> true

	-- Private
	_spawnLoop: boolean?,
	_random: Random,

	-- Public Methods
	GetRandomPosition: (self: SpawnZoneInstance) -> Vector3,
	GetRandomMobType: (self: SpawnZoneInstance) -> string,
	CanSpawn: (self: SpawnZoneInstance) -> boolean,
	RegisterMob: (self: SpawnZoneInstance, mobId: string) -> (),
	UnregisterMob: (self: SpawnZoneInstance, mobId: string) -> (),
	Start: (self: SpawnZoneInstance, spawnCallback: (typeId: string, position: Vector3) -> ()) -> (),
	Stop: (self: SpawnZoneInstance) -> (),
	Destroy: (self: SpawnZoneInstance) -> (),
}

type SpawnZoneInternal = SpawnZoneInstance

function SpawnZoneClass.new(config: SpawnZone): SpawnZoneInstance
	local self = setmetatable({} :: any, SpawnZoneClass) :: SpawnZoneInternal

	self.Config = config
	self.ActiveMobs = {}
	self._spawnLoop = nil

	if config.Seed then
		self._random = Random.new(config.Seed)
	else
		self._random = Random.new()
	end

	return self
end

function SpawnZoneClass.GetRandomPosition(self: SpawnZoneInternal): Vector3
	local center: Vector3 = self.Config.Center
	local size: Vector3 = self.Config.Size

	local halfSize: Vector3 = size / 2

	local x: number = center.X + (self._random:NextNumber() * 2 - 1) * halfSize.X
	local z: number = center.Z + (self._random:NextNumber() * 2 - 1) * halfSize.Z
	local y: number = center.Y

	return Vector3.new(x, y, z)
end

function SpawnZoneClass.GetRandomMobType(self: SpawnZoneInternal): string
	local mobTypes: { string } = self.Config.MobTypes

	if #mobTypes == 0 then
		error(`[SpawnZone] Mobs not configured for Zone '{self.Config.Name}'`)
	end

	local index: number = self._random:NextInteger(1, #mobTypes)
	return mobTypes[index]
end

function SpawnZoneClass.CanSpawn(self: SpawnZoneInternal): boolean
	local currentMobCount: number = 0
	for _ in pairs(self.ActiveMobs) do
		currentMobCount += 1
	end

	return currentMobCount < self.Config.MaxMobs
end

function SpawnZoneClass.RegisterMob(self: SpawnZoneInternal, mobId: string): ()
	self.ActiveMobs[mobId] = true
end

function SpawnZoneClass.UnregisterMob(self: SpawnZoneInternal, mobId: string): ()
	self.ActiveMobs[mobId] = nil
end

function SpawnZoneClass.Start(
	self: SpawnZoneInternal,
	spawnCallback: (typeId: string, position: Vector3) -> ()
): ()
	if self._spawnLoop then
		warn(`[SpawnZone] Zone '{self.Config.Name}' already active`)
		return
	end

	print(`[SpawnZone] Starting Zone '{self.Config.Name}'`)

	self._spawnLoop = true

	task.spawn(function()
		while self._spawnLoop do
			if self:CanSpawn() then
				local mobType: string = self:GetRandomMobType()
				local position: Vector3 = self:GetRandomPosition()

				spawnCallback(mobType, position)
			end

			task.wait(self.Config.SpawnInterval)
		end
	end)

end

function SpawnZoneClass.Stop(self: SpawnZoneInternal): ()
	if self._spawnLoop then
		self._spawnLoop = nil
		print(`[SpawnZone] Zone '{self.Config.Name}' stopped`)
	end
end

function SpawnZoneClass.Destroy(self: SpawnZoneInternal): ()
	self:Stop()
	table.clear(self.ActiveMobs)
	table.clear(self)
	setmetatable(self, nil)
end

return SpawnZoneClass