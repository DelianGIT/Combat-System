--// MODULES
local WalkSpeedManager = require(script.Parent.WalkSpeedManager)
local JumpPowerManager = require(script.Parent.JumpPowerManager)

--// TYPES
export type Config = {
	Priority: number,
	Duration: number,
	WalkSpeed: number,
	JumpPower: number,

	BlockSkills: boolean,
}

--// VARIABLES
local StunManager = {}

--// MODULE FUNCTIONS
function StunManager.MakeConfig(): Config
	return {}
end

function StunManager.Apply(character: Model, tempData: {}, config: Config)
	local existingStun = tempData.Stun
	local priority = config.Priority
	if existingStun and existingStun.Priority >= priority then
		return
	end

	local startTime = tick()
	tempData.Stun = {
		StartTime = startTime,
		Priority = priority,
		BlockSkills = config.BlockSkills,
	}

	local duration = config.Duration
	WalkSpeedManager.Change(character, tempData, {
		Value = config.WalkSpeed,
		Priority = priority,
		Duration = duration,
	})
	JumpPowerManager.Change(character, tempData, {
		Value = config.JumpPower,
		Priority = priority,
		Duration = duration,
	})

	if duration then
		task.delay(config.Duration, function()
			local newStun = tempData.Stun
			if newStun and newStun.StartTime == startTime then
				StunManager.Cancel(character, tempData)
			end
		end)
	end
end

function StunManager.Cancel(character: Model, tempData: {})
	if not tempData.Stun then
		return
	end

	tempData.Stun = nil

	WalkSpeedManager.Cancel(character, tempData)
	JumpPowerManager.Cancel(character, tempData)
end

return StunManager
