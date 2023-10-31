--// SERVICES
local DataStoreService = game:GetService("DataStoreService")

--// MODULES
local ProfileStore = require(script.ProfileStore)
local SessionLocker = require(script.SessionLocker)
local PlayerLocker = require(script.PlayerLocker)

--// TYPES
type DataStore = {
	Name: string,
	GlobalDataStore: GlobalDataStore,
	ProfileStore: ProfileStore.ProfileStore,
	SessionLocker: SessionLocker.SessionLocker,
	PlayerLocker: PlayerLocker.PlayerLocker,

	Load: (self: DataStore, player: Player) -> ProfileStore.Profile,
	Get: (self: DataStore, player: Player) -> ProfileStore.Profile,
	Remove: (self: DataStore, player: Player) -> (),
	Save: (self: DataStore, player: Player) -> (),
}

--// CLASSES
local DataStore: DataStore = {}
DataStore.__index = DataStore

--// VARIABLES
local studioMode = false

--// CHECK IF DATA STORES ARE ENABLED
if game.GameId < 1 then
	warn("Game is not connected to a universe, cannot load DataStores")
	return false
end

--// FUNCTIONS
local function waitForRequestBudget(requestType: Enum.DataStoreRequestType)
	local budget = DataStoreService:GetRequestBudgetForRequestType(requestType)

	while budget == 0 and task.wait(5) do
		budget = DataStoreService:GetRequestBudgetForRequestType(requestType)
	end
end

local function getAsync(dataStore: GlobalDataStore, key: string)
	local success, result
	local attempts = 0

	repeat
		waitForRequestBudget(Enum.DataStoreRequestType.GetAsync)

		success, result = pcall(dataStore.GetAsync, dataStore, key)
		attempts += 1

		if not success then
			warn(result)
		end
	until success or attempts >= 5

	return success, result
end

function setAsync(dataStore: DataStore, key: string, value: any)
	local success, err
	local attempts = 0

	repeat
		waitForRequestBudget(Enum.DataStoreRequestType.SetIncrementAsync)

		success, err = pcall(dataStore.SetAsync, dataStore, key, value)
		attempts += 1

		if not success then
			warn(err)
		end
	until success or attempts >= 5

	return success, err
end

--// DATASTORE FUNCTIONS
function DataStore:Load(player: Player): ProfileStore.Profile
	local existingData = self:Get(player)
	if existingData then
		return existingData
	end

	self.PlayerLocker:Lock(player)

	if studioMode then
		local profile = self.ProfileStore:CreateProfile(player)
		self.PlayerLocker:Unlock(player)
		return profile
	end

	local isLocked = self.SessionLocker:Lock(player)
	if isLocked then
		warn(player.Name .. "'s session is locked")
		self.PlayerLocker:Unlock(player)
		return
	end

	local success, data = getAsync(self.GlobalDataStore, player.UserId)
	if not success then
		self.PlayerLocker:Unlock(player)
	else
		local profile = self.ProfileStore:CreateProfile(player, data)
		self.PlayerLocker:Unlock(player)
		return profile
	end
end

function DataStore:Get(player: Player): ProfileStore.Profile
	return self.ProfileStore:GetProfile(player)
end

function DataStore:Remove(player: Player)
	self.PlayerLocker:WaitForUnlocking(player)

	self.ProfileStore:DeleteProfile(player)
	if not studioMode then
		self.SessionLocker:Unlock(player)
	end
end

function DataStore:Save(player: Player)
	self.PlayerLocker:WaitForUnlocking(player)
	self.PlayerLocker:Lock(player)

	local profile = self.ProfileStore:GetProfile(player)
	if profile then
		profile.Metadata.UpdatedTime = tick()
		if not studioMode then
			setAsync(self.GlobalDataStore, player.UserId, profile)
		end
	end

	self.PlayerLocker:Unlock(player)
end

--// MODULE FUNCTIONS
return {
	new = function(name: string, profileTemplate: ProfileStore.Template): DataStore
		if studioMode then
			return setmetatable({
				Name = name,
				ProfileStore = ProfileStore.new(profileTemplate),
				PlayerLocker = PlayerLocker.new(),
			}, DataStore)
		else
			return setmetatable({
				Name = name,
				GlobalDataStore = DataStoreService:GetDataStore(name),
				ProfileStore = ProfileStore.new(profileTemplate),
				SessionLocker = SessionLocker.new(name),
				PlayerLocker = PlayerLocker.new(),
			}, DataStore)
		end
	end,

	ToggleStudioMode = function(enabled: boolean)
		studioMode = enabled
	end,
}
