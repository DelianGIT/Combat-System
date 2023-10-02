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
	Start = function(player: Player | {}, _, tempData: {})
		BlockController.EnableBlock(player, tempData)
	end,

	End = function(player: Player | {}, _, tempData: {})
		BlockController.DisableBlock(player, tempData)
	end,
}

return {
	Data = data,
	Functions = functions,
}
