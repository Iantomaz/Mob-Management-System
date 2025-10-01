local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Assets = ReplicatedStorage:WaitForChild('Assets')

local module = {}

function module:Get(class: string | Instance, assetName: string, clone: boolean?): Instance?
	local folder

	if typeof(class) == 'Instance' then
		folder = class
	else
		if string.find(class, "%.") then
			local pathParts = string.split(class, ".")
			folder = Assets

			for _, part in ipairs(pathParts) do
				folder = folder:FindFirstChild(part)
				if not folder then
					warn(`Invalid path part: {part} in class: {class}`)
					return nil
				end
			end
		else
			folder = Assets:FindFirstChild(class)
		end
	end

	if not folder then
		warn(`Invalid class: {class}`)
		return nil
	end

	local asset = folder:FindFirstChild(assetName)
	if not asset then
		warn(`Invalid assetName: {assetName} in class: {class}`)
		return nil
	end

	if clone then
		return asset:Clone()
	end

	return asset
end

return module