--// SERVICES
local ServerStorage = game:GetService("ServerStorage")

--// MODULES
local ServerModules = ServerStorage.Modules
local BlockController = require(ServerModules.BlockController)

--// SKILL
local functions = {
	Start = function(player: Player | {}, _, tempData: {})
		BlockController.EnableBlock(player, tempData)
	end,

	End = function(player: Player | {}, _, tempData: {})
		BlockController.DisableBlock(player, tempData)
	end,
}

return {
	Data = {},
	Functions = functions,
}
