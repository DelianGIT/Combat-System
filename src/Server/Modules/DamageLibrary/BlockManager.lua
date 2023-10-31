--// MODULES
local StunManager = require(script.Parent.StunManager)

--// TYPES
export type Config = {
	BlockHitable: boolean,
	PerfectBlockable: boolean,
	BlockBreakable: boolean,

	PerfectBlockFrame: number,

	PerfectBlockStun: StunManager.Config,
	BlockBreakStun: StunManager.Config,

	BlockHitFunction: () -> (),
	PerfectBlockFunction: () -> (),
	BlockBreakFunction: () -> (),
}
type Block = {
	Durability: number,
	MaxDurability: number,
	Time: number,

	AlwaysPerfectBlock: boolean,

	SetDurabilityFunction: () -> (),
	BlockHitFunction: () -> (),
	PerfectBlockFunction: () -> (),
	BlockBreakFunction: () -> (),
}

--// VARIABLES
local BlockManager = {}

--// MODULE FUNCTIONS
function BlockManager.MakeConfig(): Config
	return {}
end

function BlockManager.EnableBlock(tempData: {}, block: Block)
	local durability = block.Durability
	local maxDurability = block.MaxDurability
	if not durability and not maxDurability then
		local blockMaxDurability = tempData.BlockMaxDurability
		block.Durability = blockMaxDurability
		block.MaxDurability = blockMaxDurability
	elseif not durability then
		block.Durability = tempData.BlockMaxDurability
	elseif not maxDurability then
		block.MaxDurability = tempData.BlockMaxDurability
	end

	block.Time = os.clock()

	tempData.Block = block
end

function BlockManager.DisableBlock(tempData: {})
	tempData.Block = nil
end

function BlockManager.SetDurability(block: Block, value: number)
	block.Durability = value

	local func = block.SetDurabilityFunction
	if func then
		task.spawn(func, block, value)
	end
end

function BlockManager.AddDurability(block: Block, value: number)
	block.Durability += value

	local func = block.SetDurabilityFunction
	if func then
		task.spawn(func, block, block.Durability)
	end
end

function BlockManager.HitBlock(block: Block, damageAmount: number, config: Config)
	BlockManager.AddDurability(block, -damageAmount)

	local func = config.BlockHitFunction
	if func then
		task.spawn(func)
	end

	func = block.BlockHitFunction
	if func then
		task.spawn(func, block)
	end
end

function BlockManager.PerfectBlock(aCharacter: Model, aTempData: {}, tBlock: Block, config: Config)
	local stun = config.PerfectBlockStun
	if stun ~= false then
		if stun then
			StunManager.Apply(aCharacter, aTempData, stun)
		else
			StunManager.Apply(aCharacter, aTempData, {
				Priority = 1,
				Duration = 2,
				WalkSpeed = 0,
				JumpPower = 0,
			})
		end
	end

	local func = config.PerfectBlockFunction
	if func then
		task.spawn(func)
	end

	func = tBlock.PerfectBlockFunction
	if func then
		task.spawn(func, tBlock)
	end
end

function BlockManager.BreakBlock(character: Model, tempData: {}, block: Block, config: Config)
	tempData.Block = nil

	local stun = config.BlockBreakStun
	if stun ~= false then
		if stun then
			StunManager.Apply(character, tempData, stun)
		else
			StunManager.Apply(character, tempData, {
				Priority = 1,
				Duration = 3,
				WalkSpeed = 0,
				JumpPower = 0,
			})
		end
	end

	local func = config.BlockBreakFunction
	if func then
		task.spawn(func)
	end

	func = block.BlockBreakFunction
	if func then
		task.spawn(func, block)
	end
end

function BlockManager.IsPerfectBlocked(block: Block, timeFrame: number?)
	timeFrame = timeFrame or block.PerfectBlockFrame

	if not block then
		return false
	elseif os.clock() - block.Time <= timeFrame then
		return true
	end
end

function BlockManager.IsBrokeBlock(block: Block, damageAmount: number)
	if not block or block.Durability <= damageAmount then
		return true
	end
end

function BlockManager.ProcessBlock(
	aCharacter: Model,
	aTempData: {},
	tCharacter: Model,
	tTempData: {},
	tBlock: Block?,
	damageAmount: number,
	config: Config
)
	if
		tBlock.AlwaysPerfectBlock
		or (config.PerfectBlockable and BlockManager.IsPerfectBlocked(tBlock, config.PerfectBlockFrame))
	then
		BlockManager.PerfectBlock(aCharacter, aTempData, tBlock, config)
		return "PerfectBlock"
	elseif config.BlockBreakable or BlockManager.IsBrokeBlock(tBlock, damageAmount) then
		BlockManager.BreakBlock(tCharacter, tTempData, tBlock, config)
		return "BlockBreak"
	elseif config.BlockHitable then
		BlockManager.HitBlock(tBlock, damageAmount, config)
		return "BlockHit"
	end
end

return BlockManager
