--// SERVICES
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// MODULES
local SharedModules = ReplicatedStorage.Modules
local Hitbox = require(SharedModules.Hitbox)

local ServerModules = ServerStorage.Modules
local ClientHitbox = require(ServerModules.ClientHitbox)
local DamageLibrary = require(ServerModules.DamageLibrary)
local VfxController = require(ServerModules.VfxController)
local KnockbackManager = DamageLibrary.KnockbackManager

--// CONFIG
local COMBO_FRAME = 3
local HITBOX_SIZE = Vector3.new(5, 5, 5)

--// FUNCTIONS
local function punchDamage(player: Player | {}, character: Model, tempData: {}, hit: Model, lookVector: Vector3)
	DamageLibrary.Deal(player, character, tempData, hit, {
		Amount = 5,
		
		Interrupting = true,
		MutualKnockback = true,

		Knockback = {
			Priority = 1,
			Force = Vector3.one * 50000,
			Duration = 0.2,
			Length = 15,

			Vector = lookVector
		},

		Stun = {
			Priority = 1,
			Duration = 0.8,
			WalkSpeed = 0,
			JumpPower = 0
		},

		Block = {
			Blockable = true,
			PerfectBlockable = true,
			BlockBreakable = false,

			PerfectBlockFrame = 0.5
		},

		HitFunction = function()
			VfxController.Start("Main", "PunchHit", 3, 100, hit)
		end
	})
end

local function lastPunchDamage(player: Player | {}, character: Model, tempData: {}, hit: Model, lookVector: Vector3, rootCFrame: CFrame)
	local isHitted
	DamageLibrary.Deal(player, character, tempData, hit, {
		Amount = 5,

		Interrupting = true,

		Knockback = {
			Priority = 1,
			Force = Vector3.one * 100000,
			Duration = 0.15,
			Length = 50,

			Vector = lookVector + rootCFrame.UpVector * 0.5
		},

		Stun = {
			Priority = 1,
			Duration = 0.8,
			WalkSpeed = 0,
			JumpPower = 0
		},

		Block = {
			Blockable = true,
			PerfectBlockable = true,
			BlockBreakable = false,

			PerfectBlockFrame = 0.5
		},

		HitFunction = function()
			isHitted = true
			VfxController.Start("Main", "PunchHit", 3, 100, hit)
		end
	})

	if isHitted then
		KnockbackManager.Apply(character, tempData, {
			Priority = 1,
			Force = Vector3.new(1, 0, 1) * 100000,
			Duration = 0.2,
			Length = 15,

			Vector = lookVector
		})
	end
end

--// SKILL FUNCTIONS
return {
	Start = function(args: {})
		local character = args.Character
		local rootCFrame = character.HumanoidRootPart.CFrame
		local lookVector = rootCFrame.LookVector
		local hitboxPosition = rootCFrame + lookVector * 3

		local skillData = args.SkillData
		local punchFunc
		if os.clock() - skillData.PunchTime > COMBO_FRAME then
			punchFunc = punchDamage
			skillData.Combo = 2
		elseif skillData.Combo == 5 then
			punchFunc = lastPunchDamage
			skillData.Combo = 1
		else
			punchFunc = punchDamage
			skillData.Combo += 1
		end
		skillData.PunchTime = os.clock()

		local tempData = args.TempData
		if not tempData.IsNpc then
			args.Event:Wait("", function(lookVector2: Vector3, hits: {})
				lookVector2 = lookVector2.Unit
				hitboxPosition = hitboxPosition.Position
	
				local player = args.Player
				for _, hit in hits do
					if ClientHitbox.Validate(player, hit, hitboxPosition) then
						punchFunc(player, character, tempData, hit, lookVector2, rootCFrame)
					end
				end
			end)
		else
			Hitbox.SpatialQuery({ character }, hitboxPosition, HITBOX_SIZE, false, function(hit: Model)
				punchFunc(args.Player, character, tempData, hit, lookVector, rootCFrame)
			end)
		end
	end
}