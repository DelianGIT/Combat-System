--// VARIABLES
local Utilities = {}

--// MODULE FUNCTIONS
function Utilities.DeepTableClone(tableToClone: { [any]: any })
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

function Utilities.IsTableEmpty(tableToCheck: {})
	for _, _ in tableToCheck do
		return false
	end
	return true
end

return Utilities
