--// SERVICES
local ServerStorage = game:GetService("ServerStorage")

--// MODULES
local ServerModules = ServerStorage.Modules
local WalkSpeedController = require(ServerModules.WalkSpeedController)

--// SKILL
local functions = {
	Start = function(_, character: Model, tempData: {})
		local currentWalkSpeed = character.Humanoid.WalkSpeed
		WalkSpeedController.Change(character, tempData, currentWalkSpeed * 1.5, 1)
	end,

	End = function(_, character: Model, tempData: {})
		WalkSpeedController.Cancel(character, tempData)
	end,
}

return {
	Data = {},
	Functions = functions,
}