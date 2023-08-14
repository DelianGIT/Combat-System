--// SERVICES
local RunService = game:GetService("RunService")

--// VARIABLES
local heartbeatConnection

local cooldowns = {} -- action:{startTime, duration}
local Cooldowns = {}

--// FUNCTIONS
local function checkArguments(action:string, duration:number?)
	if type(action) ~= "string" then
		error("Action must be a string")
	end

	if type(duration) then
		error("Duration must be a number")
	end
end

local function disconnectHeartbeat()
	if heartbeatConnection then
		heartbeatConnection:Disconnect()
		heartbeatConnection = nil
	end
end

local function areThereCooldowns()
	for _, _ in pairs(cooldowns) do
		return true
	end
	return false
end

local function connectHearbeat()
	heartbeatConnection = RunService.Heartbeat:Connect(function()
		if not areThereCooldowns() then
			disconnectHeartbeat()
		end

		for action, cooldown in pairs(cooldowns) do
			if tick() - cooldown[1] >= cooldown[2] then
				cooldowns[action] = nil
			end
		end
	end)
end

--// MODULE FUNCTIONS
function Cooldowns.Add(action:string, duration:number)
	checkArguments(action, duration)
	cooldowns[action] = {tick(), duration}
	if not heartbeatConnection then
		connectHearbeat()
	end
end

function Cooldowns.Remove(action:string)
	checkArguments(action)
	cooldowns[action] = nil
end

function Cooldowns.IsOnCooldown(action:string)
	checkArguments(action)
	local cooldown = cooldowns[action]
	return cooldown and tick() - cooldown[1] < cooldown[2] or false
end

return Cooldowns