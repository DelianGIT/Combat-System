--// SERVICES
local ServerStorage = game:GetService("ServerStorage")

--// MODULES
local ServerModules = ServerStorage.Modules
local HitboxMaker = require(ServerModules.HitboxMaker)
local Damager = require(ServerModules.Damager)

--// CONFIG
local PUNCH_FRAME = 1

--// VARIABLES
local data = {
	Name = "Punch",
	Cooldown = 0.5,
	InputKey = Enum.UserInputType.MouseButton1,
	InputState = "Begin",
	DamageConfig = Damager.CreateDamageConfig(5, false, true, {
		"Main", "PunchHit"
	}),
	Combo = 1,
	LastPunch = 0
}

--// FUNCTIONS
local functions = {
	Start = function(player: Player | {}, character: Model, tempData: {}, skillData: {}, _, _, isAirCombo: boolean)
		if tick() - skillData.LastPunch > PUNCH_FRAME or skillData.Combo > 5 then
			skillData.Combo = 1
		end

		local humanoidRootPart = character.HumanoidRootPart
		local rootCFrame = humanoidRootPart.CFrame

		local cframe = rootCFrame + rootCFrame.LookVector * 3
		local hits = HitboxMaker.SpatialQuery({ character }, cframe, Vector3.new(5, 5, 5))

		local isHitted
		local knockbackDirection = rootCFrame.LookVector * (if skillData.Combo == 5 then 50 else 10)
		for _, hittedCharacter in hits do
			local result = Damager.Deal(player, character, tempData, hittedCharacter, skillData.DamageConfig)
			if result == "Hit" then
				isHitted = true
				Damager.Knockback(hittedCharacter, knockbackDirection, 0.15)
			end
		end

		if isHitted then
			Damager.Knockback(character, rootCFrame.LookVector * 10, 0.15)
		end

		skillData.LastPunch = tick()
		skillData.Combo += 1
	end,
}

return {
	Data = data,
	Functions = functions,
}
