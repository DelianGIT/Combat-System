--VARIABLES
local JumpPowerController = {}

--// MODULE FUNCTIONS
function JumpPowerController.Change(character: Model, tempData: {},	value: number, priority: number, duration: number?)
	local existingChange = tempData.JumpPowerChange
	if existingChange and existingChange.Priority > priority then
		return
	end

	local humanoid = character.Humanoid
	local startTime = tick()
	tempData.JumpPowerChange = {
		Value = value,
		Priority = priority,
		InitPower = if existingChange then existingChange.InitPower else humanoid.JumpPower,
		StartTime = if duration then tick() else nil
	}
	humanoid.JumpPower = value
	
	if not duration then return end
	task.delay(duration, function()
		local currentChange = tempData.JumpPowerChange
		if currentChange and currentChange.StartTime == startTime then
			JumpPowerController.Cancel(character, tempData)
		end
	end)
end

function JumpPowerController.Cancel(character: Model, tempData: {})
	local change = tempData.JumpPowerChange
	if change then
		local humanoid = character.Humanoid
		humanoid.JumpPower = change.InitPower

		tempData.JumpPowerChange = nil
	end
end

return JumpPowerController