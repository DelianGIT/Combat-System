--// SERVICES
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")

--// MODULES
local ServerModules = ServerStorage.Modules
local DataLibrary = require(ServerModules.DataLibrary)
local TempData = require(ServerModules.TempData)
local SkillLibrary = require(ServerModules.SkillLibrary)

--// PACKAGES
local Packages = ReplicatedStorage.Packages
local Red = require(Packages.Red)

--// VARIABLES
local remoteEvent = Red.Server("DataControl")

--// CONFIG
local STUDIO_MODE = false
STUDIO_MODE = STUDIO_MODE and RunService:IsStudio()

--// DATA STORES CONFIGURATION
local dataStore = DataLibrary.CreateDataStore("Main", {
	SkillPacks = {"Test"}
})

TempData.SetProfileTemplate({
	SkillPacks = {}
})

--// FUNCTIONS

--// CONTROL EVENTS
Players.PlayerAdded:Connect(function(player:Player)
	local loadedData = dataStore:LoadData(player, STUDIO_MODE)
	if not loadedData then
		player:Kick("Error while loading data")
	end

	local tempData = TempData.CreateProfile(player)
	tempData.LoadedData = loadedData
end)

Players.PlayerRemoving:Connect(function(player:Player)
	dataStore:SaveData(player, STUDIO_MODE)
	dataStore:RemoveData(player, STUDIO_MODE)
	TempData.RemoveData(player)
end)

return true