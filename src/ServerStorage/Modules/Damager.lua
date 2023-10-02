--// SERVICES
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// MODULES
local ServerModules = ServerStorage.Modules
local BodyMover = require(ServerModules.BodyMover)
local BlockController = require(ServerModules.BlockController)
local TempData = require(ServerModules.TempData)
local NpcTempData = require(ServerModules.NpcMaker.TempData)
local VfxController = require(ServerModules.VfxController)

--// PACKAGES
local Packages = ReplicatedStorage.Packages
local Red = require(Packages.Red)

--// TYPES
type Vfx = {
	PackName: string,
	VfxName: string,
}
type DamageConfig = {
	Amount: number,
	BlockBreaking: boolean,
	PerfectBlockable: boolean,
	CustomHitVfx: boolean,
	CustomBlockHitVfx: boolean,
	CustomPerfectBlockVfx: boolean,
	CustomBlockBreakVfx: boolean
}

--// VARIABLES
local playersFolder = workspace.Living.Players

local bodyVelocityMaxForce = Vector3.one * math.huge

local remoteEvent = Red.Server("DamageIndicator")

local Damager = {}

--// MODULE FUNCTIONS
function Damager.Knockback(character: Model, direction: Vector3, duration: number)
	local bodyVelocity = BodyMover.BodyVelocity(character)
	bodyVelocity.MaxForce = bodyVelocityMaxForce
	bodyVelocity.Velocity = direction

	task.delay(duration, function()
		bodyVelocity:Destroy()
	end)
end

function Damager.CreateDamageConfig(
	amount: number,
	blockBreaking: boolean,
	perfectBlockable: boolean,
	customHitVfx: boolean,
	customBlockHitVfx: boolean,
	customPerfectBlockVfx: boolean,
	customBlockBreakVfx: boolean
): DamageConfig
	return {
		Amount = amount,
		BlockBreaking = blockBreaking,
		PerfectBlockable = perfectBlockable,
		CustomHitVfx = customHitVfx,
		CustomBlockHitVfx = customBlockHitVfx,
		CustomPerfectBlockVfx = customPerfectBlockVfx,
		CustomBlockBreakVfx = customBlockBreakVfx
	}
end

function Damager.Deal(
	attackerPlayer: Player,
	attackerCharacter: Model,
	attackerTempData: {},
	targetCharacter: Model,
	damageConfig: DamageConfig
)
	local parent = targetCharacter.Parent
	local targetPlayer, targetTempData
	if parent == playersFolder then
		targetPlayer = Players:GetPlayerFromCharacter(targetCharacter)
		targetTempData = TempData.Get(targetPlayer)
	else
		targetTempData = NpcTempData.Get(targetCharacter)
	end

	local counterSkill = targetTempData.CounterSkill
	if counterSkill then
		targetTempData.CounterSkill = nil
		counterSkill(attackerPlayer, attackerCharacter, attackerTempData, damageConfig)
	elseif targetTempData.IsBlocking then
		return BlockController.ProcessBlock(attackerCharacter, attackerTempData, targetPlayer, targetCharacter, targetTempData, damageConfig)
	else
		local targetHumanoid = targetCharacter.Humanoid
		targetHumanoid:TakeDamage(damageConfig.Amount)

		local customVfx = damageConfig.CustomHitVfx
		if customVfx then
			VfxController.Start(customVfx[1], customVfx[2], targetCharacter)
		end

		if typeof(attackerPlayer) == "Instance" then
			remoteEvent:Fire(attackerPlayer, "Hit", attackerPlayer, targetCharacter, damageConfig.Amount)
		end

		return "Hit"
	end
end

return Damager
