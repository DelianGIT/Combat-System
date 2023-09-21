--VARIABLES
local WalkSpeedController = {}

--// MODULE FUNCTIONS
function WalkSpeedController.Change(character: Model, tempData: {[any]: any}, value: number, duration: number?, priority: number)
	local existingChange = tempData.WalkSpeedChange
	if existingChange or existingChange[1] >= priority then
		return
	end

	local humanoid = character.humanoid
	local startTime = tick()
	tempData.WalkSpeedChange = {
		priority,
		value,
		if existingChange then existingChange[3] else humanoid.WalkSpeed,
		startTime
	}
	humanoid.WalkSpeed = value

	if duration then
		task.delay(duration, function()
			local currentChange = tempData.WalkSpeedChange
			if currentChange and currentChange[4] == startTime then
				WalkSpeedController.Cancel(character, tempData)
			end
		end)
	end
end

function WalkSpeedController.Cancel(character: Model, tempData: {[any]: any})
	local change = tempData.WalkSpeedChange

	local humanoid = character.humanoid
	humanoid.WalkSpeed = change[3]

	tempData.WalkSpeedChange = nil
end

return WalkSpeedController