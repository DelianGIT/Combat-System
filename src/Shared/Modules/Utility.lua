--// VARIABLES
local Utility = {}

--// MODULE FUNCTIONS
function Utility.DeepTableClone(tableToClone: { [any]: any })
	local result = {}

	for key, value in tableToClone do
		if type(value) == "table" then
			result[key] = Utility.DeepTableClone(value)
		else
			result[key] = value
		end
	end

	return result
end

function Utility.IsTableEmpty(tableToCheck: {})
	for _, _ in tableToCheck do
		return false
	end
	return true
end

return Utility
