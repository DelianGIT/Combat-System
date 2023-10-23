--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

--// MODULES
local ServerModules = ServerStorage.Modules
local VfxController = require(ServerModules.VfxController)

local StunManager = require(script.Parent.StunManager)

--// TYPES
export type Config = {
	Blockable: boolean,
	PerfectBlockable: boolean,
	BlockBreakable: boolean,

	CustomBlockHit: boolean,
	CustomPerfectBlock: boolean,
	CustomBlockBreak: boolean,

	PerfectBlockFrame: number,
	PerfectBlockStun: StunManager.Config,

	BlockHitFunction: () -> (),
	PerfectBlockFunction: () -> (),
	BlockBreakFunction: () -> (),
}
type Block = {
	Durability: number,
	MaxDurability: number,
	Time: number
}

--// VARIABLES
local remoteEvents = ReplicatedStorage.Events
local remoteEvent = require(remoteEvents.BlockIndicator):Server()

local BlockManager = {}

--// MODULE FUNCTIONS
function BlockManager.MakeConfig(): Config
	return {}
end

function BlockManager.EnableBlock(player: Player, tempData: {}, durability: number?)
	durability = durability or tempData.BlockMaxDurability

	tempData.Block = {
		Durability = durability,
		MaxDurability = durability,
		Time = os.clock(),
	}

	if not tempData.IsNpc then
		remoteEvent:Fire(player, "Enable", durability)
	end
end

function BlockManager.DisableBlock(player: Player, tempData: {})
	tempData.Block = nil

	if not tempData.IsNpc then
		remoteEvent:Fire(player, "Disable")
	end
end

function BlockManager.SetDurability(player: Player, tempData: {}, value: number, block: Block)
	block = block or tempData.Block
	if not block then
		return
	end

	block.Durability = value

	if not tempData.IsNpc then
		remoteEvent:Fire(player, "SetDurability", value)
	end
end

function BlockManager.AddDurability(player: Player, tempData: {}, value: number, block: Block)
	block = block or tempData.Block
	if not block then
		return
	end

	block.Durability += value

	if not tempData.IsNpc then
		remoteEvent:Fire(player, "SetDurability", block.Durability)
	end
end

function BlockManager.IsPerfectBlocked(tempData: {}, timeFrame: number?, block: Block?)
	block = block or tempData.Block
	timeFrame = timeFrame or block.PerfectBlockFrame

	if not block then
		return false
	elseif os.clock() - block.Time <= timeFrame then
		return true
	end
end

function BlockManager.IsBrokeBlock(tempData: {}, damageAmount: number, block: Block?)
	block = block or tempData.Block
	if not block or block.Durability <= damageAmount then
		return true
	end
end

function BlockManager.PerfectBlock(aCharacter: Model, aTempData: {}, tPlayer: Player, tCharacter: Model, tTempData: {}, config: Config)
	local stun = config.PerfectBlockStun
	if stun ~= false then
		if stun then
			StunManager.Apply(aCharacter, aTempData, stun)
		else
			StunManager.Apply(aCharacter, aTempData, {
				Priority = 1,
				Duration = 2,
				WalkSpeed = 0,
				JumpPower = 0
			})
		end
	end

	if not config.CustomPerfectBlock then
		VfxController.Start("Block", "PerfectBlock", 100, 3, tCharacter)
	end

	if not tTempData.IsNpc then
		remoteEvent:Fire(tPlayer, "PerfectBlock")
	end
end

function BlockManager.BreakBlock(player: Player, character: Model, tempData: {}, config: Config)
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
				JumpPower = 0
			})
		end
	end

	if not config.CustomBlockBreak then
		VfxController.Start("Block", "Main", 100, 3, character)
	end

	if not tempData.IsNpc then
		remoteEvent:Fire(player, "BlockBreak")
	end
end

function BlockManager.HitBlock(player: Player, character: Model, tempData: {}, block: Block, damageAmount: number, config: Config)
	BlockManager.AddDurability(player, tempData, block, -damageAmount)

	if not config.CustomBlockHit then
		VfxController.Start("Block", "BlockHit", 100, 3, character)
	end
end

function BlockManager.ProcessBlock(aCharacter: Model, aTempData: {}, tPlayer: Player, tCharacter: Model, tTempData: {}, damageAmount: number, config: Config)
	local block = tTempData.Block
	if not block then
		return
	end

	if config.PerfectBlockable and BlockManager.IsPerfectBlocked(tTempData, config.PerfectBlockFrame, block) then
		BlockManager.PerfectBlock(aCharacter, aTempData, tPlayer, tCharacter, tTempData, config)

		local perfectBlockFunction = config.PerfectBlockFunction
		if perfectBlockFunction then
			perfectBlockFunction()
		end

		return "PerfectBlock"
	elseif config.BlockBreakable or BlockManager.IsBrokeBlock(tTempData, damageAmount, block) then
		BlockManager.BreakBlock(tPlayer, tCharacter, tTempData, config)

		local blockBreakFunction = config.BlockBreakFunction
		if blockBreakFunction then
			blockBreakFunction()
		end

		return "BlockBreak"
	elseif config.Blockable then
		BlockManager.HitBlock(tPlayer, tCharacter, tTempData, block, damageAmount, config)
	
		local blockHitFunction = config.BlockHitFunction
		if blockHitFunction then
			blockHitFunction()
		end

		return "BlockHit"
	end
end

return BlockManager