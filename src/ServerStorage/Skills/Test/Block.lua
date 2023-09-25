--// SERVICES
local ServerStorage = game:GetService("ServerStorage")

--// MODULES
local ServerModules = ServerStorage.Modules
local BlockController = require(ServerModules.BlockController)

--// VARIABLES
local data = {
	Name = "Block",
	Cooldown = 1,
	InputKey = Enum.KeyCode.F,
	InputState = "Begin",
}

--// FUNCTIONS
local functions = {
	Start = function(_, _, tempData)
		BlockController.EnableBlock(tempData)
	end,

	End = function(_, _, tempData)
		BlockController.DisableBlock(tempData)
	end
}

return {
	Data = data,
	Functions = functions,
}
