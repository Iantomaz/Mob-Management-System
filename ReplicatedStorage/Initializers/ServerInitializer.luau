local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerInitializer = require(ReplicatedStorage.Core.ServerInitializer)

local Services = ServerStorage:WaitForChild("Services")
for _, serviceModule: Instance in ipairs(Services:GetChildren()) do
	if serviceModule:IsA("ModuleScript") then
		ServerInitializer.AddService(require(serviceModule))
	end
end

ServerInitializer.Run()