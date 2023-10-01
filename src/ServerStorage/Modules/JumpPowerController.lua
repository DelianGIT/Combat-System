--VARIABLES
local JumpPowerController = {}

--// MODULE FUNCTIONS
function JumpPowerController.Change(character: Model, tempData: {},	value: number, priority: number, duration: number?)
	local existingChange = tempData.WalkSpeedChange
	if existingChange and existingChange[1] >= priority then
		return
	end

	local humanoid = character.Humanoid
	local startTime = tick()
	tempData.JumpPowerChange = {
		priority,
		value,
		if existingChange then existingChange[3] else humanoid.JumpPower,
		startTime,
	}
	humanoid.JumpPower = value

	if not duration then return end
	task.delay(duration, function()
		local currentChange = tempData.JumpPowerChange
		if currentChange and currentChange[4] == startTime then
			JumpPowerController.Cancel(character, tempData)
		end
	end)
end

function JumpPowerController.Cancel(character: Model, tempData: {})
	local change = tempData.JumpPowerChange
	if change then
		local humanoid = character.Humanoid
		humanoid.JumpPower = change[3]

		tempData.JumpPowerChange = nil
	end
end

return JumpPowerController