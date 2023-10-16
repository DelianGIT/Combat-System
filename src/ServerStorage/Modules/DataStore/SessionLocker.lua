--// SERVICES
local MemoryStoreService = game:GetService("MemoryStoreService")

--// TYPES
export type SessionLocker = {
	SortedMap: MemoryStoreSortedMap,
	LockedPlayers: {[Player]: number},

	Lock: (self: SessionLocker, player: Player) -> boolean,
	Unlock: (self: SessionLocker, player: Player) -> (),
}

--// CLASSES
local SessionLocker: SessionLocker = {}
SessionLocker.__index = SessionLocker

--// CONFIG
local LOCK_DURATION = 120

--// VARIABLES
local renewingEnabled = false

local sessionLockers = {}

--// FUNCTIONS
local function renewLocking()
	local areThereLockedPlayers = false

	for _, sessionLocker in sessionLockers do
		local sortedMap = sessionLocker.SortedMap
		local lockedPlayers = sessionLocker.LockedPlayers

		for player, lastLockTime in lockedPlayers do
			if tick() - lastLockTime >= LOCK_DURATION then
				continue
			end

			sortedMap:SetAsync(player.UserId, true, LOCK_DURATION)
			lockedPlayers[player] = tick()

			areThereLockedPlayers = true
		end
	end

	return areThereLockedPlayers
end

local function disableRenewing()
	renewingEnabled = false
end

local function enableRenewing()
	renewingEnabled = true

	task.spawn(function()
		while renewingEnabled and task.wait(5) do
			local areThereLockedPlayers = renewLocking()
			if areThereLockedPlayers then
				disableRenewing()
			end
		end
	end)
end

--// SESSION LOCKER FUNCTIONS
function SessionLocker:Lock(player: Player): boolean
	local wasLocked = true

	local success, err = pcall(function()
		self.SortedMap:UpdateAsync(player.UserId, function(oldValue: boolean)
			if oldValue then
				return nil
			else
				wasLocked = false
				return true
			end
		end, LOCK_DURATION)
	end)

	if not success then
		warn("Session locker " .. self.Name .. " threw an error: " .. err)
	elseif not wasLocked then
		self.LockedPlayers[player] = tick()
		if not renewingEnabled then
			enableRenewing()
		end
	end
	
	return wasLocked
end

function SessionLocker:Unlock(player: Player): ()
	local success, err = pcall(function()
		self.SortedMap:RemoveAsync(player.UserId)
	end)

	if not success then
		warn("Session locker " .. self.Name .. " threw an error: " .. err)
	end

	self.LockedPlayers[player] = nil
end

--// MODULE FUNCTIONS
return {
	new = function(name: string): SessionLocker
		local sessionLocker = setmetatable({
			Name = name,
			LockedPlayers = {},
			SortedMap = MemoryStoreService:GetSortedMap(name),
		}, SessionLocker)

		sessionLockers[name] = sessionLocker

		return sessionLocker
	end,
}
