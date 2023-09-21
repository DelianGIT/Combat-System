--// SERVICES
local ServerStorage = game:GetService("ServerStorage")

--// MODULES
local ServerModules = ServerStorage.Modules
local WalkSpeedController = require(ServerModules.WalkSpeedController)
local JumpPowerController = require(ServerModules.JumpPowerController)

--// VARIABLES
local StunController = {}

--// MODULE FUNCTIONS
function StunController.Apply(character: Model, tempData: {[any]: any}, duration: number)
	local existingStun = tempData.Stun
	if existingStun and existingStun[2] - (tick() - existingStun[1]) < duration then
		return
	end

	local startTime = tick()
	tempData.Stun = {duration, startTime}
	tempData.CanUseSkills = true

	WalkSpeedController.Change(character, tempData, 0, duration, 5)
	JumpPowerController.Change(character, tempData, 0, duration, 5)

	task.delay(duration, function()
		local currentStun = tempData.Stun
		if currentStun and currentStun[2] == startTime then
			StunController.Cancel()
		end
	end)
end

function StunController.Cancel(character: Model, tempData: {[any]: any})
	if tempData.Stun then
		tempData.CanUseSkills = nil
		WalkSpeedController.Cancel(character, tempData)
		JumpPowerController.Cancel(character, tempData)
	end
end

return StunController