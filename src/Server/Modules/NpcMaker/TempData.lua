--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// MODULES
local SharedModules = ReplicatedStorage.Modules
local Utility = require(SharedModules.Utility)

--// VARIABLES
local template

local allData = {}
local TempData = {}

--// MODULE FUNCTIONS
function TempData.SetTemplate(templateToSet: { [string]: any })
	template = Utility.DeepTableClone(templateToSet)
end

function TempData.Create(npc: Model)
	local newData = Utility.DeepTableClone(template)
	allData[npc.Name] = newData
	return newData
end

function TempData.Get(npc: Model)
	return allData[npc.Name]
end

function TempData.Delete(npc: Model)
	allData[npc.Name] = nil
end

return TempData
