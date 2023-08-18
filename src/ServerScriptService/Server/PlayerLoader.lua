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
local remoteEvent = Red.Server("LoadingControl")

local loadedPlayers = {}

--// CONFIG
local STUDIO_MODE = true
STUDIO_MODE = STUDIO_MODE and RunService:IsStudio()

local AUTOSAVE_INTERVAL = 300 -- In seconds

--// DATA STORES CONFIGURATION
DataLibrary.ToggleStudioMode(STUDIO_MODE)

local dataStore = DataLibrary.CreateDataStore("Main", {
	SkillPacks = { "Test" },
})

TempData.SetProfileTemplate({
	SkillPacks = {},
	Cooldowns = {},
	CanUseSkills = true,
	NotLoaded = true,
})

--// FUNCTIONS
local function loadCharacter(player: Player)
	player:LoadCharacter()
	print("Loaded " .. player.Name .. "'s character")
end

local function savePlayerData(player)
	dataStore:SaveData(player, STUDIO_MODE)
	dataStore:RemoveData(player, STUDIO_MODE)
end

local function saveAllPlayersData()
	for _, player in Players:GetPlayers() do
		savePlayerData(player)
	end
end

local function playerAdded(player: Player)
	print("Player " .. player.Name .. " added")

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

	for _, packName in savedData.Data.SkillPacks do
		SkillLibrary.GiveSkillPack(player, tempData, packName)
	end

	loadedPlayers[player] = true
	tempData.NotLoaded = nil
	print("Player " .. player.Name .. " loaded")
end

local function sendDataToClient(player: Player)
	print("Got client loaded signal from " .. player.Name)

	if not loadedPlayers[player] then
		repeat
		until loadedPlayers[player]
		loadedPlayers[player] = nil
	end

	local savedData = dataStore:GetData(player)
	local tempData = TempData.GetData(player)

	local keybindsInfo = {}
	for _, packName in savedData.Data.SkillPacks do
		keybindsInfo[packName] = SkillLibrary.GetKeybindsInfoPack(packName)
	end
	remoteEvent:Fire(player, "SkillPacks", keybindsInfo)
	print("Sent " .. player.Name .. "'s skill packs keybinds info")

	print("Sent all data to " .. player.Name .. "'s client")
end

local function playerRemoving(player: Player)
	print("Player " .. player.Name .. " removing")

	savePlayerData(player)
	TempData.DeleteData(player)
end

--// BINDING TO CLOSING OF GAME SAVING DATA OF ALL PLAYERS
if not STUDIO_MODE then
	game:BindToClose(function()
		saveAllPlayersData()
		print("Saved all players data before server closing")
	end)
end

--// ENABLING AUTOSAVING
if not STUDIO_MODE then
	task.spawn(function()
		while task.wait(AUTOSAVE_INTERVAL) do
			saveAllPlayersData()
			print("Autosave finished")
		end
	end)
end

--// EVENTS
Players.PlayerAdded:Connect(playerAdded)
Players.PlayerRemoving:Connect(playerRemoving)
remoteEvent:On("ReadyForData", sendDataToClient)
remoteEvent:On("LoadCharacter", loadCharacter)

return true
