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
function BlockController.EnableBlock(player: Player, tempData: {}, durability: number?)
	durability = durability or tempData.BlockMaxDurability
	tempData.Blocking = {
		Durability = durability,
		Time = tick()
	}

	if not tempData.IsNpc then
		remoteEvent:Fire(player, "Enable", durability)
	end
end

function BlockController.DisableBlock(player: Player, tempData: {})
	tempData.Blocking = nil

	if not tempData.IsNpc then
		remoteEvent:Fire(player, "Disable")
	end
end

function BlockController.ChangeDurability(player: Player?, tempData: {}, value: number)
	local blocking = tempData.Blocking
	if not blocking then return end

	blocking.Durability = value
	
	if not tempData.IsNpc then
		remoteEvent:Fire(player, "ChangeDurability", value)
	end
end

function BlockController.AddDurability(player: Player?, tempData: {}, value: number)
	local blocking = tempData.Blocking
	if not blocking then return end

	blocking.Durability += value
	
	if not tempData.IsNpc then
		remoteEvent:Fire(player, "ChangeDurability", blocking.Durability)
	end
end

function BlockController.PerfectBlock(
	tPlayer: Player,
	tTempData: {},
	tCharacter: Model,
	aCharacter: Model,
	aTempData: {},
	customVfx: boolean
)
	StunController.Apply(aCharacter, aTempData, 3)

	if not tTempData.IsNpc then
		remoteEvent:Fire(tPlayer, "PerfectBlock")
	end

	if not customVfx then
		VfxController.Start("Main", "PerfectBlock", tCharacter)
	end
end

function BlockController.BreakBlock(player: Player, character: Model, tempData: {}, customVfx: boolean)
	tempData.Blocking = nil
	StunController.Apply(character, tempData, 3)

	if not tempData.IsNpc then
		remoteEvent:Fire(player, "BlockBreak")
	end

	if not customVfx then
		VfxController.Start("Main", "BlockBreak", character)
	end
end

function BlockController.HitBlock(player: Player, tempData: {}, damageAmount: number, character: Model, customVfx: boolean)
	BlockController.AddDurability(player, tempData, -damageAmount)

	if not customVfx then
		VfxController.Start("Main", "BlockHit", character)
	end
end

function BlockController.IsPerfectBlocked(tempData: {}, blocking: {}?)
	blocking = blocking or tempData.Blocking

	if not blocking then
		return false
	elseif tick() - blocking.Time <= PERFECT_BLOCK_FRAME then
		return true
	end
end

function BlockController.IsBrokeBlock(tempData: {}, blocking: {}?, damageAmount: number)
	blocking = blocking or tempData.Blocking

	if not blocking or blocking.Durability <= damageAmount then
		return true
	end
end

return BlockController