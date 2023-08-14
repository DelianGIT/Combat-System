--// SERVICES
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")

--// MODULES
local ServerModules = ServerStorage.Modules
local DataLibrary = require(ServerModules.DataLibrary)
local TempData = require(ServerModules.TempData)
local SkillLibrary = require(ServerModules.SkillLibrary)

--// CONFIG
local STUDIO_MODE = false
STUDIO_MODE = STUDIO_MODE and RunService:IsStudio()

--// DATA STORES CONFIGURATION
local dataStore = DataLibrary.CreateDataStore("Main", {
	SkillPacks = {"Test"}
})

TempData.SetProfileTemplate({
	SkillPacks = {},
	Cooldowns = {},
	CanUseSkills = true
})

--// CONTROL EVENTS
Players.PlayerAdded:Connect(function(player:Player)
	local savedData = dataStore:LoadData(player, STUDIO_MODE)
	if not savedData then
		player:Kick("Error while loading data")
		return
	end

	if player.Parent ~= Players then
		return
	end

	local tempData = TempData.CreateProfile(player)
	tempData.SavedData = savedData

	for _, packName in ipairs(savedData.Data.SkillPacks) do
		SkillLibrary.GiveSkillPack(player, packName)
	end
end)

Players.PlayerRemoving:Connect(function(player:Player)
	dataStore:SaveData(player, STUDIO_MODE)
	dataStore:RemoveData(player, STUDIO_MODE)
	TempData.RemoveData(player)
end)

return true