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

	if player then
		remoteEvent:Fire(player, "Enable", maxDurability)
	end
end

function BlockController.DisableBlock(player: Player?, tempData: {})
	tempData.IsBlocking = false

	if player then
		remoteEvent:Fire(player, "Disable")
	end
end

function BlockController.IncreaseDurability(player: Player?, tempData: {}, value: number)
	tempData.BlockDurability += value

	if player then
		remoteEvent:Fire(player, "ChangeDurability", value)
	end
end

function BlockController.DecreaseDurability(player: Player?, tempData: {}, value: number)
	if BlockController.IsBrokeBlock(tempData, value) then
		BlockController.BreakBlock()
	else
		tempData.BlockDurability -= value

		if player then
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
	attackerTempData: {}
)
	StunController.Apply(attackerCharacter, attackerTempData, 3)

	if blockerPlayer then
		remoteEvent:Fire(blockerPlayer, "PerfectBlock")
	end

	VfxController.Start("Main", "PerfectBlock", blockerCharacter)
end

function BlockController.BreakBlock(player: Player?, character: Model, tempData: {})
	tempData.IsBlocking = false
	StunController.Apply(character, tempData, 3)

	if player then
		remoteEvent:Fire(player, "BlockBreak")
	end

	VfxController.Start("Main", "BlockBreak", character)
end

function BlockController.HitBlock(player: Player?, character: Model, tempData: {}, damageAmount: number)
	BlockController.DecreaseDurability(player, tempData, damageAmount)
	VfxController.Start("Main", "BlockHit", character)
end

function BlockController.ProcessBlock(
	attackerCharacter: Model,
	attackerTempData: {},
	targetPlayer: Player?,
	targetCharacter: Model,
	targetTempData: {},
	amount: number
)
	if not targetTempData.IsBlocking then
		return
	end

	if BlockController.IsPerfectBlocked(targetTempData) then
		BlockController.PerfectBlock(targetPlayer, targetCharacter, attackerCharacter, attackerTempData)
	elseif BlockController.IsBrokeBlock(targetTempData, amount) then
		BlockController.BreakBlock(targetPlayer, targetCharacter, targetTempData)
	else
		BlockController.HitBlock(targetPlayer, targetCharacter, targetTempData, amount)
	end
end

return BlockController
