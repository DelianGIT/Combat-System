--// SERVICES
local ServerStorage = game:GetService("ServerStorage")

--// MODULES
local ServerModules = ServerStorage.Modules
local Utilities = require(ServerModules.Utilities)

--// VARIABLES
local profileTemplate

local profiles = {}
local TempData = {}

--// MODULE FUNCTIONS
function TempData.SetProfileTemplate(template:{[string]:any})
	profileTemplate = Utilities.DeepTableClone(template)
end

function TempData.CreateProfile(player:Player)
	local profile = Utilities.DeepTableClone(profileTemplate)
	profiles[player.Name] = profile
	return profile
end

function TempData.GetData(player:Player)
	local profile = profiles[player.Name]
	if not profile then
		warn(player.Name.."'s temp data not found")
	else
		return profile
	end
end

function TempData.DeleteData(player:Player)
	if not profiles[player.Name] then
		warn(player.Name.."'s temp data already doesnt exist")
	else
		profiles[player.Name] = nil
	end
end

return TempData