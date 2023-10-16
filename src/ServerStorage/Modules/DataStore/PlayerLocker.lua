--// TYPES
export type PlayerLocker = {
	Lock: (self: PlayerLocker, player: Player) -> (),
	Unlock: (self: PlayerLocker, player: Player) -> (),
	IsLocked: (self: PlayerLocker, player: Player) -> boolean,
	WaitForUnlocking: (self: PlayerLocker, player: Player) -> (),
}

--// CLASSES
local PlayerLocker: PlayerLocker = {}
PlayerLocker.__index = PlayerLocker

--// SESSIONLOCKER FUNCTIONS
function PlayerLocker:Lock(player: Player): ()
	self[player] = true
end

function PlayerLocker:Unlock(player: Player): ()
	self[player] = nil
end

function PlayerLocker:IsLocked(player: Player): ()
	return self[player]
end

function PlayerLocker:WaitForUnlocking(player: Player): ()
	if self:IsLocked(player) then
		repeat
			task.wait()
		until not self:IsLocked(player)
	end
end

--// MODULE FUNCTIONS
return {
	new = function(): PlayerLocker
		return setmetatable({}, PlayerLocker)
	end,
}
