--// SERVICES
local MemoryStoreService = game:GetService("MemoryStoreService")

--// TYPES
type SessionLocker = {
	Lock:(self:SessionLocker, player:Player) -> boolean,
	Unlock:(self:SessionLocker, player:Player) -> ()
}

--// CLASSES
local SessionLocker:SessionLocker = {}
SessionLocker.__index = SessionLocker

--// VARIABLES
local renewingEnabled = false

local sessionLockers = {}

--// CONFIG
local LOCK_DURATION = 120

--// FUNCTIONS
local function areThereLockedPlayers()
	for _, sessionLocker in sessionLockers do
		for _, _ in sessionLocker._lockedPlayers do
			return true
		end
	end
	return false
end

local function renewLocking()
	for _, sessionLocker in sessionLockers do
		local sortedMap = sessionLocker._sortedMap
		local lockedPlayers = sessionLocker._lockedPlayers

		for player, lastLock in lockedPlayers do
			if tick() - lastLock < LOCK_DURATION then continue end
			sortedMap:SetAsync(player.UserId, true, LOCK_DURATION)
			lockedPlayers[player] = tick()
		end
	end
end

local function disableRenewing()
	renewingEnabled = false
end

local function enableRenewing()
	renewingEnabled = true

	task.spawn(function()
		while renewingEnabled and task.wait(5) do
			if not areThereLockedPlayers() then
				disableRenewing()
			end
			renewLocking()
		end
	end)
end

--// SESSIONLOCKER FUNCTIONS
function SessionLocker:Lock(player:Player):boolean
	local wasLocked = true

	local success, err = pcall(function()
		self._sortedMap:UpdateAsync(player.UserId, function(oldValue:boolean)
			if oldValue then
				return nil
			else
				wasLocked = false
				return true
			end
		end, LOCK_DURATION)
	end)

	if not success then
		warn("Session locker "..self.Name.." threw an error: "..err)
	elseif success and not wasLocked then
		self._lockedPlayers[player] = tick()
		if not renewingEnabled then
			enableRenewing()
		end
	end

	return wasLocked
end

function SessionLocker:Unlock(player:Player):()
	self._lockedPlayers[player] = nil
	
	local success, err = pcall(function()
		self._sortedMap:RemoveAsync(player.UserId)
	end)

	if not success then
		warn("Session locker "..self.Name.." threw an error: "..err)
	end
end

--// MODULE FUNCTIONS
return {
	new = function(name:string):SessionLocker
		local sessionLocker = setmetatable({
			Name = name,
			_lockedPlayers = {},
			_sortedMap = MemoryStoreService:GetSortedMap(name)
		}, SessionLocker)

		sessionLockers[name] = sessionLocker
		
		return sessionLocker
	end
}