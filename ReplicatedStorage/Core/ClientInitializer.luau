--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local NetworkAPI = require(ReplicatedStorage.Library.NetworkAPI)

-- Types
export type Controller = {
	Name: string,
	[any]: any,
}

type ControllerInternal = Controller & {
	_initialized: boolean,
	Init: (self: Controller) -> ()?,
	Start: (self: Controller) -> ()?,
}

-- Variables
local ClientInitializer = {}
local controllers: { [string]: ControllerInternal } = {}
local started: boolean = false
local initialized: boolean = false

-- Private Functions
local function validateController(controller: any): ControllerInternal
	assert(type(controller) == "table", "Controller need to be a table")
	assert(type(controller.Name) == "string", "Controller need to have a name (string)")
	assert(controllers[controller.Name] == nil, `Controller '{controller.Name}' already registered`)

	return controller :: ControllerInternal
end

-- Internal function to create proxy
local function createFireProxy(serviceName: string): any
	return setmetatable({}, {
		__index = function(_, methodName: string)
			return function(...: any)
				local eventName: string = `{serviceName}:{methodName}`
				NetworkAPI.Fire(eventName, ...)
			end
		end
	})
end

local function createInvokeProxy(serviceName: string): any
	return setmetatable({}, {
		__index = function(_, methodName: string)
			return function(...: any): any
				local invokeEventName: string = `{serviceName}:{methodName}:Invoke`
				return NetworkAPI.Invoke(invokeEventName, ...)
			end
		end
	})
end

-- Public Functions
function ClientInitializer.AddController(controller: Controller): ()
	assert(not started, "It's not possible to add a controller before Start()")

	local validatedController: ControllerInternal = validateController(controller)
	validatedController._initialized = false

	controllers[validatedController.Name] = validatedController
end

function ClientInitializer.GetController(controllerName: string): Controller
	local controller: ControllerInternal? = controllers[controllerName]
	assert(controller ~= nil, `Controller '{controllerName}' not found`)
	assert(initialized, `Controller '{controllerName}' not started. Use before Init()`)

	return controller :: Controller
end

function ClientInitializer._CreateServiceProxy(serviceName: string): any
	return createFireProxy(serviceName)
end

function ClientInitializer._CreateServiceProxyAsync(serviceName: string): any
	return createInvokeProxy(serviceName)
end

function ClientInitializer.Init(): ()
	assert(not initialized, "ClientInitializer already initialized")

	for _, controller: ControllerInternal in pairs(controllers) do
		if controller.Init and type(controller.Init) == "function" then
			local success: boolean, err: string? = pcall(controller.Init, controller)

			if not success then
				error(`[ClientInitializer] Failed to initialize controller '{controller.Name}': {err}`)
			end
		end

		controller._initialized = true
	end

	initialized = true
end

function ClientInitializer.Start(): ()
	assert(not started, "ClientInitializer already started")
	assert(initialized, "Execute Init() after Start()")

	for _, controller: ControllerInternal in pairs(controllers) do
		if controller.Start and type(controller.Start) == "function" then
			task.spawn(function()
				local success: boolean, err: string? = pcall(controller.Start, controller)

				if not success then
					warn(`[ClientInitializer] Failed to initialize controller '{controller.Name}': {err}`)
				end
			end)
		end
	end

	started = true
end

function ClientInitializer.Run(): ()
	ClientInitializer.Init()
	ClientInitializer.Start()
end

return ClientInitializer