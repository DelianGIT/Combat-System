--// SERVICES
local ServerStorage = game:GetService("ServerStorage")

--// MODULES
local ServerModules = ServerStorage.Modules
local HitboxMaker = require(ServerModules.HitboxMaker)
local Damager = require(ServerModules.Damager)

--// CONFIG
local PUNCH_FRAME = 1

--// VARIABLES
local hitboxSize = Vector3.new(5, 5, 5)

--// FUNCTIONS
local function punch(player: Player | {}, character: Model, tempData: {}, skillData: {})
	local humanoidRootPart = character.HumanoidRootPart
	local rootCFrame = humanoidRootPart.CFrame

	local cframe = rootCFrame + rootCFrame.LookVector * 3

	local isHitted
	local knockbackDirection = rootCFrame.LookVector * 10
	HitboxMaker.SpatialQuery({ character }, cframe, hitboxSize, false, function(hit: Model)
		local result = Damager.Deal(player, character, tempData, hit, skillData.DamageConfig)
		if result == "Hit" then
			isHitted = true
			Damager.Knockback(hit, knockbackDirection, 0.15)
		end
	end)

	if isHitted then
		Damager.Knockback(character, rootCFrame.LookVector * 10, 0.15)
	end
end

local function lastPunch(player: Player | {}, character: Model, tempData: {}, skillData: {})
	local humanoidRootPart = character.HumanoidRootPart
	local rootCFrame = humanoidRootPart.CFrame

	local cframe = rootCFrame + rootCFrame.LookVector * 3

	local isHitted
	local knockbackDirection = rootCFrame.LookVector * 50
	HitboxMaker.SpatialQuery({ character }, cframe, hitboxSize, false, function(hit: Model)
		local result = Damager.Deal(player, character, tempData, hit, skillData.DamageConfig)
		if result == "Hit" then
			isHitted = true
			Damager.Knockback(hit, knockbackDirection, 0.15)
		end
	end)

	if isHitted then
		Damager.Knockback(character, rootCFrame.LookVector * 10, 0.15)
	end
end

--// SKILL
local data = {
	DamageConfig = Damager.CreateDamageConfig(5, false, true, {
		"Main", "PunchHit"
	}),
	Combo = 0,
	LastPunch = 0
}

local functions = {
	Start = function(player: Player | {}, character: Model, tempData: {}, skillData: {}, _, _, _: boolean)
		if tick() - skillData.LastPunch > PUNCH_FRAME then
			punch(player, character, tempData, skillData)
			skillData.Combo = 2
		elseif skillData.Combo == 5 then
			lastPunch(player, character, tempData, skillData)
			skillData.Combo = 1
		else
			punch(player, character, tempData, skillData)
			skillData.Combo += 1
		end
		skillData.LastPunch = tick()
	end,
}

return {
	Data = data,
	Functions = functions,
}
