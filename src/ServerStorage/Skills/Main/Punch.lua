--// SERVICES
-- local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

--// MODULES
local ServerModules = ServerStorage.Modules
local HitboxMaker = require(ServerModules.HitboxMaker)
local DamageHandler = require(ServerModules.DamageHandler)
local KnockbackManager = DamageHandler.KnockbackManager
local VfxController = require(ServerModules.VfxController)
-- local AnimationManager = require(ServerModules.AnimationManager)

--// CONFIG
local COMBO_FRAME = 2
local HITBOX_SIZE = Vector3.new(5, 5, 5)

--// VARIABLES
-- local animations = ReplicatedStorage.Animations
-- local punchAnimations = animations.Main.Punch

--// FUNCTIONS
local function punch(player: Player | {}, character: Model, tempData: {}, _: number)
	local humanoidRootPart = character.HumanoidRootPart
	local rootCFrame = humanoidRootPart.CFrame
	local lookVector = rootCFrame.LookVector
	local cframe = rootCFrame + lookVector * 3

	-- local animation = punchAnimations[count]
	-- AnimationManager.Play(character, animation)

	HitboxMaker.SpatialQuery({ character }, cframe, HITBOX_SIZE, false, function(hit: Model)
		DamageHandler.Deal(player, character, tempData, hit, {
			Amount = 5,
			
			MutualKnockback = true,
			Interruptable = true,

			Knockback = {
				FromPoint = false,
				Duration = 0.2,
				Priority = 1,
				Force = Vector3.one * 100000,
				Length = 15,
				Vector = lookVector
			},

			Block = {
				Blockable = true,
				BlockBreakable = false,
				PerfectBlockable = true,
				PerfectBlockFrame = 0.5
			},

			Stun = {
				Duration = 0.8,
				JumpPower = 0,
				WalkSpeed = 0,
				Priority = 1
			},

			HitFunction = function()
				VfxController.Start(100, 3, "Main", "PunchHit", hit)
			end
		})
	end)
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
			
			Interruptable = true,

			Knockback = {
				FromPoint = false,
				Force = Vector3.one * 10000000,
				Length = 100,
				Duration = 0.15,
				Priority = 1,
				Vector = lookVector + rootCFrame.UpVector * 0.7
			},

			Block = {
				Blockable = true,
				BlockBreakable = false,
				PerfectBlockable = true,
				PerfectBlockFrame = 0.5
			},

			Stun = {
				Duration = 0.5,
				JumpPower = 0,
				WalkSpeed = 0,
				Priority = 1
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
			Duration = 0.2,
			Priority = 1,
			Force = Vector3.new(1, 0, 1) * 100000,
			Length = 15,
			Vector = lookVector
		})
	end
end

--// SKILL FUNCTIONS
return {
	Start = function(player: Player | {}, character: Model, tempData: {}, skillData: {})
		if os.clock() - skillData.PunchTime > COMBO_FRAME then
			punch(player, character, tempData, 1)
			skillData.Combo = 2
		elseif skillData.Combo == 5 then
			lastPunch(player, character, tempData)
			skillData.Combo = 1
		else
			punch(player, character, tempData, skillData.Combo)
			skillData.Combo += 1
		end
		skillData.PunchTime = os.clock()
	end
}