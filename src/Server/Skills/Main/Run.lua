--// SERVICES
local ServerStorage = game:GetService("ServerStorage")

--// MODULES
local ServerModules = ServerStorage.Modules
local WalkSpeedManager = require(ServerModules.DamageLibrary).WalkSpeedManager

--// CONFIG
local WALK_SPEED = 18

--// SKILL FUNCTIONS
local functions = {
	Start = function(args: {})
		local skillData = args.SkillData
		local enabled = skillData.Enabled

		if enabled then
			WalkSpeedManager.Cancel(args.Character, args.TempData)
		else
			local character = args.Character
			WalkSpeedManager.Change(character, args.TempData, {
				Priority = 0,
				Value = WALK_SPEED,
			})
		end

		skillData.Enabled = not enabled
	end,

	Interrupt = function(args: {})
		WalkSpeedManager.Cancel(args.Character, args.TempData)
		args.SkillData.Enabled = false
	end
}

return functions
