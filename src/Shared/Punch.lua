--// SERVICES
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// MODULES
local SharedModules = ReplicatedStorage.Modules
local Hitbox = require(SharedModules.Hitbox)

local ServerModules = ServerStorage.Modules
local ClientHitbox = require(ServerModules.ClientHitbox)
local DamageLibrary = require(ServerModules.DamageLibrary)
local WalkSpeedManager = DamageLibrary.WalkSpeedManager
local JumpPowerManager = DamageLibrary.JumpPowerManager
local VfxController = require(ServerModules.VfxController)
local BodyMover = require(ServerModules.BodyMover)

--// CONFIG
local SLOWDOWN_DURATION = 0.75
local COMBO_FRAME = 3
local AIR_COMBO_START = 4
local HITBOX_SIZE = Vector3.new(5, 5, 5)

--// FUNCTIONS
local function raisePlayer(character:Model, position: Vector3)
	local alignPosition = BodyMover.AlignPosition(character)
	if alignPosition then
		alignPosition.Position = position
		alignPosition.ApplyAtCenterOfMass = true
		alignPosition.MaxForce = 3e5
		alignPosition.MaxVelocity = math.huge
		alignPosition.Responsiveness = 35

		task.delay(3, function()
			alignPosition:Destroy()
		end)
	end
end

local function punchDamage(player: Player | {}, character: Model, tempData: {}, hit: Model, lookVector: Vector3)
	return DamageLibrary.Deal(player, character, tempData, hit, {
		Amount = 5,

		Interrupting = true,
		Blockable = true,

		Knockback = {
			Priority = 1,
			Force = Vector3.one * 3e4,
			Duration = 0.15,
			Length = 10,

			Vector = lookVector,
		},

		Stun = {
			Priority = 1,
			Duration = 0.8,
			WalkSpeed = 0,
			JumpPower = 0,
		},

		Block = {
			BlockHitable = true,
			PerfectBlockable = true,
			BlockBreakable = false,

			PerfectBlockFrame = 0.5,
		},

		HitFunction = function()
			VfxController.Start(100, hit, {
				Pack = "Main",
				Vfx = "PunchHit",
				AdditionalData = character,
			})
		end,
	})
end

local function lastPunchDamage(
	player: Player | {},
	character: Model,
	tempData: {},
	hit: Model,
	lookVector: Vector3,
	rootCFrame: CFrame
)
	DamageLibrary.Deal(player, character, tempData, hit, {
		Amount = 15,

		Interrupting = true,
		Blockable = true,

		Knockback = {
			Priority = 1,
			Force = Vector3.one * 1e5,
			Duration = 0.1,
			Length = 75,

			Vector = lookVector + rootCFrame.UpVector * 0.5,
		},

		Stun = {
			Priority = 1,
			Duration = 0.8,
			WalkSpeed = 0,
			JumpPower = 0,
		},

		Block = {
			BlockHitable = true,
			PerfectBlockable = true,
			BlockBreakable = false,

			PerfectBlockFrame = 0.5,
		},

		HitFunction = function()
			VfxController.Start(100, hit, {
				Pack = "Main",
				Vfx = "PunchHit",
				AdditionalData = character,
			})
		end,
	})
end

--// SKILL FUNCTIONS
return {
	Start = function(args: {}, isSpaceDown: boolean)
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
		WalkSpeedManager.Change(character, tempData, {
			Value = 6,
			Duration = SLOWDOWN_DURATION,
			Priority = 1
		})

		local isAirCombo = skillData.Combo == AIR_COMBO_START and isSpaceDown and not skillData.AirCombo

		if not tempData.IsNpc then
			args.Event:Wait("", function(lookVector2: Vector3, hits: {})
				lookVector2 = lookVector2.Unit
				hitboxPosition = hitboxPosition.Position

				local isHitted
				local player = args.Player
				for _, hit in hits do
					if not ClientHitbox.Validate(player, hit, hitboxPosition) then
						return
					end

					local result = punchFunc(player, character, tempData, hit, lookVector2, rootCFrame)
					if result == "Hit" then
						isHitted = true

						if isAirCombo then
							isAirCombo = false
							skillData.AirCombo = true

							local hitPosition = hit.HumanoidRootPart.Position
							local position = rootCFrame.Position + Vector3.yAxis * 15
							raisePlayer(hit, Vector3.new(hitPosition.X, position.Y, hitPosition.Z))
							raisePlayer(character, position)
						end
					end
				end

				if isHitted then
					JumpPowerManager.Change(character, tempData, {
						Value = 0,
						Duration = 1,
						Priority = 1
					})
				end
			end)
		else
			Hitbox.SpatialQuery({ character }, hitboxPosition, HITBOX_SIZE, false, function(hit: Model)
				punchFunc(args.Player, character, tempData, hit, lookVector, rootCFrame)
			end)
		end
	end,
}
