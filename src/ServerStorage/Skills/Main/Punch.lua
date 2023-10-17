--// SERVICES
local ServerStorage = game:GetService("ServerStorage")

--// MODULES
local ServerModules = ServerStorage.Modules
local HitboxMaker = require(ServerModules.HitboxMaker)
local DamageHandler = require(ServerModules.DamageHandler)
local KnockbackManager = DamageHandler.KnockbackManager
local VfxController = require(ServerModules.VfxController)

--// CONFIG
local COMBO_FRAME = 1
local HITBOX_SIZE = Vector3.new(5, 5, 5)
local KNOCKBACK_FORCE = Vector3.one * 1e5

--// FUNCTIONS
local function punch(player: Player | {}, character: Model, tempData: {})
	local humanoidRootPart = character.HumanoidRootPart
	local rootCFrame = humanoidRootPart.CFrame
	local lookVector = rootCFrame.LookVector
	local cframe = rootCFrame + lookVector * 3

	local isHitted
	HitboxMaker.SpatialQuery({ character }, cframe, HITBOX_SIZE, false, function(hit: Model)
		DamageHandler.Deal(player, character, tempData, hit, {
			Amount = 5,
			MutualKnockback = true,

			Knockback = {
				FromPoint = false,
				Force = KNOCKBACK_FORCE,
				Length = 10,
				Duration = 0.15,
				Priority = 1,
				Vector = lookVector
			},

			Block = {
				Blockable = true,
				BlockBreakable = false,
				PerfectBlockable = true,
				PerfectBlockFrame = 0.5
			},

			Stun = {
				BlockSkills = true,
				Duration = 0.5,
				JumpPower = 0,
				WalkSpeed = 0,
				Priority = 1,
			},

			HitFunction = function()
				isHitted = true
				VfxController.Start(100, 3, "Main", "PunchHit", hit)
			end
		})
	end)

	return isHitted
end

local function lastPunch(player: Player | {}, character: Model, tempData: {})
	local humanoidRootPart = character.HumanoidRootPart
	local rootCFrame = humanoidRootPart.CFrame
	local lookVector = rootCFrame.LookVector
	local cframe = rootCFrame + lookVector * 3

	local isHitted
	HitboxMaker.SpatialQuery({ character }, cframe, HITBOX_SIZE, false, function(hit: Model)
		DamageHandler.Deal(player, character, tempData, hit, {
			Amount = 15,

			Knockback = {
				FromPoint = false,
				Force = KNOCKBACK_FORCE,
				Length = 50,
				Duration = 0.15,
				Priority = 1,
				Vector = lookVector
			},

			Block = {
				Blockable = true,
				BlockBreakable = false,
				PerfectBlockable = true,
				PerfectBlockFrame = 0.5
			},

			Stun = {
				BlockSkills = true,
				Duration = 0.5,
				JumpPower = 0,
				WalkSpeed = 0,
				Priority = 1,
			},

			HitFunction = function()
				isHitted = true
				VfxController.Start(100, 3, "Main", "PunchHit", hit)
			end
		})
	end)

	if isHitted then
		KnockbackManager.Apply(character, tempData, {
			FromPoint = false,
			Force = KNOCKBACK_FORCE,
			Length = 10,
			Duration = 0.15,
			Priority = 1,
			Vector = lookVector
		})
	end
end

--// SKILL FUNCTIONS
return {
	Start = function(player: Player | {}, character: Model, tempData: {}, skillData: {})
		if os.clock() - skillData.PunchTime > COMBO_FRAME then
			skillData.Combo = 1
			punch(player, character, tempData)
		elseif skillData.Combo == 5 then
			skillData.Combo = 1
			lastPunch(player, character, tempData)
		else
			local isHitted = punch(player, character, tempData)
			if isHitted then
				print(1)
				skillData.Combo += 1
			end
		end
		skillData.PunchTime = os.clock()
	end
}