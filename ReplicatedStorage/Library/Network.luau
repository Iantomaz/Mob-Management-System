--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Reference
local remotes = ReplicatedStorage:WaitForChild("Network", 99999999)
local Players = game:GetService("Players")
local Asserts = require(ReplicatedStorage.Library.Asserts)
--local NetMap = require(ReplicatedStorage.Library.Globals.Constants).NETWORK_MAP

--  Variables
local events: { [number]: { [string]: Instance } } = { {}, {}, {} }
local packetInstances: { string } = {
	"RemoteEvent", -- Fired
	"RemoteFunction", -- Invoked
	"UnreliableRemoteEvent", -- UnreliableFired
}

local function _getName(_, remoteName: string): string
	return remoteName
end

--  Get (or create) Remotes by PacketType and name
local function _remote(packetType: number, remoteName: string): Instance
	local packetEvents = events[packetType]
	local remote = packetEvents[remoteName]

	if not remote then
		remote = Instance.new(packetInstances[packetType])
		assert(remote, `luau`)
		remote.Name = remoteName
		remote.Parent = remotes
		packetEvents[remoteName] = remote
	end

	return remote
end

--  Get (or create) RemoteEvent / RemoteFunction
local function _remoteEvent(remoteName: string): RemoteEvent
	return _remote(1, _getName(1, remoteName)) :: RemoteEvent
end

local function _remoteFunction(remoteName: string): RemoteFunction
	return _remote(2, _getName(2, remoteName)) :: RemoteFunction
end

local function _unreliableRemoteEvent(remoteName: string): RemoteEvent
	return _remote(3, _getName(3, remoteName)) :: RemoteEvent
end

local Network = { NET_MAP = NetMap }

--  Fire
function Network.Fire(remoteName: string, player: Player, ...: any): ()
	Asserts.Player(player)

	local remote: RemoteEvent = _remoteEvent(remoteName)
	task.spawn(function(...)
		remote:FireClient(player, ...)
	end, ...)
end

function Network.FireSync(remoteName: string, player: Player, ...: any): ()
	Asserts.Player(player)

	local remote: RemoteEvent = _remoteEvent(remoteName)
	remote:FireClient(player, ...)
end

--  Fire (everyone)
function Network.FireAll(remoteName: string, ...: any): ()
	local players = Players:GetPlayers()
	local playersToSend = {}

	for _, player in ipairs(players) do
		table.insert(playersToSend, player)
	end

	local remote: RemoteEvent = _remoteEvent(remoteName)
	if #playersToSend >= #players then
		-- Can use optimized FireAllClients
		task.spawn(function(...)
			remote:FireAllClients(...)
		end, ...)
	else
		-- Some players are in intro, so we gotta fire each manually
		for _, player in ipairs(playersToSend) do
			task.spawn(function(...)
				remote:FireClient(player, ...)
			end, ...)
		end
	end
end

--  On Fire
function Network.Fired(remoteName: string): RBXScriptSignal
	local remote: RemoteEvent = _remoteEvent(remoteName)
	return remote.OnServerEvent
end

--  Unreliable Fire
function Network.UnreliableFire(remoteName: string, player: Player, ...: any): ()
	Asserts.Player(player)

	local remote: RemoteEvent = _unreliableRemoteEvent(remoteName)
	task.spawn(function(...)
		remote:FireClient(player, ...)
	end, ...)
end

--  On Unreliable Fire
function Network.UnreliableFired(remoteName: string): RBXScriptSignal
	local remote: RemoteEvent = _unreliableRemoteEvent(remoteName)
	return remote.OnServerEvent
end

--  Unreliable Fire (everyone)
function Network.UnreliableFireAll(remoteName: string, blacklist: { Player }?, ...: any): ()
	local players = Players:GetPlayers()
	local playersToSend = {}

	for _, player in ipairs(players) do
		if blacklist and table.find(blacklist, player) then
			continue
		end
		table.insert(playersToSend, player)
	end

	local remote: RemoteEvent = _unreliableRemoteEvent(remoteName)

	if #playersToSend >= #players then
		-- Can use optimized FireAllClients
		task.spawn(function(...)
			remote:FireAllClients(...)
		end, ...)
	else
		-- Some players are in intro, so we gotta fire each manually
		for _, player in ipairs(playersToSend) do
			task.spawn(function(...)
				remote:FireClient(player, ...)
			end, ...)
		end
	end
end

--  Invoke
function Network.Invoke(remoteName: string, player: Player, ...: any): any
	Asserts.Player(player)

	-- Get/create remote
	local remote: RemoteFunction = _remoteFunction(remoteName)
	return remote:InvokeClient(player, ...)
end

--  On Invoke
type InvokeMethodsProxy = {
	OnInvoke: (...any) -> any,
}

function Network.Invoked(remoteName: string): InvokeMethodsProxy
	local remote: RemoteFunction = _remoteFunction(remoteName)

	local metatable = {}
	metatable.__newindex = function(_, index: string, value: any)
		if index == "OnInvoke" then
			remote.OnServerInvoke = value
		elseif index == "OnServerInvoke" then
			error(tostring(index) .. " is not a valid member of NetworkFunction")
		end
	end

	metatable.__index = function(_, index: string)
		if index == "OnInvoke" then
			return remote.OnServerInvoke
		elseif index == "OnServerInvoke" then
			error(tostring(index) .. " is not a valid member of NetworkFunction")
		end
	end

	return (setmetatable({}, metatable) :: any) :: InvokeMethodsProxy
end

return Network