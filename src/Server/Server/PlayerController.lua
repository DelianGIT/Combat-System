--// SERVICES
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")

--// MODULES
local ServerModules = ServerStorage.Modules
local DataStore = require(ServerModules.DataStore)
local TempData = require(ServerModules.TempData)
local CharacterMaker = require(ServerModules.CharacterMaker)
local SkillLibrary = require(ServerModules.SkillLibrary)

--// CONFIG
local STUDIO_MODE = false and RunService:IsStudio()
local AUTOSAVE_INTERVAL = 300

--// VARIABLES
local remoteEvents = ReplicatedStorage.Events
local remoteEvent = require(remoteEvents.LoadingControl):Server()

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

--// BINDING TO CLOSING OF GAME SAVING DATA OF ALL PLAYERS
if not STUDIO_MODE then
	game:BindToClose(function()
		for _, player in Players:GetPlayers() do
			mainDataStore:Save(player)
			mainDataStore:Remove(player)
		end
	end)
end

--// ENABLING AUTOSAVING
if not STUDIO_MODE then
	task.spawn(function()
		while task.wait(AUTOSAVE_INTERVAL) do
			for _, player in Players:GetPlayers() do
				mainDataStore:Save(player)
			end
		end
	end)
end

--// EVENTS
Players.PlayerAdded:Connect(function(player: Player)
	notLoadedPlayers[player] = true

	local savedData = mainDataStore:Load(player)
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
	print(player.Name .. "'s data loaded")
end)

Players.PlayerRemoving:Connect(function(player: Player)
	notLoadedPlayers[player] = nil

	local tempData = TempData.Get(player)
	if tempData then
		if not tempData.NotLoaded then
			local skillPacks = tempData.SkillPacks
			local activeSkills = tempData.ActiveSkills

			for identifier, _ in activeSkills do
				local splittedString = string.split(identifier, "_")
				local pack = skillPacks[splittedString[1]]
				task.spawn(function()
					pack:InterruptSkill(splittedString[2], true)
				end)
			end
		end

		TempData.Delete(player)
	end

	mainDataStore:Save(player)
	mainDataStore:Remove(player)

	print(player.Name .. "'s data removed")
end)

remoteEvent:On(function(player: Player, action: string)
	if action == "ReadyForData" then
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
	elseif action == "LoadCharacter" then
		local tempData = TempData.Get(player)
		if not tempData.NotLoadedCharacter then
			return
		end

		CharacterMaker.Make(player, tempData)
		tempData.NotLoadedCharacter = nil
		
		print(player.Name .. " is fully loaded")
	end
end)

return true