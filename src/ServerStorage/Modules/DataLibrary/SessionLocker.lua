--// SERVICES
local MemoryStoreService = game:GetService("MemoryStoreService")

--// TYPES
type SessionLocker = {
	Lock:(self:SessionLocker, player:Player) -> boolean,
	Unlock:(self:SessionLocker, player:Player) -> nil
}

--// CLASSES
local SessionLocker = {}
SessionLocker.__index = SessionLocker

--// VARIABLES
local renewingEnabled = false

local sessionLockers = {}

--// CONFIG
local LOCK_DURATION = 120

--// FUNCTIONS
local function areThereLockedPlayers()
	for _, sessionLocker in pairs(sessionLockers) do
		for _, _ in ipairs(sessionLocker._lockedPlayers) do
			return true
		end
	end
	return false
end

local function disableRenewing()
	renewingEnabled = false
end

local function enableRenewing()
	if not areThereLockedPlayers() then
		disableRenewing()
	end

	task.spawn(function()
		while task.wait(5) do
			for _, sessionLocker in pairs(sessionLockers) do
				for player, lastLock in ipairs(sessionLocker._lockedPlayers) do
					if tick() - lastLock < LOCK_DURATION then continue end
					sessionLocker._sortedMap:SetAsync(player.UserId, true, LOCK_DURATION)
					sessionLocker._lockedPlayers[player] = tick()
				end
			end
		end
	end)
end

--// SESSIONLOCKER FUNCTIONS
function SessionLocker:Lock(player:Player)
	local wasLocked = false

	local success, err = pcall(function()
		self._sortedMap:UpdateAsync(player.UserId, function(oldValue:boolean)
			if oldValue then
				wasLocked = true
				return nil
			else
				return true
			end
		end, LOCK_DURATION)
	end)

	if not success then
		warn("Session locker "..self.Name.." threw an error: "..err)
	end

	if not wasLocked then
		self._lockedPlayers[player] = tick()
		if not renewingEnabled then
			enableRenewing()
		end
	end

	return wasLocked
end

function SessionLocker:Unlock(player:Player)
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
	new = function(name:string)
		local sessionLocker = setmetatable({
			Name = name,
			_lockedPlayers = {},
			_sortedMap = MemoryStoreService:GetSortedMap(name)
		}, SessionLocker)

		sessionLockers[name] = sessionLocker
		return sessionLocker
	end
}