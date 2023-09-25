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
function TempData.SetProfileTemplate(template: { [string]: any })
	profileTemplate = Utilities.DeepTableClone(template)
end

function TempData.Create(npc: Model)
	local profile = Utilities.DeepTableClone(profileTemplate)
	profiles[npc.Name] = profile
	return profile
end

function TempData.Get(npc: Model)
	local profile = profiles[npc.Name]
	if not profile then
		warn(npc.Name .. "'s temp data not found")
	else
		return profile
	end
end

function TempData.Delete(npc: Model)
	if not profiles[npc.Name] then
		warn(npc.Name .. "'s temp data already doesnt exist")
	else
		profiles[npc.Name] = nil
	end
end

return TempData
