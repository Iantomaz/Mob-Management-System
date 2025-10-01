--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = require(ReplicatedStorage.Library.Network)

export type Service = {
	Name: string,
	Client: ServiceClient?,
	[any]: any,
}

export type ServiceClient = {
	[string]: (...any) -> (...any),
}

type ServiceInternal = Service & {
	_initialized: boolean,
	Init: (self: Service) -> ()?,
	Start: (self: Service) -> ()?,
}

local ServerInitializer = {}
local services: { [string]: ServiceInternal } = {}
local started: boolean = false
local initialized: boolean = false

local function validateService(service: any): ServiceInternal
	assert(type(service) == "table", "Service need to be a table")
	assert(type(service.Name) == "string", "Service need to have a name (string)")
	assert(services[service.Name] == nil, `Service '{service.Name}' already registered`)

	return service :: ServiceInternal
end

local function setupClientCommunication(service: ServiceInternal): ()
	if not service.Client then
		return
	end
	
	for methodName: string, method in pairs(service.Client) do
		if type(method) == "function" then
			local eventName: string = `{service.Name}:{methodName}`

			Network.Fired(eventName):Connect(function(player: Player, ...: any)
				local success: boolean, result: any = pcall(method, service.Client, player, ...)

				if not success then
					warn(`[ServerInitializer] Error on service '{service.Name}.{methodName}': {result}`)
				end
			end)

			local invokeEventName: string = `{service.Name}:{methodName}:Invoke`
			Network.Invoked(invokeEventName).OnInvoke = function(player: Player, ...: any): any
				local success: boolean, result: any = pcall(method, service.Client, player, ...)

				if not success then
					warn(`[ServerInitializer] Error on service '{service.Name}.{methodName}': {result}`)
					return nil
				end

				return result
			end
		end
	end
end

function ServerInitializer.AddService(service: Service): ()
	assert(not started, "It's not possible to add a service before Start()")

	local validatedService: ServiceInternal = validateService(service)
	validatedService._initialized = false

	services[validatedService.Name] = validatedService
end

function ServerInitializer.GetService(serviceName: string): Service
	local service: ServiceInternal? = services[serviceName]
	assert(service ~= nil, `Service '{serviceName}' not found`)
	assert(initialized, `Service '{serviceName}' not initialized yet. Use after Init()`)

	return service :: Service
end

function ServerInitializer.Init(): ()
	assert(not initialized, "ServerInitializer already started")

	for _, service: ServiceInternal in pairs(services) do
		if service.Init and type(service.Init) == "function" then
			local success: boolean, err: string? = pcall(service.Init, service)

			if not success then
				error(`[ServerInitializer] Erro while initializing service '{service.Name}': {err}`)
			end
		end

		service._initialized = true
	end

	initialized = true
end

function ServerInitializer.Start(): ()
	assert(not started, "ServerInitializer already started")
	assert(initialized, "Execute Init() before Start()")

	for _, service: ServiceInternal in pairs(services) do
		setupClientCommunication(service)
	end

	for _, service: ServiceInternal in pairs(services) do
		if service.Start and type(service.Start) == "function" then
			task.spawn(function()
				local success: boolean, err: string? = pcall(service.Start, service)

				if not success then
					warn(`[ServerInitializer] Failed to start service '{service.Name}': {err}`)
				end
			end)
		end
	end

	started = true
end

function ServerInitializer.Run(): ()
	ServerInitializer.Init()
	ServerInitializer.Start()
end

return ServerInitializer