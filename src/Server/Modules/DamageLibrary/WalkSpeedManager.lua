--// TYPES
type Config = {
	Value: number,
	Priority: number,
	Duration: number,
}

--VARIABLES
local WalkSpeedManager = {}

--// MODULE FUNCTIONS
function WalkSpeedManager.MakeConfig(): Config
	return {}
end

function WalkSpeedManager.Change(character: Model, tempData: {}, config: Config)
	local existingChange = tempData.WalkSpeedChange
	local priority = config.Priority
	if existingChange and existingChange.Priority > priority then
		return
	end

	local humanoid = character.Humanoid
	local startTime = os.clock()
	tempData.WalkSpeedChange = {
		InitValue = if existingChange then existingChange.InitValue else humanoid.WalkSpeed,
		Priority = priority,
		StartTime = startTime,
	}
	humanoid.WalkSpeed = config.Value

	local duration = config.Duration
	if duration then
		task.delay(duration, function()
			local currentChange = tempData.WalkSpeedChange
			if currentChange and currentChange.StartTime == startTime then
				WalkSpeedManager.Cancel(character, tempData)
			end
		end)
	end
end

function WalkSpeedManager.Cancel(character: Model, tempData: {})
	local change = tempData.WalkSpeedChange
	if not change then
		return
	end

	if character then
		local humanoid = character.Humanoid
		humanoid.WalkSpeed = change.InitValue
	end

	tempData.WalkSpeedChange = nil
end

return WalkSpeedManager