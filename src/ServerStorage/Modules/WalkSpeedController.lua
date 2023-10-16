--VARIABLES
local WalkSpeedController = {}

--// MODULE FUNCTIONS
function WalkSpeedController.Change(character: Model, tempData: {},	value: number, priority: number, duration: number?)
	local existingChange = tempData.WalkSpeedChange
	if existingChange and existingChange.Priority > priority then
		return
	end

	local humanoid = character.Humanoid
	local startTime = tick()
	tempData.WalkSpeedChange = {
		Value = value,
		Priority = priority,
		InitSpeed = if existingChange then existingChange.InitSpeed else humanoid.WalkSpeed,
		StartTime = if duration then tick() else nil
	}
	humanoid.WalkSpeed = value

	if not duration then return end
	task.delay(duration, function()
		local currentChange = tempData.WalkSpeedChange
		if currentChange and currentChange.StartTime == startTime then
			WalkSpeedController.Cancel(character, tempData)
		end
	end)
end

function WalkSpeedController.Cancel(character: Model, tempData: {})
	local change = tempData.WalkSpeedChange
	if change then
		local humanoid = character.Humanoid
		humanoid.WalkSpeed = change.InitSpeed

		tempData.WalkSpeedChange = nil
	end
end

return WalkSpeedController