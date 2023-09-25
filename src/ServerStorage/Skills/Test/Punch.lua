--// SERVICES
local ServerStorage = game:GetService("ServerStorage")

--// MODULES
local ServerModules = ServerStorage.Modules
local HitboxMaker = require(ServerModules.HitboxMaker)
local Damager = require(ServerModules.Damager)

--// VARIABLES
local data = {
	Name = "Punch",
	Cooldown = 0.5,
	InputKey = Enum.UserInputType.MouseButton1,
	InputState = "Begin",
	Damage = 5
}

--// FUNCTIONS
local functions = {
	Start = function(player, character, tempData, skillData)
		local humanoidRootPart = character.HumanoidRootPart
		local characterCFrame = humanoidRootPart.CFrame

		local cframe = characterCFrame + characterCFrame.LookVector * 3
		local hits = HitboxMaker.SpatialQuery({character}, cframe, Vector3.new(5, 5, 5))

		for _, hittedCharacter in hits do
			Damager.Deal(player, character, hittedCharacter, tempData, skillData.Damage)
		end
	end
}

return {
	Data = data,
	Functions = functions,
}
