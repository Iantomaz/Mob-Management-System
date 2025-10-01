--!strict

local runService = game:GetService("RunService")
if runService:IsClient() then
	assert(runService:IsClient())
end

local replicatedStorage = game:GetService("ReplicatedStorage")
local networkFolder = replicatedStorage:WaitForChild("Network", 99999999)
--local netMap = require(replicatedStorage.Library.Globals.Constants).NETWORK_MAP

local bindableContainers = { {}, {}, {}, {}, {}, {} }
local bindableClasses =
	{ "BindableEvent", "BindableFunction", "BindableEvent", "BindableEvent", "BindableFunction", "BindableEvent" }
local remoteContainers = { {}, {}, {} }
local remoteClasses = { "RemoteEvent", "RemoteFunction", "UnreliableRemoteEvent" }

local ignoredProfileEvents = {}
for _, eventName in ipairs({ "ProfileFunction: Reset", "ProfileFunction: Print" }) do
	ignoredProfileEvents[eventName] = true
end

local remoteCallbacks: { (string, Instance) -> () } = {
	-- For RemoteEvent / BindableEvent (Fire)
	function(key: string, obj: Instance): ()
		local remoteEvent = obj :: RemoteEvent
		local bindableObj = _bindable(1, key, false) :: BindableEvent?
		if bindableObj then
			remoteEvent.OnClientEvent:Connect(function(...)
				bindableObj:Fire(...)
			end)
		end
		local bindableSender = _bindable(4, key, false) :: BindableEvent?
		if bindableSender then
			bindableSender.Event:Connect(function(...)
				remoteEvent:FireServer(...)
			end)
		end
	end,
	-- For RemoteFunction / BindableFunction (Invoke)
	function(key: string, obj: Instance): ()
		local remoteFunc = obj :: RemoteFunction
		local bindableFunc = _bindable(2, key, false) :: BindableFunction?
		if bindableFunc then
			function remoteFunc.OnClientInvoke(...: any): any
				return bindableFunc:Invoke(...)
			end
		end
		local bindableSender = _bindable(5, key, false) :: BindableFunction?
		if bindableSender then
			function bindableSender.OnInvoke(...: any): any
				return remoteFunc:InvokeServer(...)
			end
		end
	end,
	-- For UnreliableRemoteEvent / BindableEvent (Fire)
	function(key: string, obj: Instance): ()
		local unreliableRemote = obj :: RemoteEvent
		local unreliableBindable = _bindable(3, key, false) :: BindableEvent?
		if unreliableBindable then
			unreliableRemote.OnClientEvent:Connect(function(...)
				unreliableBindable:Fire(...)
			end)
		end
		local unreliableSender = _bindable(6, key, false) :: BindableEvent?
		if unreliableSender then
			unreliableSender.Event:Connect(function(...)
				unreliableRemote:FireServer(...)
			end)
		end
	end,
}

local function getName(_: number, name: string): string
	return name
end

function _bindable(index: number, key: string, createIfMissing: boolean): Instance?
	local container = bindableContainers[index]
	local bindableObj = container[key]
	if not bindableObj and createIfMissing then
		bindableObj = Instance.new(bindableClasses[index])
		bindableObj.Name = key
		bindableObj.Parent = script
		container[key] = bindableObj
	end
	return bindableObj
end

function _bindableEventRx(key: string): BindableEvent
	return _bindable(1, getName(1, key), true) :: BindableEvent
end

function _bindableEventTx(key: string): BindableEvent
	return _bindable(4, getName(1, key), true) :: BindableEvent
end

function _bindableFunctionRx(key: string): BindableFunction
	return _bindable(2, getName(2, key), true) :: BindableFunction
end

function _bindableFunctionTx(key: string): BindableFunction
	return _bindable(5, getName(2, key), true) :: BindableFunction
end

function _bindableUnreliableEventRx(key: string): BindableEvent
	return _bindable(3, getName(1, key), true) :: BindableEvent
end

function _bindableUnreliableEventTx(key: string): BindableEvent
	return _bindable(6, getName(1, key), true) :: BindableEvent
end

