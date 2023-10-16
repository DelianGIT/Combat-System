--// SERVICES
local ServerStorage = game:GetService("ServerStorage")

--// MODULES
local ServerModules = ServerStorage.Modules
local HitboxMaker = require(ServerModules.HitboxMaker)
local Damager = require(ServerModules.Damager)
local KnockbackController = require(ServerModules.KnockbackController)
local VfxController = require(ServerModules.VfxController)

--// CONFIG
local PUNCH_FRAME = 1
local HITBOX_SIZE = Vector3.new(5, 5, 5)
local KNOCKBACK_FORCE = 10
local LAST_KNOCKBACK_FORCE = 50

--// FUNCTIONS
local function punch(player: Player | {}, character: Model, tempData: {}, skillData: {})
	local humanoidRootPart = character.HumanoidRootPart
	local rootCFrame = humanoidRootPart.CFrame

	local cframe = rootCFrame + rootCFrame.LookVector * 3

	local isHitted
	local knockbackDirection = rootCFrame.LookVector * KNOCKBACK_FORCE
	HitboxMaker.SpatialQuery({ character }, cframe, HITBOX_SIZE, false, function(hit: Model)
		local result = Damager.Deal(player, character, tempData, hit, skillData.DamageConfig)
		if result == "Hit" then
			isHitted = true
			KnockbackController.Apply(hit, 0.15, knockbackDirection)
			VfxController.Start("Main", "PunchHit", hit)
		end
	end)

	if isHitted then
		KnockbackController.Apply(character, 0.15, rootCFrame.LookVector * KNOCKBACK_FORCE)
	end

	return isHitted
end

local function lastPunch(player: Player | {}, character: Model, tempData: {}, skillData: {})
	local humanoidRootPart = character.HumanoidRootPart
	local rootCFrame = humanoidRootPart.CFrame

	local cframe = rootCFrame + rootCFrame.LookVector * 3

	local isHitted
	local knockbackDirection = rootCFrame.LookVector * LAST_KNOCKBACK_FORCE
	HitboxMaker.SpatialQuery({ character }, cframe, HITBOX_SIZE, false, function(hit: Model)
		local result = Damager.Deal(player, character, tempData, hit, skillData.DamageConfig)
		if result == "Hit" then
			isHitted = true
			KnockbackController.Apply(hit, 0.15, knockbackDirection)
			VfxController.Start("Main", "PunchHit", hit)
		end
	end)

	if isHitted then
		KnockbackController.Apply(character, 0.15, rootCFrame.LookVector * KNOCKBACK_FORCE)
	end
end

--// SKILL
local damageConfig = Damager.MakeConfig()
damageConfig.Amount = 5

local data = {
	DamageConfig = damageConfig,
	Combo = 1,
	PunchTime = math.huge
}

local functions = {
	Start = function(player: Player | {}, character: Model, tempData: {}, skillData: {}, _, _, _: boolean)
		if tick() - skillData.PunchTime > PUNCH_FRAME then
			skillData.Combo = 1
			punch(player, character, tempData, skillData)
		elseif skillData.Combo == 5 then
			skillData.Combo = 1
			lastPunch(player, character, tempData, skillData)
		else
			local isHitted = punch(player, character, tempData, skillData)
			if isHitted then
				skillData.Combo += 1
			end
		end
		skillData.PunchTime = tick()
	end
}

return {
	Data = data,
	Functions = functions
}