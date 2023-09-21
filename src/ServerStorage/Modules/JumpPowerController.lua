--VARIABLES
local JumpPowerController = {}

--// MODULE FUNCTIONS
function JumpPowerController.Change(character: Model, tempData: {[any]: any}, value: number, duration: number?, priority: number)
	local existingChange = tempData.JumpPowerChange
	if existingChange or existingChange[1] >= priority then
		return
	end

	local humanoid = character.humanoid
	local startTime = tick()
	tempData.JumpPowerChange = {
		priority,
		value,
		if existingChange then existingChange[3] else humanoid.JumpPower,
		startTime
	}
	humanoid.JumpPower = value

	if duration then
		task.delay(duration, function()
			local currentChange = tempData.JumpPowerChange
			if currentChange and currentChange[4] == startTime then
				JumpPowerController.Cancel(character, tempData)
			end
		end)
	end
end

function JumpPowerController.Cancel(character: Model, tempData: {[any]: any})
	local change = tempData.JumpPowerChange

	local humanoid = character.humanoid
	humanoid.JumpPower = change[3]

	tempData.JumpPowerChange = nil
end

return JumpPowerController