--// TYPES
export type CooldownStore = {
	Add: (self: CooldownStore, action: string, duration: number) -> (),
	Start: (self: CooldownStore, action: string) -> number,
	IsOnCooldown: (self: CooldownStore, action: string) -> boolean,
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

function CooldownStore:IsOnCooldown(action: string)
	local cooldown = self[action]
	return if cooldown then tick() - cooldown[1] < cooldown[2] else false
end

return {
	new = function(): CooldownStore
		return setmetatable({}, CooldownStore)
	end
}