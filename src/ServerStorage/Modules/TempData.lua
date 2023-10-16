--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// MODULES
local SharedModules = ReplicatedStorage.Modules
local Utilities = require(SharedModules.Utilities)

--// VARIABLES
local template

local allData = {}
local TempData = {}

--// MODULE FUNCTIONS
function TempData.SetTemplate(templateToSet: { [string]: any })
	template = Utilities.DeepTableClone(templateToSet)
end

function TempData.Create(player: Player)
	local newData = Utilities.DeepTableClone(template)
	allData[player.Name] = newData
	return newData
end

function TempData.Get(player: Player)
	return allData[player.Name]
end

function TempData.Delete(player: Player)
	allData[player.Name] = nil
end

return TempData