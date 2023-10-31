--// SERVICES
local ServerStorage = game:GetService("ServerStorage")

--// MODULES
local ServerModules = ServerStorage.Modules
local WalkSpeedManager = require(ServerModules.DamageLibrary).WalkSpeedManager

--// CONFIG
local WALK_SPEED = 24

--// SKILL FUNCTIONS
local functions = {
	Start = function(args: {})
		local character = args.Character
		WalkSpeedManager.Change(character, args.TempData, {
			Priority = 0,
			Value = WALK_SPEED,
		})
	end,

	End = function(args: {})
		WalkSpeedManager.Cancel(args.Character, args.TempData)
	end,
}
functions.Interrupt = functions.End

return functions
