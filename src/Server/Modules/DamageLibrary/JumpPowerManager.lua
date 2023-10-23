--// TYPES
type Config = {
	Value: number,
	Priority: number,
	Duration: number,
}

--VARIABLES
local JumpPowerManager = {}

--// MODULE FUNCTIONS
function JumpPowerManager.MakeConfig(): Config
	return {}
end

function JumpPowerManager.Change(character: Model, tempData: {}, config: Config)
	local existingChange = tempData.JumpPowerChange
	local priority = config.Priority
	if existingChange and existingChange.Priority > priority then
		return
	end

	local humanoid = character.Humanoid
	local startTime = os.clock()
	tempData.JumpPowerChange = {
		InitValue = if existingChange then existingChange.InitValue else humanoid.JumpPower,
		Priority = priority,
		StartTime = startTime,
	}
	humanoid.JumpPower = config.Value

	local duration = config.Duration
	if duration then
		task.delay(duration, function()
			local currentChange = tempData.JumpPowerChange
			if currentChange and currentChange.StartTime == startTime then
				JumpPowerManager.Cancel(character, tempData)
			end
		end)
	end
end

function JumpPowerManager.Cancel(character: Model, tempData: {})
	local change = tempData.JumpPowerChange
	if not change then
		return
	end

	if character then
		local humanoid = character.Humanoid
		humanoid.JumpPower = change.InitValue
	end
	
	tempData.JumpPowerChange = nil
end

return JumpPowerManager