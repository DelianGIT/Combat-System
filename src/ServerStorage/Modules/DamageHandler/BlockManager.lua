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
	CustomBlock: boolean,
	CustomPerfectBlock: boolean,
	CustomBlockBreak: boolean,

	PerfectBlockFrame: number,
	PerfectBlockStun: StunManager.Config,

	BlockFunction: () -> (),
	PerfectBlockFunction: () -> (),
	BlockBreakFunction: () -> (),
}
type Block = {
	Time: number,
	Durability: number,
	MaxDurability: number,

	Enabled: boolean,

	PerfectBlockStun: StunManager.Config | false | nil,
	BlockBreakStun: StunManager.Config | false | nil,
}

--// VARIABLES\
local remoteEvents = ReplicatedStorage.Events
local remoteEvent = require(remoteEvents.BlockIndicator):Server()

local BlockManager = {}

--// MODULE FUNCTIONS
function BlockManager.MakeConfig(): Config
	return {}
end

function BlockManager.EnableBlock(player: Player, tempData: {}, durability: number?): Block
	durability = durability or tempData.BlockMaxDurability

	local block = {
		Durability = durability,
		MaxDurability = durability,
		Time = os.clock(),
	}
	tempData.Block = block

	if not tempData.IsNpc then
		remoteEvent:Fire(player, "Enable", durability)
	end

	return block
end

function BlockManager.DisableBlock(player: Player, tempData: {})
	tempData.Block = nil

	if not tempData.IsNpc then
		remoteEvent:Fire(player, "Disable")
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

function BlockManager.SetDurability(player: Player, tempData: {}, block: Block?, value: number)
	block = block or tempData.Block
	if not block then
		return
	end

	block.Durability = value

	if not tempData.IsNpc then
		remoteEvent:Fire(player, "ChangeDurability", value)
	end
end

function BlockManager.AddDurability(player: Player, tempData: {}, block: Block?, value: number)
	block = block or tempData.Block
	if not block then
		return
	end

	block.Durability += value

	if not tempData.IsNpc then
		remoteEvent:Fire(player, "ChangeDurability", block.Durability)
	end
end

function BlockManager.PerfectBlock(aCharacter: Model, aTempData: {}, tPlayer: Player, tCharacter: Model, tTempData: {}, config: Config)
	local stun = config.PerfectBlockStun
	if stun then
		StunManager.Apply(aCharacter, aTempData, stun)
	elseif stun == false then
		return
	else
		StunManager.Apply(aCharacter, aTempData, {
			Priority = 1,
			Duration = 2,
			WalkSpeed = 0,
			JumpPower = 0
		})
	end

	if not config.CustomPerfectBlock then
		VfxController.Start(100, 3, "Block", "PerfectBlock", tCharacter)
	end

	if not tTempData.IsNpc then
		remoteEvent:Fire(tPlayer, "PerfectBlock")
	end
end

function BlockManager.BreakBlock(player: Player, character: Model, tempData: {}, config: Config)
	tempData.Block = nil

	local stun = config.BlockBreakStun
	if stun then
		StunManager.Apply(character, tempData, stun)
	elseif stun == false then
		return
	else
		StunManager.Apply(character, tempData, {
			Priority = 1,
			Duration = 3,
			WalkSpeed = 0,
			JumpPower = 0,
			BlockSkills = true,
		})
	end

	if not config.CustomBlockBreak then
		VfxController.Start(100, 3, "Block", "BlockBreak", character)
	end

	if not tempData.IsNpc then
		remoteEvent:Fire(player, "BlockBreak")
	end
end

function BlockManager.HitBlock(player: Player | {}, character: Model, tempData: {}, block: Block, damageAmount: number, config: Config)
	BlockManager.AddDurability(player, tempData, block, -damageAmount)

	if not config.CustomBlock then
		VfxController.Start(100, 3, "Block", "BlockHit", character)
	end
end

function BlockManager.ProcessBlock(
	aCharacter: Model,
	aTempData: {},
	tPlayer: Player,
	tCharacter: Model,
	tTempData: {},
	damageAmount: number,
	config: Config
)
	local block = tTempData.Block
	if not block then
		return
	end
	
	if config.PerfectBlockable and BlockManager.IsPerfectBlocked(block, config.PerfectBlockFrame) then
		BlockManager.PerfectBlock(aCharacter, aTempData, tPlayer, tCharacter, tTempData, config)

		local perfectBlockFunction = config.PerfectBlockFunction
		if perfectBlockFunction then
			perfectBlockFunction()
		end

		return "PerfectBlock"
	elseif config.BlockBreakable or BlockManager.IsBrokeBlock(block, damageAmount) then
		BlockManager.BreakBlock(tPlayer, tCharacter, tTempData, config)

		local blockBreakFunction = config.BlockBreakFunction
		if blockBreakFunction then
			blockBreakFunction()
		end

		return "BlockBreak"
	elseif config.Blockable then
		BlockManager.HitBlock(tPlayer, tCharacter, tTempData, block, damageAmount, config)

		local blockFunction = config.BlockFunction
		if blockFunction then
			blockFunction()
		end

		return "Block"
	end
end

return BlockManager
