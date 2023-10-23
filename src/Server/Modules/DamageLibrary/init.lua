--// SERVICES
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// MODULES
local ServerModules = ServerStorage.Modules
local TempData = require(ServerModules.TempData)
local NpcTempData = require(ServerModules.NpcMaker.TempData)

local StunManager = require(script.StunManager)
local BlockManager = require(script.BlockManager)
local KnockbackManager = require(script.KnockbackManager)

--// TYPES
type DamageResult = "Hit" | "CounterSkill" | "BlockHit" | "BlockBreak" | "PerfectBlock"
type Config = {
	Amount: number,

	Interrupting: boolean,
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

local DamageLibrary = {}

--// MODULE FUNCTIONS
function DamageLibrary.MakeConfig(): Config
	return {}
end

function DamageLibrary.Deal(aPlayer: Model, aCharacter: Model, aTempData: {}, tCharacter: Model, config: Config)
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
		counterSkill(aPlayer, aCharacter, aTempData, config.Amount)
		return "CounterSkill"
	end

	local block = tTempData.Block
	if block then
		return BlockManager.ProcessBlock(aCharacter, aTempData, tPlayer, tCharacter, tTempData, config.Amount, config.Block)
	end

	local damageAmount = config.Amount
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

	if config.Interrupting then
		local skillPacks = tTempData.SkillPacks
		for identifier, _ in tTempData.ActiveSkills do
			local splittedString = string.split(identifier, "_")
			local pack = skillPacks[splittedString[1]]
			task.spawn(function()
				pack:InterruptSkill(splittedString[2])
			end)
		end
	end

	local hitFunction = config.HitFunction
	if hitFunction then
		hitFunction()
	end

	if not aTempData.IsNpc then
		remoteEvent:Fire(aPlayer, tCharacter, damageAmount)
	end

	return "Hit"
end

DamageLibrary.StunManager = StunManager
DamageLibrary.BlockManager = BlockManager
DamageLibrary.KnockbackManager = KnockbackManager
DamageLibrary.WalkSpeedManager = require(script.WalkSpeedManager)
DamageLibrary.JumpPowerManager = require(script.JumpPowerManager)

return DamageLibrary