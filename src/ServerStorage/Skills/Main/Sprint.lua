--// SERVICES
local ServerStorage = game:GetService("ServerStorage")

--// MODULES
local ServerModules = ServerStorage.Modules
local WalkSpeedManager = require(ServerModules.DamageHandler).WalkSpeedManager

--// SKILL FUNCTIONS
return {
	Start = function(_, character: Model, tempData: {})
		WalkSpeedManager.Change(character, tempData, {
			Priority = 1,
			Value = character.Humanoid.WalkSpeed * 1.5
		})
	end,

	End = function(_, character: Model, tempData: {})
		WalkSpeedManager.Cancel(character, tempData)
	end
}