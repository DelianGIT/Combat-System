--// TYPES
export type CooldownStore = {
	Add: (self: CooldownStore, action: string, duration: number) -> (),
	Start: (self: CooldownStore, action: string) -> (),
	Remove: (self: CooldownStore, action: string) -> (),
	IsOnCooldown: (self: CooldownStore, action: string) -> (),
}

--// CLASSES
local CooldownStore: CooldownStore = {}
CooldownStore.__index = CooldownStore

--// MODULE FUNCTIONS
function CooldownStore:Add(action: string, duration: number)
	self[action] = { 0, duration }
end

function CooldownStore:Start(action: string)
	local cooldown = self[action]
	cooldown[1] = tick()
	return cooldown[2]
end

function CooldownStore:Remove(action: string)
	self[action] = nil
end

function CooldownStore:IsOnCooldown(action: string)
	local cooldown = self[action]
	return cooldown and tick() - cooldown[1] < cooldown[2] or false
end

return {
	new = function()
		return setmetatable({}, CooldownStore)
	end,
}
