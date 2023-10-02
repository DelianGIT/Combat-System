--// SERVICES
local ServerStorage = game:GetService("ServerStorage")

--// MODULES
local ServerModules = ServerStorage.Modules
local WalkSpeedController = require(ServerModules.WalkSpeedController)

--// VARIABLES
local data = {
	Name = "Sprint",
	Cooldown = 0,
	InputKey = Enum.KeyCode.W,
	InputState = "DoubleClick",
	ClickFrame = 0.5
}

--// FUNCTIONS
local functions = {
	Start = function(_, character: Model, tempData: {})
		local currentWalkSpeed = character.Humanoid.WalkSpeed
		WalkSpeedController.Change(character, tempData, currentWalkSpeed * 1.25, 1)
	end,

	End = function(_, character: Model, tempData: {})
		WalkSpeedController.Cancel(character, tempData)
	end,
}

return {
	Data = data,
	Functions = functions,
}
