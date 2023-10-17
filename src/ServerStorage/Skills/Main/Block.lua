--// SERVICES
local ServerStorage = game:GetService("ServerStorage")

--// MODULES
local ServerModules = ServerStorage.Modules
local BlockManager = require(ServerModules.DamageHandler).BlockManager

--// SKILL
return {
	Start = function(player: Player | {}, _, tempData: {})
		BlockManager.EnableBlock(player, tempData)
	end,

	End = function(player: Player | {}, _, tempData: {})
		BlockManager.DisableBlock(player, tempData)
	end,
}
