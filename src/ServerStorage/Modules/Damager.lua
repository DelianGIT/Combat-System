--// SERVICES
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// MODULES
local ServerModules = ServerStorage.Modules
local TempData = require(ServerModules.TempData)
local NpcTempData = require(ServerModules.NpcMaker.TempData)
local BlockController = require(ServerModules.BlockController)

--// PACKAGES
local Packages = ReplicatedStorage.Packages
local Red = require(Packages.Red)

--// TYPES
type DamageResult = "Hit" | "Block" | "PerfectBlock" | "BlockBreak"
type DamageConfig = {
	Amount: number,
	Blockable: boolean,
	PerfectBlockable: boolean,
	BlockBreakable: boolean,
	CustomBlock: boolean,
	CustomPerfectBlock: boolean,
	CustomBlockBreak: boolean
}

--// VARIABLES
local playersFolder = workspace.Living.Players

local remoteEvent = Red.Server("DamageIndicator")

local Damager = {}

--// MODULE FUNCTIONS
function Damager.MakeConfig(): DamageConfig
	return {
		Blockable = true,
		PerfectBlockable = true,
		BlockBreakable = false,
	}
end

function Damager.Deal(
	aPlayer: Player,
	aCharacter: Model,
	aTempData: {},
	tCharacter: Model,
	config: DamageConfig
): DamageResult
	local amount = config.Amount

	local tHumanoid = tCharacter.Humanoid
	if tHumanoid.Health <= 0 then return end

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
		counterSkill(aPlayer, aCharacter, aTempData, amount)
		return
	end

	local blocking = tTempData.Blocking
	if blocking then
		if config.PerfectBlockable and BlockController.IsPerfectBlocked(tTempData, blocking) then
			BlockController.PerfectBlock(tPlayer, tTempData, tCharacter, aCharacter, aTempData, config.CustomPerfectBlock)
			return "PerfectBlock"
		elseif config.BlockBreakable or BlockController.IsBrokeBlock(tTempData, blocking, amount) then
			BlockController.BreakBlock(tPlayer, tCharacter, tTempData, config.CustomBlockBreak)
			return "BlockBreak"
		elseif config.Blockable then
			BlockController.HitBlock(tPlayer, tTempData, amount, tCharacter)
			return "Block"
		end
	end

	tHumanoid:TakeDamage(amount)
	if not aTempData.IsNpc then
		remoteEvent:Fire(aPlayer, "Hit", aPlayer, tCharacter, amount)
	end
	return "Hit"
end

return Damager
