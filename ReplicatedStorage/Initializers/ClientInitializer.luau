local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ClientInitializer = require(ReplicatedStorage.Core.ClientInitializer)

local Controllers = ReplicatedStorage:WaitForChild("Controllers")
for _, controllerModule: Instance in ipairs(Controllers:GetChildren()) do
	if controllerModule:IsA("ModuleScript") then
		ClientInitializer.AddController(require(controllerModule))
	end
end

-- Initialize
ClientInitializer.Run()