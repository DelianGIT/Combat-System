--// SERVICES
local DataStoreService = game:GetService("DataStoreService")

--// MODULES
local ProfileStore = require(script.ProfileStore)
local Utilities = require(script.Utilities)
local SessionLocker = require(script.SessionLocker)
local PlayerLocker = require(script.PlayerLocker)

--// TYPES
type DataStore = {
	Name: string,

	LoadData: (self: DataStore, player: Player, studioMode: boolean) -> ProfileStore.Profile,
	GetData: (self: DataStore, player: Player) -> ProfileStore.Profile,
	SaveData: (self: DataStore, player: Player, studioMode: boolean) -> (),
	RemoveData: (self: DataStore, player: Player, studioMode: boolean) -> (),
}

--// CLASSES
local DataStore: DataStore = {}
DataStore.__index = DataStore

--// VARIABLES
local studioMode = false

local dataStores = {}

--// CHECK IF DATA STORES ARE ENABLED
if game.GameId < 1 then
	warn("Game is not connected to a universe, cannot load DataStores")
	return false
end

--// DATASTORE FUNCTIONS
function DataStore:LoadData(player: Player): ProfileStore.Profile
	self._playerLocker:Lock(player)

	if studioMode then
		local profile = self._profileStore:CreateProfile(player)
		self._playerLocker:Unlock(player)
		return profile
	end

	local isLocked = self._sessionLocker:Lock(player)
	if isLocked then
		warn(player.Name .. "'s session is locked")
		self._playerLocker:Unlock(player)
		return
	end

	local success, data = Utilities.GetAsync(self._globalDataStore, player.UserId)
	if not success then
		self._playerLocker:Unlock(player)
		return false, data
	else
		local profile = self._profileStore:CreateProfile(player, data)
		self._playerLocker:Unlock(player)
		return profile
	end
end

function DataStore:GetData(player: Player): ProfileStore.Profile
	return self._profileStore:GetProfile(player)
end

function DataStore:SaveData(player: Player): ()
	self._playerLocker:WaitForUnlocking(player)
	self._playerLocker:Lock(player)

	local profile = self._profileStore:GetProfile(player)
	if profile then
		profile.Metadata.UpdatedTime = tick()
		if not studioMode then
			Utilities.SetAsync(self._globalDataStore, player.UserId, profile)
		end
	end

	self._playerLocker:Unlock(player)
end

function DataStore:RemoveData(player: Player): ()
	self._playerLocker:WaitForUnlocking(player)

	self._profileStore:DeleteProfile(player)
	if not studioMode then
		self._sessionLocker:Unlock(player)
	end
end

--// MODULE FUNCTIONS
return {
	CreateDataStore = function(name: string, profileTemplate: ProfileStore.ProfileTemplate): DataStore
		local dataStore = setmetatable({
			Name = name,
			_profileStore = ProfileStore.new(profileTemplate),
			_globalDataStore = if studioMode then DataStoreService:GetDataStore(name) else nil,
			_sessionLocker = if studioMode then SessionLocker.new(name) else nil,
			_playerLocker = PlayerLocker.new(),
		}, DataStore)

		dataStores[name] = dataStore

		return dataStore
	end,

	GetDataStore = function(name: string): DataStore
		return dataStores[name]
	end,

	ToggleStudioMode = function(enabled: boolean)
		studioMode = enabled
	end,
}
