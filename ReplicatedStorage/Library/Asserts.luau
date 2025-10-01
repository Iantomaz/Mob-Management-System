local library = game:GetService("ReplicatedStorage"):WaitForChild("Library")
local isASCII = require(library:WaitForChild("Functions"):WaitForChild("IsASCII"))

local Asserts = {
	optional = {},
	array = {},
	custom = {},
}

function IsFinite(num)
	local isFinite = false
	if num == num then -- Check for NaN
		isFinite = false
		if num ~= math.huge then
			isFinite = num ~= -math.huge
		end
	end
	return isFinite
end

function IsFiniteVec2(vector)
	return IsFinite(vector.X) and IsFinite(vector.Y)
end

function IsFiniteVec(vector)
	return (IsFinite(vector.X) and IsFinite(vector.Y)) and IsFinite(vector.Z)
end

function IsFiniteCFrame(cf)
	local comp1, comp2, comp3, comp4, comp5, comp6, comp7, comp8, comp9, comp10, comp11, comp12 = cf:GetComponents()
	return (
		(
			(
				(
					(
						(
							(
								(((IsFinite(comp1) and IsFinite(comp2)) and IsFinite(comp3)) and IsFinite(comp4))
									and IsFinite(comp5)
							) and IsFinite(comp6)
						) and IsFinite(comp7)
					) and IsFinite(comp8)
				) and IsFinite(comp9)
			) and IsFinite(comp10)
		) and IsFinite(comp11)
	) and IsFinite(comp12)
end

function cassert(condition, level)
	if not condition then
		error("assertion failed!", (level or 0) + 3)
	end
end
Asserts.cassert = cassert

function Asserts.defined(value, level)
	cassert(value ~= nil, level)
	return value
end

function Asserts.exists(value, level)
	Asserts.defined(value, level)
	return value
end

function Asserts.cond(condition, level)
	cassert(condition == true, level)
end

function Asserts.boolean(value, level)
	cassert(type(value) == "boolean", level)
end

function Asserts.optional.boolean(value, level)
	local isValid = true
	if value ~= nil then
		isValid = type(value) == "boolean"
	end
	cassert(isValid, level)
end

function Asserts.enum(value, level)
	cassert(typeof(value) == "EnumItem", level)
end

function Asserts.optional.enum(value, level)
	if value == nil then
		return
	end
	cassert(typeof(value) == "EnumItem", level)
end

function Asserts.number(value, level)
	cassert(type(value) == "number", level)
end

function Asserts.optional.number(value, level)
	local isValid = true
	if value ~= nil then
		isValid = type(value) == "number"
	end
	cassert(isValid, level)
end

function Asserts.TweenInfo(value, level)
	cassert(typeof(value) == "TweenInfo", level)
end

function Asserts.optional.TweenInfo(value, level)
	local isValid = true
	if value ~= nil then
		isValid = typeof(value) == "TweenInfo"
	end
	cassert(isValid, level)
end

function Asserts.nonNegativeInteger(value, level)
	Asserts.integer(value, level)
	cassert(value >= 0, level)
	cassert(math.floor(value) == value, level)
end

function Asserts.optional.nonNegativeInteger(value, level)
	Asserts.optional.integer(value, level)
	if value ~= nil then
		cassert(value >= 0, level)
		cassert(math.floor(value) == value, level)
	end
end

function Asserts.positiveInteger(value, level)
	Asserts.integer(value, level)
	cassert(value > 0, level)
	cassert(math.floor(value) == value, level)
end

function Asserts.optional.positiveInteger(value, level)
	Asserts.optional.integer(value, level)
	if value ~= nil then
		cassert(value > 0, level)
		cassert(math.floor(value) == value, level)
	end
end

function Asserts.real(value, level)
	cassert(type(value) == "number", level)
	cassert(value == value, level)
end

function Asserts.optional.real(value, level)
	if value ~= nil then
		cassert(type(value) == "number", level)
		cassert(value == value, level)
	end
end

