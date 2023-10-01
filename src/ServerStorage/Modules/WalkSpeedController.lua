--VARIABLES
local WalkSpeedController = {}

--// MODULE FUNCTIONS
function WalkSpeedController.Change(character: Model, tempData: {},	value: number, priority: number, duration: number?)
	local existingChange = tempData.WalkSpeedChange
	if existingChange and existingChange[1] >= priority then
		return
	end

	local humanoid = character.Humanoid
	local startTime = tick()
	tempData.WalkSpeedChange = {
		priority,
		value,
		if existingChange then existingChange[3] else humanoid.WalkSpeed,
		startTime,
	}
	humanoid.WalkSpeed = value

	if not duration then return end
	task.delay(duration, function()
		local currentChange = tempData.WalkSpeedChange
		if currentChange and currentChange[4] == startTime then
			WalkSpeedController.Cancel(character, tempData)
		end
	end)
end

function WalkSpeedController.Cancel(character: Model, tempData: {})
	local change = tempData.WalkSpeedChange
	if change then
		local humanoid = character.Humanoid
		humanoid.WalkSpeed = change[3]

		tempData.WalkSpeedChange = nil
	end
end

return WalkSpeedController