--// SERVICES
local DataStoreService = game:GetService("DataStoreService")

--// MODULES
local ProfileStore = require(script.ProfileStore)
local Utilities = require(script.Utilities)
local SessionLocker = require(script.SessionLocker)

--// TYPES
type DataStore = {
	Name:string,
	ProfileStore:ProfileStore.ProfileStore,

	LoadData:(self:DataStore, player:Player, studioMode:boolean) -> {any},
	GetData:(self:DataStore, player:Player) -> {any},
	SaveData:(self:DataStore, player:Player, studioMode:boolean) -> nil,
	RemoveData:(self:DataStore, player:Player, studioMode:boolean) -> nil
}

--// CLASSES
local DataStore:DataStore = {}
DataStore.__index = DataStore

--// VARIABLES
local dataStores = {}

--// CHECK IF DATA STORES ARE ENABLED
if game.GameId < 1 then
	warn("Game is not connected to a universe, cannot load DataStores.")
	return { Success = false }
end

--// FUNCTIONS
local function lockPlayer(dataStore:DataStore, player:Player, reason:string)
	dataStore._lockedPlayers[player] = reason
end

local function unlockPlayer(dataStore:DataStore, player:Player)
	dataStore._lockedPlayers[player] = nil
end

local function isPlayerLocked(dataStore: DataStore, player:Player)
	return dataStore._lockedPlayers[player]
end

local function waitForUnlockingPlayer(dataStore:DataStore, player:Player)
	if isPlayerLocked(dataStore, player) then
		repeat until not isPlayerLocked(dataStore, player)
	end
end

--// DATASTORE FUNCTIONS
function DataStore:LoadData(player:Player, studioMode:boolean):ProfileStore.Profile
	lockPlayer(self, player, "Loading")

	if studioMode then
		local profile = self.ProfileStore:CreateProfile(player)
		print("Loaded data from "..self.Name.." for "..player.Name)
		unlockPlayer(self, player)
		return profile
	end

	local isLocked = self._sessionLocker:Lock(player)
	if isLocked then
		warn(player.Name.."'s session is locked")
		unlockPlayer(self, player)
		return
	end

	local success, data = Utilities.GetAsync(self._globalDataStore, player.UserId)
	if not success then
		unlockPlayer(self, player)
		return false
	else
		local profile = self.ProfileStore:CreateProfile(player, data)
		print("Loaded data from "..self.Name.." for "..player.Name)
		unlockPlayer(self, player)
		return profile
	end
end

function DataStore:GetData(player:Player):ProfileStore.Profile
	return self.ProfileStore:GetProfile(player)
end

function DataStore:SaveData(player:Player, studioMode:boolean):nil
	waitForUnlockingPlayer(self, player)
	lockPlayer(self, player, "Saving")

	local profile = self.ProfileStore:GetProfile(player)
	if profile then
		profile.Metadata.UpdatedTime = tick()
		if not studioMode then
			Utilities.SetAsync(self._globalDataStore, player.UserId, profile)
		end
		print("Saved data from "..self.Name.." for "..player.Name)
	end

	unlockPlayer(self, player)
end

function DataStore:RemoveData(player:Player, studioMode:boolean):nil
	waitForUnlockingPlayer(self, player)

	self.ProfileStore:DeleteProfile(player)
	if not studioMode then
		self._sessionLocker:Unlock(player)
	end
	
	print("Removed "..player.Name.."'s data of "..self.Name)
end

--// MODULE FUNCTIONS
return {
	CreateDataStore = function(name:string, profileTemplate:ProfileStore.ProfileTemplate):DataStore
		if type(name) ~= "string" then
			error("Name must be a string")
		end
		if type(profileTemplate) ~= "table" then
			error("Profile template must be a table")
		end

		local dataStore = setmetatable({
			Name = name,
			ProfileStore = ProfileStore.new(profileTemplate),
			_globalDataStore = DataStoreService:GetDataStore(name),
			_sessionLocker = SessionLocker.new(name),
			_lockedPlayers = {}
		}, DataStore)

		dataStores[name] = dataStore
		return dataStore
	end,

	GetDataStore = function(name:string):DataStore
		local dataStore = dataStores[name]
		if not dataStore then
			error("DataStore "..name.." not found")
		else
			return dataStores[name]
		end
	end
}