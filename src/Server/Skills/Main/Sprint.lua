--// SERVICES
local ServerStorage = game:GetService("ServerStorage")

--// MODULES
local ServerModules = ServerStorage.Modules
local WalkSpeedManager = require(ServerModules.DamageLibrary).WalkSpeedManager

--// SKILL FUNCTIONS
local functions = {
	Start = function(args: {})
		local character = args.Character
		WalkSpeedManager.Change(character, args.TempData, {
			Priority = 0,
			Value = character.Humanoid.WalkSpeed * 1.5
		})
	end,

	End = function(args: {})
		WalkSpeedManager.Cancel(args.Character, args.TempData)
	end
}
functions.Interrupt = functions.End

return functions