--// VARIABLES
local Utilities = {}

function Utilities.DeepTableClone(tableToClone:{[any]:any})
	local result = {}
	
	for key, value in tableToClone do
		if type(value) == "table" then
			result[key] = Utilities.DeepTableClone(value)
		else
			result[key] = value
		end
	end

	return result
end

return Utilities