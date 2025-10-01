return function(inputString: string): boolean
	-- Ensure the input is a string.
	local isString = type(inputString) == "string"
	assert(isString)

	-- Iterate over each character in the string.
	for i = 1, #inputString do
		local asciiCode = inputString:byte(i)
		if asciiCode < 32 or asciiCode > 126 then
			return false
		end
	end

	return true
end