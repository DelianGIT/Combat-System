--// CLASSES
local CooldownStore = {}
CooldownStore.__index = CooldownStore

--// MODULE FUNCTIONS
function CooldownStore:Add(action:string, duration:number)
	self[action] = {0, duration}
end

function CooldownStore:Start(action:string)
	self[action][1] = tick()
end

function CooldownStore:Remove(action:string)
	self[action] = nil
end

function CooldownStore:IsOnCooldown(action:string)
	local cooldown = self[action]
	return cooldown and tick() - cooldown[1] < cooldown[2] or false
end

return {
	CreateCooldownStore = function()
		return setmetatable({}, CooldownStore)
	end
}