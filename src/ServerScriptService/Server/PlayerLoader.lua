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
local CharacterMaker = require(ServerModules.CharacterMaker)

--// PACKAGES
local Packages = ReplicatedStorage.Packages
local Red = require(Packages.Red)

--// VARIABLES
local remoteEvent = Red.Server("LoadingControl")

local loadedPlayers = {}

--// CONFIG
local STUDIO_MODE = false
STUDIO_MODE = STUDIO_MODE and RunService:IsStudio()

local AUTOSAVE_INTERVAL = 300 -- In seconds

--// DATA STORES CONFIGURATION
DataLibrary.ToggleStudioMode(STUDIO_MODE)

local dataStore = DataLibrary.CreateDataStore("Main", {
	SkillPacks = { "Main" },
})

TempData.SetProfileTemplate({
	SkillPacks = {},
	ActiveSkills = {},
	CanUseSkills = true,
	NotLoaded = true,
	NotLoadedCharacter = true,
	BlockMaxDurability = 10,
})

--// FUNCTIONS
local function loadCharacter(player: Player)
	local tempData = TempData.Get(player)
	if tempData.NotLoadedCharacter then
		tempData.NotLoadedCharacter = nil
		CharacterMaker.Make(player, tempData)
	end
end

local function savePlayerData(player)
	dataStore:Save(player, STUDIO_MODE)
	dataStore:Remove(player, STUDIO_MODE)
end

local function saveAllPlayersData()
	for _, player in Players:GetPlayers() do
		savePlayerData(player)
	end
end

local function sendDataToClient(player: Player)
	if not loadedPlayers[player] then
		repeat task.wait() until loadedPlayers[player]
		loadedPlayers[player] = nil
	end

	local tempData = TempData.Get(player)

	local givenPacks = {}
	for packName, _ in tempData.SkillPacks do
		table.insert(givenPacks, packName)
	end
	remoteEvent:Fire(player, "SkillPacks", givenPacks)

	print("Sent all data to " .. player.Name .. "'s client")
end

local function playerAdded(player: Player)
	print("Player " .. player.Name .. " added")

	local savedData = dataStore:Load(player, STUDIO_MODE)
	if not savedData then
		player:Kick("Error while loading data")
		return
	end

	if player.Parent ~= Players then
		return
	end

	local tempData = TempData.Create(player)

	for _, packName in savedData.Data.SkillPacks do
		SkillLibrary.GiveSkillPack(packName, player, tempData)
	end

	loadedPlayers[player] = true
	tempData.NotLoaded = nil

	print(player.Name .. "'s data loaded")
end

local function playerRemoving(player: Player)
	print("Player " .. player.Name .. " removing")

	local tempData = TempData.Get(player)
	if tempData and not tempData.NotLoaded then
		if not tempData.NotLoaded then
			task.spawn(function()
				local skillPacks = tempData.SkillPacks
				local activeSkills = tempData.ActiveSkills

				for skillName, properties in activeSkills do
					local pack = skillPacks[properties.PackName] 
					pack:InterruptSkill(skillName, true)
				end
	
				for _, pack in tempData.SkillPacks do
					pack.Communicator:Destroy()
				end
			end)
		end

		TempData.Delete(player)
	end

	savePlayerData(player)

	print(player.Name .. "'s data removed")
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
Players.PlayerAdded:Connect(playerAdded)
Players.PlayerRemoving:Connect(playerRemoving)

remoteEvent:On("ReadyForData", sendDataToClient)
remoteEvent:On("LoadCharacter", loadCharacter)

return true
