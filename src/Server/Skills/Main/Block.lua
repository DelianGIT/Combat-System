--// SERVICES
local ServerStorage = game:GetService("ServerStorage")

--// MODULES
local ServerModules = ServerStorage.Modules
local BlockManager = require(ServerModules.DamageLibrary).BlockManager

--// SKILL
return {
	Start = function(args: {})
		BlockManager.EnableBlock(args.Player, args.TempData)
	end,

	End = function(args: {})
		BlockManager.DisableBlock(args.Player, args.TempData)
	end,
}
