--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

--// MODULES
local ServerModules = ServerStorage.Modules
local StunController = require(ServerModules.StunController)
local VfxController = require(ServerModules.VfxController)

--// PACKAGES
local Packages = ReplicatedStorage.Packages
local Red = require(Packages.Red)

--// CONFIG
local PERFECT_BLOCK_FRAME = 0.5

--// VARIABLES
local remoteEvent = Red.Server("BlockIndicator")

local BlockController = {}

--// MODULE FUNCTIONS
function BlockController.EnableBlock(player: Player?, tempData: {})
	local maxDurability = tempData.BlockMaxDurability
	tempData.BlockDurability = maxDurability
	tempData.BlockTime = tick()
	tempData.IsBlocking = true

	if typeof(player) == "Instance" then
		remoteEvent:Fire(player, "Enable", maxDurability)
	end
end

function BlockController.DisableBlock(player: Player?, tempData: {})
	tempData.IsBlocking = false

	if typeof(player) == "Instance" then
		remoteEvent:Fire(player, "Disable")
	end
end

function BlockController.IncreaseDurability(player: Player?, tempData: {}, value: number)
	tempData.BlockDurability += value

	if typeof(player) == "Instance" then
		remoteEvent:Fire(player, "ChangeDurability", value)
	end
end

function BlockController.DecreaseDurability(player: Player?, tempData: {}, value: number)
	if BlockController.IsBrokeBlock(tempData, value) then
		BlockController.BreakBlock()
	else
		tempData.BlockDurability -= value

		if typeof(player) == "Instance" then
			remoteEvent:Fire(player, "ChangeDurability", -value)
		end
	end
end

function BlockController.IsPerfectBlocked(tempData: {})
	if not tempData.IsBlocking then
		return false
	elseif tick() - tempData.BlockTime <= PERFECT_BLOCK_FRAME then
		return true
	end
end

function BlockController.IsBrokeBlock(tempData: {}, damageAmount: number)
	if not tempData.IsBlocking then
		return false
	elseif tempData.BlockDurability - damageAmount <= 0 then
		return true
	end
end

function BlockController.PerfectBlock(
	blockerPlayer: Player?,
	blockerCharacter: Model,
	attackerCharacter: Model,
	attackerTempData: {},
	customVfx: boolean
)
	StunController.Apply(attackerCharacter, attackerTempData, 3)

	if typeof(blockerPlayer) == "Instance" then
		remoteEvent:Fire(blockerPlayer, "PerfectBlock")
	end

	if customVfx then
		VfxController.Start(customVfx[1], customVfx[2], blockerCharacter)
	else
		VfxController.Start("Main", "PerfectBlock", blockerCharacter)
	end
end

function BlockController.BreakBlock(player: Player?, character: Model, tempData: {}, customVfx: boolean)
	tempData.IsBlocking = false
	StunController.Apply(character, tempData, 3)

	if typeof(player) == "Instance" then
		remoteEvent:Fire(player, "BlockBreak")
	end

	if customVfx then
		VfxController.Start(customVfx[1], customVfx[2], character)
	else
		VfxController.Start("Main", "BlockBreak", character)
	end
end

function BlockController.HitBlock(player: Player?, character: Model, tempData: {}, damageAmount: number, customVfx: boolean)
	BlockController.DecreaseDurability(player, tempData, damageAmount)

	if customVfx then
		VfxController.Start(customVfx[1], customVfx[2], character)
	else
		VfxController.Start("Main", "BlockHit", character)
	end
end

function BlockController.ProcessBlock(
	attackerCharacter: Model,
	attackerTempData: {},
	targetPlayer: Player?,
	targetCharacter: Model,
	targetTempData: {},
	damageConfig: {}
)
	if not targetTempData.IsBlocking then
		return
	end

	if damageConfig.PerfectBlockable and BlockController.IsPerfectBlocked(targetTempData) then
		BlockController.PerfectBlock(targetPlayer, targetCharacter, attackerCharacter, attackerTempData, damageConfig.CustomPerfectBlockVfx)
		return "PerfectBlock"
	elseif damageConfig.BlockBreaking or BlockController.IsBrokeBlock(targetTempData, damageConfig.Amount) then
		BlockController.BreakBlock(targetPlayer, targetCharacter, targetTempData, damageConfig.CustomBlockBreakVfx)
		return "BlockBreak"
	else
		BlockController.HitBlock(targetPlayer, targetCharacter, targetTempData, damageConfig.Amount, damageConfig.CustomBlockHitVfx)
		return "BlockHit"
	end
end

return BlockController
