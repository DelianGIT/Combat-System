--// SERVICES
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// MODULES
local ServerModules = ServerStorage.Modules
local DataStore = require(ServerModules.DataStore)
local TempData = require(ServerModules.TempData)
local CharacterMaker = require(ServerModules.CharacterMaker)
local SkillLibrary = require(ServerModules.SkillLibrary)

--// PACKAGES
local Packages = ReplicatedStorage.Packages
local Red = require(Packages.Red)

--// CONFIG
local STUDIO_MODE = false
STUDIO_MODE = STUDIO_MODE and RunService:IsStudio()

local AUTOSAVE_INTERVAL = 300

--// VARIABLES
local remoteEvent = Red.Server("LoadingControl")

local notLoadedPlayers = {}

--// DATA STORES CONFIGURATION
DataStore.ToggleStudioMode(STUDIO_MODE)

local mainDataStore = DataStore.new("Main", {
	SkillPacks = { "Main" }
})

TempData.SetTemplate({
	NotLoadedCharacter = true,
	SkillPacks = {},
	ActiveSkills = {},
	BlockMaxDurability = 50
})

--// FUNCTIONS
local function saveAllPlayersData()
	for _, player in Players:GetPlayers() do
		mainDataStore:Save(player)
		mainDataStore:Remove(player)
	end
end

--// BINDING TO CLOSING OF GAME SAVING DATA OF ALL PLAYERS
if not STUDIO_MODE then
	game:BindToClose(function()
		saveAllPlayersData()
	end)
end

--// ENABLING AUTOSAVING
if not STUDIO_MODE then
	task.spawn(function()
		while task.wait(AUTOSAVE_INTERVAL) do
			saveAllPlayersData()
		end
	end)
end

--// EVENTS
Players.PlayerAdded:Connect(function(player: Player)
	notLoadedPlayers[player] = true

	local savedData = mainDataStore:Load(player, STUDIO_MODE)
	if not savedData then
		player:Kick("Error while loading data")
		return
	end

	if player.Parent ~= Players then
		return
	end
	
	local tempData = TempData.Create(player)
	for _, packName in savedData.Data.SkillPacks do
		SkillLibrary.GiveSkillPack(packName, player, tempData, true)
	end

	notLoadedPlayers[player] = nil
end)

Players.PlayerRemoving:Connect(function(player: Player)
	notLoadedPlayers[player] = nil

	local tempData = TempData.Get(player)

	if tempData then
		if not tempData.NotLoaded then
			task.spawn(function()
				local skillPacks = tempData.SkillPacks
				local activeSkills = tempData.ActiveSkills

				for identifier, properties in activeSkills do
					local skillName = string.split(identifier, "_")[2]
					local pack = skillPacks[properties.PackName]
					pack:InterruptSkill(skillName, true)
				end
			end)
		end

		TempData.Delete(player)
	end

	mainDataStore:Save(player)
	mainDataStore:Remove(player)

	print(player.Name .. "'s data removed")
end)

remoteEvent:On("ReadyForData", function(player: Player)
	if notLoadedPlayers[player] then
		repeat task.wait() until not notLoadedPlayers[player]
	end

	if player.Parent ~= Players then
		return
	end

	local tempData = TempData.Get(player)

	local givenPacks = {}
	for packName, _ in tempData.SkillPacks do
		table.insert(givenPacks, packName)
	end
	remoteEvent:Fire(player, "SkillPacks", givenPacks)

	print("Sent all data to " .. player.Name .. "'s client")
end)

remoteEvent:On("LoadCharacter", function(player: Player)
	local tempData = TempData.Get(player)
	if tempData.NotLoadedCharacter then
		CharacterMaker.Make(player, tempData)
		tempData.NotLoadedCharacter = nil
	end
end)

return true