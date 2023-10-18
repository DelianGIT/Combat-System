--// SERVICES
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// MODULES
local ServerModules = ServerStorage.Modules
local TempData = require(ServerModules.TempData)
local NpcTempData = require(ServerModules.NpcMaker.TempData)

local StunManager = require(script.StunManager)
local BlockManager = require(script.BlockManager)
local KnockbackManager = require(script.KnockbackManager)

--// TYPES
type Config = {
	Amount: number,

	Interruptable: boolean,
	MutualKnockback: boolean,

	Knockback: KnockbackManager.Config,
	Stun: StunManager.Config,
	Block: BlockManager.Config,

	HitFunction: () -> ()
}

--// VARIABLES
local playersFolder = workspace.Living.Players

local remoteEvents = ReplicatedStorage.Events
local remoteEvent = require(remoteEvents.DamageIndicator):Server()

local DamageHandler = {}

--// MODULE FUNCTIONS
function DamageHandler.MakeConfig(): Config
	return {}
end

function DamageHandler.Deal(aPlayer: Model, aCharacter: Model, aTempData: {}, tCharacter: Model, config: Config)
	local damageAmount = config.Amount

	local tHumanoid = tCharacter.Humanoid
	if tHumanoid.Health <= 0 then
		return
	end

	local tPlayer, tTempData
	if tCharacter.Parent == playersFolder then
		tPlayer = Players:GetPlayerFromCharacter(tCharacter)
		tTempData = TempData.Get(tPlayer)
	else
		tTempData = NpcTempData.Get(tCharacter)
	end

	local counterSkill = tTempData.CounterSkill
	if counterSkill then
		tTempData.CounterSkill = nil
		counterSkill(aPlayer, aCharacter, aTempData, damageAmount)
		return
	end

	local block = tTempData.Block
	if block then
		BlockManager.ProcessBlock(aCharacter, aTempData, tPlayer, tCharacter, tTempData, damageAmount, config.Block)
		return
	end

	tHumanoid:TakeDamage(damageAmount)

	local knockback = config.Knockback
	if knockback then
		KnockbackManager.Apply(tCharacter, tTempData, knockback)
		if config.MutualKnockback then
			KnockbackManager.Apply(aCharacter, aTempData, knockback)
		end
	end

	local stun = config.Stun
	if stun then
		StunManager.Apply(tCharacter, tTempData, stun)
	end

	if config.Interruptable then
		local skillPacks = tTempData.SkillPacks
		for identifier, _ in tTempData.ActiveSkills do
			local packName, skillName = table.unpack(string.split(identifier, "_"))
			local pack = skillPacks[packName]
			pack:InterruptSkill(skillName)
		end
	end

	local hitFunction = config.HitFunction
	if hitFunction then
		hitFunction()
	end

	if not aTempData.IsNpc then
		remoteEvent:Fire(aPlayer, aPlayer, tCharacter, damageAmount)
	end

	return "Hit"
end

DamageHandler.StunManager = StunManager
DamageHandler.BlockManager = BlockManager
DamageHandler.KnockbackManager = KnockbackManager
DamageHandler.WalkSpeedManager = require(script.WalkSpeedManager)
DamageHandler.JumpPowerManager = require(script.JumpPowerManager)

return DamageHandler
