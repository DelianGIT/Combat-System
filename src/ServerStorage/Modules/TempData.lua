--// VARIABLES
local profileTemplate

local profiles = {}
local TempData = {}

--// FUNCTIONS
local function deepTableClone(tableToClone:{any})
	local clonedTable = {}
	
	for key, value in pairs(tableToClone) do
		if type(value) == "table" then
			clonedTable[key] = deepTableClone(value)
		else
			clonedTable[key] = value
		end
	end

	return clonedTable
end

--// MODULE FUNCTIONS
function TempData.SetProfileTemplate(template:{[string]:any})
	if type(template) ~= "table" then
		error("Template must be a table")
	else
		profileTemplate = deepTableClone(template)
	end
end

function TempData.CreateProfile(player:Player)
	local profile = deepTableClone(profileTemplate)
	profiles[player.Name] = profile
	return profile
end

function TempData.GetData(player:Player)
	local profile = profiles[player.Name]
	if not profile then
		warn(player.Name.."'s data not found")
	else
		return profile
	end
end

function TempData.RemoveData(player:Player)
	if not profiles[player.Name] then
		warn(player.Name.."'s data already doesnt exist")
	else
		profiles[player.Name] = nil
	end
end

return TempData