function Asserts.finite(value, level)
	cassert(type(value) == "number", level)
	cassert(IsFinite(value), level)
end

function Asserts.optional.finite(value, level)
	if value ~= nil then
		cassert(type(value) == "number", level)
		cassert(IsFinite(value), level)
	end
end

function Asserts.finiteNonNegative(value, level)
	cassert(type(value) == "number", level)
	cassert(IsFinite(value), level)
	cassert(value >= 0, level)
end

function Asserts.optional.finiteNonNegative(value, level)
	if value ~= nil then
		cassert(type(value) == "number", level)
		cassert(IsFinite(value), level)
		cassert(value >= 0, level)
	end
end

function Asserts.integer(value, level)
	cassert(type(value) == "number", level)
	cassert(IsFinite(value), level)
	cassert(math.floor(value) == value, level)
end

function Asserts.optional.integer(value, level)
	if value ~= nil then
		cassert(type(value) == "number", level)
		cassert(IsFinite(value), level)
		cassert(math.floor(value) == value, level)
	end
end

function Asserts.integerNonNegative(value, level)
	cassert(type(value) == "number", level)
	cassert(IsFinite(value), level)
	cassert(math.floor(value) == value, level)
	cassert(value >= 0, level)
end

function Asserts.optional.integerNonNegative(value, level)
	if value ~= nil then
		cassert(type(value) == "number", level)
		cassert(IsFinite(value), level)
		cassert(math.floor(value) == value, level)
		cassert(value >= 0, level)
	end
end

function Asserts.natural(value, level)
	cassert(type(value) == "number", level)
	cassert(IsFinite(value), level)
	cassert(math.floor(value) == value, level)
	cassert(value > 0, level)
end

function Asserts.optional.natural(value, level)
	if value ~= nil then
		cassert(type(value) == "number", level)
		cassert(IsFinite(value), level)
		cassert(math.floor(value) == value, level)
		cassert(value > 0, level)
	end
end

function Asserts.string(value, level)
	cassert(type(value) == "string", level)
end

function Asserts.optional.string(value, level)
	local isValid = true
	if value ~= nil then
		isValid = type(value) == "string"
	end
	cassert(isValid, level)
end

function Asserts.Color3(value, level)
	cassert(typeof(value) == "Color3", level)
end

function Asserts.optional.Color3(value, level)
	if value ~= nil then
		cassert(typeof(value) == "Color3", level)
	end
end

function Asserts.ascii(value, level)
	cassert(type(value) == "string", level)
	cassert(isASCII(value), level)
end

function Asserts.optional.ascii(value, level)
	if value ~= nil then
		cassert(type(value) == "string", level)
		cassert(isASCII(value), level)
	end
end

function Asserts.username(value, level)
	cassert(type(value) == "string", level)
	cassert(isASCII(value), level)
end

function Asserts.optional.username(value, level)
	if value ~= nil then
		cassert(type(value) == "string", level)
		local isValid = false
		if #value >= 3 then
			isValid = #value <= 20
		end
		cassert(isValid, level)
		cassert(value:find("^%w+$") ~= nil, level)
		isValid = false
		if value:sub(1, 1) ~= "_" then
			isValid = value:sub(-1) ~= "_"
		end
		cassert(isValid, level)
		cassert(value:find("__") == nil, level)
		cassert(value:find("^%d+$") == nil, level)
	end
end

