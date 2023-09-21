--// SERVICES
local ServerStorage = game:GetService("ServerStorage")

--// MODULES
local ServerModules = ServerStorage.Modules
local StunController = require(ServerModules.StunController)

--// CONFIG
local PERFECT_BLOCK_FRAME = 0.5
local BLOCK_DURABILITY = 500

--// VARIABLES
local BlockController = {}

--// MODULE FUNCTIONS
function BlockController.IsPerfectBlocked(tempData: { [any]: any })
	if not tempData.IsBlocking then
		return false
	elseif tick() - tempData.BlockTime <= PERFECT_BLOCK_FRAME then
		return true
	end
end

function BlockController.IsBrokeBlock(tempData: { [any]: any }, damage: number)
	if not tempData.IsBlocking then
		return true
	elseif tempData.BlockDurability - damage <= 0 then
		return true
	end
end

function BlockController.EnableBlock(tempData: { [any]: any })
	tempData.IsBlocking = true
	tempData.BlockTime = tick()
	tempData.BlockDurability = BLOCK_DURABILITY
end

function BlockController.DisableBlock(tempData: { [any]: any })
	tempData.IsBlocking = false
end

function BlockController.DecreaseDurability(tempData: {[any]: any}, value: number)
	tempData.BlockDurability -= value
end

function BlockController.IncreaseDurability(tempData: {[any]: any}, value: number)
	tempData.BlockDurability += value
end

function BlockController.PerfectBlock(character: Model, tempData: {[any]: any})
	StunController.Apply(character, tempData, 3)
end

function BlockController.BreakBlock(character: Model, tempData: {[any]: any})
	BlockController.DisableBlock(tempData)
	StunController.Apply(character, tempData, 3)
end

return BlockController