function onChildAdded(child: Instance): ()
	-- Check if child belongs to a remote class category and initialize callback
	for remoteIndex, container in pairs(remoteContainers) do
		if child:IsA(remoteClasses[remoteIndex]) then
			local childKey = child.Name
			if container[childKey] == nil then
				container[childKey] = child
				remoteCallbacks[remoteIndex](childKey, child)
				return
			end
			break
		end
	end
end

function _remote(index: number, key: string): Instance?
	local container = remoteContainers[index]
	local remoteObj = container[key]
	if not remoteObj then
		remoteObj = networkFolder:FindFirstChild(key)
		if not remoteObj then
			return nil
		end
		container[key] = remoteObj
		remoteCallbacks[index](key, remoteObj)
	end
	return remoteObj
end

function _remoteEvent(key: string): RemoteEvent?
	return _remote(1, getName(1, key)) :: RemoteEvent?
end

function _remoteFunction(key: string): RemoteFunction?
	return _remote(2, getName(2, key)) :: RemoteFunction?
end

function _unreliableRemoteEvent(key: string): UnreliableRemoteEvent?
	return _remote(3, getName(3, key)) :: UnreliableRemoteEvent?
end

-- NET_MAP = netMap
local networkAPI = {}

function networkAPI.Fire(key: string, ...: any): ()
	local remoteEvent = _remoteEvent(key)
	if remoteEvent then
		task.spawn(function(...: any)
			remoteEvent:FireServer(...)
		end, ...)
	else
		local bindableEventTx = _bindableEventTx(key)
		task.spawn(function(...: any)
			bindableEventTx:Fire(...)
		end, ...)
	end
end

function networkAPI.Fired(key: string): RBXScriptSignal
	local remoteEvent = _remoteEvent(key)
	if remoteEvent then
		return remoteEvent.OnClientEvent
	else
		return _bindableEventRx(key).Event
	end
end

function networkAPI.UnreliableFire(key: string, ...: any): ()
	local unreliableRemote = _unreliableRemoteEvent(key)
	if unreliableRemote then
		task.spawn(function(...: any)
			unreliableRemote:FireServer(...)
		end, ...)
	else
		local unreliableBindableTx = _bindableUnreliableEventTx(key)
		task.spawn(function(...: any)
			unreliableBindableTx:Fire(...)
		end, ...)
	end
end

function networkAPI.UnreliableFired(key: string): RBXScriptSignal
	local unreliableRemote = _unreliableRemoteEvent(key)
	if unreliableRemote then
		return unreliableRemote.OnClientEvent
	else
		return _bindableUnreliableEventRx(key).Event
	end
end

function networkAPI.Invoke(key: string, ...: any): ...any
	local remoteFunc = _remoteFunction(key)
	if remoteFunc then
		return remoteFunc:InvokeServer(...)
	else
		return _bindableFunctionTx(key):Invoke(...)
	end
end

type InvokeMethodsProxy = {
	OnInvoke: (...any) -> any,
}
type NetworkRemoteCall = InvokeMethodsProxy

function networkAPI.Invoked(key: string): NetworkRemoteCall
	local bindableUsed = _bindable(2, getName(2, key), false)
	if not bindableUsed then
		local remoteFunc = _remoteFunction(key)
		if not remoteFunc then
			return (_bindableFunctionRx(key) :: any) :: NetworkRemoteCall
		end
		local proxy = {
			__newindex = function(_, member: string, value: any)
				if member == "OnInvoke" then
					remoteFunc.OnClientInvoke = value
				else
					error(("'" .. tostring(member) .. "' is not a valid member of NetworkFunction"))
				end
			end,
			__index = function(_, member: string): any
				if member == "OnInvoke" then
					return remoteFunc.OnClientInvoke
				end
				error(("'" .. tostring(member) .. "' is not a valid member of NetworkFunction"))
			end,
		}
		return (setmetatable({}, proxy) :: any) :: InvokeMethodsProxy
	else
		return (_bindableFunctionRx(key) :: any) :: NetworkRemoteCall
	end
end

networkFolder.ChildAdded:Connect(onChildAdded)
for _, child in ipairs(networkFolder:GetChildren()) do
	onChildAdded(child)
end

return networkAPI