function Asserts.uuid(value, level)
	cassert(type(value) == "string", level)
	cassert(#value == 36, level)
	cassert(value:find("^%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x$") ~= nil, level)
end

function Asserts.optional.uuid(value, level)
	if value ~= nil then
		cassert(type(value) == "string", level)
		cassert(#value == 36, level)
		cassert(value:find("^%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x$") ~= nil, level)
	end
end

function Asserts.uuidStripped(value, level)
	cassert(type(value) == "string", level)
	cassert(#value == 32, level)
	cassert(value:find("^%x+$") ~= nil, level)
end

function Asserts.optional.uuidStripped(value, level)
	if value ~= nil then
		cassert(type(value) == "string", level)
		cassert(#value == 32, level)
		cassert(value:find("^%x+$") ~= nil, level)
	end
end

function Asserts.FromGenerateUID(value, level)
	return Asserts.UUIDv4StrippedUpper(value, level)
end

function Asserts.optional.FromGenerateUID(value, level)
	return Asserts.optional.UUIDv4StrippedUpper(value, level)
end

function Asserts.UUIDv4StrippedLower(value, level)
	cassert(type(value) == "string", level)
	cassert(#value == 32, level)
	cassert(value:find("^[0-9a-f]+$") ~= nil, level)
	cassert(value:sub(13, 13) == "4", level)
	cassert(value:sub(17, 17):find("[8-9a-b]") ~= nil, level)
end

function Asserts.optional.UUIDv4StrippedLower(value, level)
	if value ~= nil then
		cassert(type(value) == "string", level)
		cassert(#value == 32, level)
		cassert(value:find("^[0-9a-f]+$") ~= nil, level)
		cassert(value:sub(13, 13) == "4", level)
		cassert(value:sub(17, 17):find("[8-9a-b]") ~= nil, level)
	end
end

function Asserts.UUIDv4StrippedLowerFast(value, level)
	cassert(type(value) == "string", level)
	cassert(#value == 32, level)
end

function Asserts.optional.UUIDv4StrippedLowerFast(value, level)
	if value ~= nil then
		cassert(type(value) == "string", level)
		cassert(#value == 32, level)
	end
end

function Asserts.UUIDv4StrippedUpper(value, level)
	cassert(type(value) == "string", level)
	cassert(#value == 32, level)
	cassert(value:find("^[0-9A-F]+$") ~= nil, level)
	cassert(value:sub(13, 13) == "4", level)
	cassert(value:sub(17, 17):find("[8-9A-B]") ~= nil, level)
end

function Asserts.optional.UUIDv4StrippedUpper(value, level)
	if value ~= nil then
		cassert(type(value) == "string", level)
		cassert(#value == 32, level)
		cassert(value:find("^[0-9A-F]+$") ~= nil, level)
		cassert(value:sub(13, 13) == "4", level)
		cassert(value:sub(17, 17):find("[8-9A-B]") ~= nil, level)
	end
end

function Asserts.func(value, level)
	cassert(type(value) == "function", level)
end

function Asserts.optional.func(value, level)
	local isValid = true
	if value ~= nil then
		isValid = type(value) == "function"
	end
	cassert(isValid, level)
end

function Asserts.table(value, level)
	cassert(type(value) == "table", level)
end

function Asserts.optional.table(value, level)
	local isValid = true
	if value ~= nil then
		isValid = type(value) == "table"
	end
	cassert(isValid, level)
end

function Asserts.array.generic(array, valueType, level)
	cassert(type(array) == "table", level)
	local arrayLength = #array
	if arrayLength > 0 then
		local index = 0
		for key, value in pairs(array) do
			index = index + 1
			cassert(key == index, level)
			cassert(type(value) == valueType, level)
		end
		cassert(index == arrayLength, level)
	else
		cassert(next(array) == nil, level)
	end
end
function Asserts.array.notEmpty(array, level)
	cassert(type(array) == "table", level)
	assert(#array > 0, "An empty array was provided")
end

function Asserts.array.custom(array, customAssert, level)
	cassert(type(array) == "table", level)
	local arrayLength = #array
	if arrayLength > 0 then
		local index = 0
		for key, value in pairs(array) do
			index = index + 1
			cassert(key == index, level)
			customAssert(value, (level or 0) + 1)
		end
		cassert(index == arrayLength, level)
	else
		cassert(next(array) == nil, level)
	end
end

function Asserts.array.uuid(array, level)
	Asserts.array.custom(array, Asserts.uuid, (level or 0) + 1)
end

function Asserts.array.uuidStripped(array, level)
	Asserts.array.custom(array, Asserts.uuidStripped, (level or 0) + 1)
end

function Asserts.array.UUIDv4StrippedLower(array, level)
	Asserts.array.custom(array, Asserts.UUIDv4StrippedLower, (level or 0) + 1)
end

function Asserts.array.uniqueUUID(array, level)
	Asserts.array.custom(array, Asserts.uuid, (level or 0) + 1)
	local seen = {}
	for _, value in ipairs(array) do
		cassert(not seen[value], level)
		seen[value] = true
	end
end

function Asserts.array.uniqueUUIDStripped(array, level)
	Asserts.array.custom(array, Asserts.uuidStripped, (level or 0) + 1)
	local seen = {}
	for _, value in ipairs(array) do
		cassert(not seen[value], level)
		seen[value] = true
	end
end

function Asserts.array.uniqueUUIDv4StrippedLower(array, level)
	Asserts.array.custom(array, Asserts.UUIDv4StrippedLower, (level or 0) + 1)
	local seen = {}
	for _, value in ipairs(array) do
		cassert(not seen[value], level)
		seen[value] = true
	end
end

function Asserts.array.uniqueUUIDv4StrippedLowerFast(array, level)
	Asserts.array.custom(array, Asserts.UUIDv4StrippedLowerFast, (level or 0) + 1)
	local seen = {}
	for _, value in ipairs(array) do
		cassert(not seen[value], level)
		seen[value] = true
	end
end

function Asserts.array.boolean(array, level)
	Asserts.array.generic(array, "boolean", (level or 0) + 1)
end

function Asserts.array.number(array, level)
	Asserts.array.generic(array, "number", (level or 0) + 1)
end

function Asserts.array.string(array, level)
	Asserts.array.generic(array, "string", (level or 0) + 1)
end

function Asserts.array.table(array, level)
	Asserts.array.generic(array, "table", (level or 0) + 1)
end

function Asserts.array.Vector2(array, level)
	Asserts.array.generic(array, "Vector2", (level or 0) + 1)
end

function Asserts.array.finiteVector2(array, level)
	Asserts.array.custom(array, Asserts.finiteVector2, (level or 0) + 1)
end

function Asserts.array.Vector3(array, level)
	Asserts.array.generic(array, "Vector3", (level or 0) + 1)
end

function Asserts.array.finiteVector3(array, level)
	Asserts.array.custom(array, Asserts.finiteVector3, (level or 0) + 1)
end

function Asserts.array.CFrame(array, level)
	Asserts.array.generic(array, "CFrame", (level or 0) + 1)
end

function Asserts.array.finiteCFrame(array, level)
	Asserts.array.custom(array, Asserts.finiteCFrame, (level or 0) + 1)
end

function Asserts.array.integer(array, level)
	Asserts.array.custom(array, Asserts.integer, (level or 0) + 1)
end

function Asserts.array.positiveInteger(array, level)
	Asserts.array.custom(array, Asserts.positiveInteger, (level or 0) + 1)
end

function Asserts.array.Player(array, level)
	Asserts.array.custom(array, Asserts.Player, (level or 0) + 1)
end

function Asserts.array.finite(array, level)
	Asserts.array.custom(array, Asserts.finite, (level or 0) + 1)
end

function Asserts.array.uniqueInteger(array, level)
	local seen = {}
	Asserts.array.custom(array, function(value, currentLevel)
		Asserts.integer(value, (currentLevel or 0) + 1)
		cassert(not seen[value], currentLevel)
		seen[value] = true
	end, (level or 0) + 1)
end

function Asserts.array.uniquePlayer(array, level)
	local seen = {}
	Asserts.array.custom(array, function(value, currentLevel)
		Asserts.Player(value, (currentLevel or 0) + 1)
		cassert(not seen[value], currentLevel)
		seen[value] = true
	end, (level or 0) + 1)
end

function Asserts.array.uniqueModel(array, level)
	local seen = {}
	Asserts.array.custom(array, function(value, currentLevel)
		Asserts.Model(value, (currentLevel or 0) + 1)
		cassert(not seen[value], currentLevel)
		seen[value] = true
	end, (level or 0) + 1)
end

function Asserts.Vector2(value, level)
	cassert(typeof(value) == "Vector2", level)
end

function Asserts.optional.Vector2(value, level)
	local isValid = true
	if value ~= nil then
		isValid = typeof(value) == "Vector2"
	end
	cassert(isValid, level)
end

function Asserts.finiteVector2(value, level)
	cassert(typeof(value) == "Vector2", level)
	cassert(IsFiniteVec2(value), level)
end

function Asserts.optional.finiteVector2(value, level)
	if value ~= nil then
		cassert(typeof(value) == "Vector2", level)
		cassert(IsFiniteVec2(value), level)
	end
end

function Asserts.Vector3(value, level)
	cassert(typeof(value) == "Vector3", level)
end

function Asserts.optional.Vector3(value, level)
	local isValid = true
	if value ~= nil then
		isValid = typeof(value) == "Vector3"
	end
	cassert(isValid, level)
end

function Asserts.finiteVector3(value, level)
	cassert(typeof(value) == "Vector3", level)
	cassert(IsFiniteVec(value), level)
end

function Asserts.optional.finiteVector3(value, level)
	if value ~= nil then
		cassert(typeof(value) == "Vector3", level)
		cassert(IsFiniteVec(value), level)
	end
end

function Asserts.CFrame(value, level)
	cassert(typeof(value) == "CFrame", level)
end

function Asserts.optional.CFrame(value, level)
	local isValid = true
	if value ~= nil then
		isValid = typeof(value) == "CFrame"
	end
	cassert(isValid, level)
end

function Asserts.finiteCFrame(value, level)
	cassert(typeof(value) == "CFrame", level)
	cassert(IsFiniteCFrame(value), level)
end

function Asserts.optional.finiteCFrame(value, level)
	if value ~= nil then
		cassert(typeof(value) == "CFrame", level)
		cassert(IsFiniteCFrame(value), level)
	end
end

function Asserts.Instance(value, level)
	cassert(typeof(value) == "Instance", level)
end

function Asserts.optional.Instance(value, level)
	local isValid = true
	if value ~= nil then
		isValid = typeof(value) == "Instance"
	end
	cassert(isValid, level)
end

function Asserts.Player(value, level)
	local isValid = false
	if typeof(value) == "Instance" then
		isValid = value.ClassName == "Player"
	end
	cassert(isValid, level)
end

function Asserts.optional.Player(value, level)
	local isValid = true
	if value ~= nil then
		isValid = false
		if typeof(value) == "Instance" then
			isValid = value.ClassName == "Player"
		end
	end
	cassert(isValid, level)
end

function Asserts.Model(value, level)
	local isValid = false
	if typeof(value) == "Instance" then
		isValid = value.ClassName == "Model"
	end
	cassert(isValid, level)
end

function Asserts.Sound(value, level)
	local isValid = false
	if typeof(value) == "Instance" then
		isValid = value.ClassName == "Sound"
	end
	cassert(isValid, level)
end

function Asserts.optional.Sound(value, level)
	local isValid = true
	if value ~= nil then
		isValid = false
		if typeof(value) == "Instance" then
			isValid = value.ClassName == "Sound"
		end
	end
	cassert(isValid, level)
end

function Asserts.optional.Model(value, level)
	local isValid = true
	if value ~= nil then
		isValid = false
		if typeof(value) == "Instance" then
			isValid = value.ClassName == "Model"
		end
	end
	cassert(isValid, level)
end

function Asserts.Attachment(value, level)
	local isValid = false
	if typeof(value) == "Instance" then
		isValid = value.ClassName == "Attachment"
	end
	cassert(isValid, level)
end

function Asserts.optional.Attachment(value, level)
	local isValid = true
	if value ~= nil then
		isValid = false
		if typeof(value) == "Instance" then
			isValid = value.ClassName == "Attachment"
		end
	end
	cassert(isValid, level)
end

function Asserts.BasePart(value, level)
	local isValid = false
	if typeof(value) == "Instance" then
		isValid = value:IsA("BasePart")
	end
	cassert(isValid, level)
end

function Asserts.optional.BasePart(value, level)
	local isValid = true
	if value ~= nil then
		isValid = false
		if typeof(value) == "Instance" then
			isValid = value:IsA("BasePart")
		end
	end
	cassert(isValid, level)
end

function Asserts.Tool(value, level)
	local isValid = false
	if typeof(value) == "Instance" then
		isValid = value:IsA("Tool")
	end
	cassert(isValid, level)
end

function Asserts.optional.Tool(value, level)
	local isValid = true
	if value ~= nil then
		isValid = false
		if typeof(value) == "Instance" then
			isValid = value:IsA("Tool")
		end
	end
	cassert(isValid, level)
end

function Asserts.Motor6D(value, level)
	local isValid = false
	if typeof(value) == "Instance" then
		isValid = value:IsA("Motor6D")
	end
	cassert(isValid, level)
end

function Asserts.optional.Motor6D(value, level)
	local isValid = true
	if value ~= nil then
		isValid = false
		if typeof(value) == "Instance" then
			isValid = value:IsA("Motor6D")
		end
	end
	cassert(isValid, level)
end

function Asserts.UIGradient(value, level)
	local isValid = false
	if typeof(value) == "Instance" then
		isValid = value:IsA("UIGradient")
	end
	cassert(isValid, level)
end

function Asserts.optional.UIGradient(value, level)
	local isValid = true
	if value ~= nil then
		isValid = false
		if typeof(value) == "Instance" then
			isValid = value:IsA("UIGradient")
		end
	end
	cassert(isValid, level)
end

function Asserts.ImageLabel(value, level)
	local isValid = false
	if typeof(value) == "Instance" then
		isValid = value:IsA("ImageLabel")
	end
	cassert(isValid, level)
end

function Asserts.optional.ImageLabel(value, level)
	local isValid = true
	if value ~= nil then
		isValid = false
		if typeof(value) == "Instance" then
			isValid = value:IsA("ImageLabel")
		end
	end
	cassert(isValid, level)
end

function Asserts.GuiObject(value, level)
	local isValid = false
	if typeof(value) == "Instance" then
		isValid = value:IsA("GuiObject")
	end
	cassert(isValid, level)
end

function Asserts.optional.GuiObject(value, level)
	local isValid = true
	if value ~= nil then
		isValid = false
		if typeof(value) == "Instance" then
			isValid = value:IsA("GuiObject")
		end
	end
	cassert(isValid, level)
end

function Asserts.Frame(value, level)
	local isValid = false
	if typeof(value) == "Instance" then
		isValid = value:IsA("Frame")
	end
	cassert(isValid, level)
end

function Asserts.optional.Frame(value, level)
	local isValid = true
	if value ~= nil then
		isValid = false
		if typeof(value) == "Instance" then
			isValid = value:IsA("Frame")
		end
	end
	cassert(isValid, level)
end

function Asserts.Folder(value, level)
	local isValid = false
	if typeof(value) == "Instance" then
		isValid = value:IsA("Folder")
	end
	cassert(isValid, level)
end

function Asserts.optional.Folder(value, level)
	local isValid = true
	if value ~= nil then
		isValid = false
		if typeof(value) == "Instance" then
			isValid = value:IsA("Folder")
		end
	end
	cassert(isValid, level)
end

function Asserts.MeshPart(value, level)
	local isValid = false
	if typeof(value) == "Instance" then
		isValid = value:IsA("MeshPart")
	end
	cassert(isValid, level)
end

function Asserts.optional.MeshPart(value, level)
	local isValid = true
	if value ~= nil then
		isValid = false
		if typeof(value) == "Instance" then
			isValid = value:IsA("MeshPart")
		end
	end
	cassert(isValid, level)
end

function Asserts.BillboardGui(value, level)
	local isValid = false
	if typeof(value) == "Instance" then
		isValid = value:IsA("BillboardGui")
	end
	cassert(isValid, level)
end

function Asserts.optional.BillboardGui(value, level)
	local isValid = true
	if value ~= nil then
		isValid = false
		if typeof(value) == "Instance" then
			isValid = value:IsA("BillboardGui")
		end
	end
	cassert(isValid, level)
end

function Asserts.TextLabel(value, level)
	local isValid = false
	if typeof(value) == "Instance" then
		isValid = value:IsA("TextLabel")
	end
	cassert(isValid, level)
end

function Asserts.optional.TextLabel(value, level)
	local isValid = true
	if value ~= nil then
		isValid = false
		if typeof(value) == "Instance" then
			isValid = value:IsA("TextLabel")
		end
	end
	cassert(isValid, level)
end

function Asserts.UIScale(value, level)
	local isValid = false
	if typeof(value) == "Instance" then
		isValid = value:IsA("UIScale")
	end
	cassert(isValid, level)
end

function Asserts.optional.UIScale(value, level)
	local isValid = true
	if value ~= nil then
		isValid = false
		if typeof(value) == "Instance" then
			isValid = value:IsA("UIScale")
		end
	end
	cassert(isValid, level)
end

function Asserts.ScrollingFrame(value, level)
	local isValid = false
	if typeof(value) == "Instance" then
		isValid = value:IsA("ScrollingFrame")
	end
	cassert(isValid, level)
end

function Asserts.optional.ScrollingFrame(value, level)
	local isValid = true
	if value ~= nil then
		isValid = false
		if typeof(value) == "Instance" then
			isValid = value:IsA("ScrollingFrame")
		end
	end
	cassert(isValid, level)
end

function Asserts.ModuleScript(value, level)
	local isValid = false
	if typeof(value) == "Instance" then
		isValid = value:IsA("ModuleScript")
	end
	cassert(isValid, level)
end

function Asserts.optional.ModuleScript(value, level)
	local isValid = true
	if value ~= nil then
		isValid = false
		if typeof(value) == "Instance" then
			isValid = value:IsA("ModuleScript")
		end
	end
	cassert(isValid, level)
end

function Asserts.GuiButton(value, level)
	local isValid = false
	if typeof(value) == "Instance" then
		isValid = value:IsA("GuiButton")
	end
	cassert(isValid, level)
end

function Asserts.optional.GuiButton(value, level)
	local isValid = true
	if value ~= nil then
		isValid = false
		if typeof(value) == "Instance" then
			isValid = value:IsA("GuiButton")
		end
	end
	cassert(isValid, level)
end

function Asserts.Humanoid(value, level)
	local isValid = false
	if typeof(value) == "Instance" then
		isValid = value:IsA("Humanoid")
	end
	cassert(isValid, level)
end

function Asserts.optional.Humanoid(value, level)
	local isValid = true
	if value ~= nil then
		isValid = false
		if typeof(value) == "Instance" then
			isValid = value:IsA("Humanoid")
		end
	end
	cassert(isValid, level)
end

function Asserts.Animator(value, level)
	local isValid = false
	if typeof(value) == "Instance" then
		isValid = value:IsA("Animator")
	end
	cassert(isValid, level)
end

function Asserts.optional.Animator(value, level)
	local isValid = true
	if value ~= nil then
		isValid = false
		if typeof(value) == "Instance" then
			isValid = value:IsA("Animator")
		end
	end
	cassert(isValid, level)
end

function Asserts.Animation(value, level)
	local isValid = false
	if typeof(value) == "Instance" then
		isValid = value:IsA("Animation")
	end
	cassert(isValid, level)
end

function Asserts.optional.Animation(value, level)
	local isValid = true
	if value ~= nil then
		isValid = false
		if typeof(value) == "Instance" then
			isValid = value:IsA("Animation")
		end
	end
	cassert(isValid, level)
end

return Asserts