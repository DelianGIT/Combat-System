--// SERVICES
local ServerStorage = game:GetService("ServerStorage")

--// MODULES
local ServerModules = ServerStorage.Modules
local BlockManager = require(ServerModules.DamageLibrary).BlockManager
local VfxController = require(ServerModules.VfxController)

--// SKILL
return {
	PreStart = function(args: {})
		return args.TempData.BlockMaxDurability
	end,

	PreEnd = function(args: {})
		return args.SkillData.BrokeBlock
	end,

	Start = function(args: {})
		local event = args.Event
		local tempData = args.TempData
		local character = args.Character

		local skillData = args.SkillData
		if not tempData.IsNpc then
			BlockManager.EnableBlock(tempData, {
				AlwaysPerfectBlock = skillData.AlwaysPerfectBlock,

				SetDurabilityFunction = function(_, value)
					event:Fire("SetDurability", value)
				end,

				BlockHitFunction = function()
					VfxController.Start(100, character, {
						Pack = "Block",
						Vfx = "BlockHit",
					})
				end,

				PerfectBlockFunction = function()
					event:Fire("PerfectBlock")
					VfxController.Start(100, character, {
						Pack = "Block",
						Vfx = "PerfectBlock",
					})
				end,

				BlockBreakFunction = function()
					skillData.BrokeBlock = true
					args.Pack:EndSkill("Block")
					VfxController.Start(100, character, {
						Pack = "Block",
						Vfx = "BlockBreak",
					})
				end,
			})
		else
			BlockManager.EnableBlock(tempData, {
				AlwaysPerfectBlock = skillData.AlwaysPerfectBlock,

				BlockHitFunction = function()
					VfxController.Start(100, character, {
						Pack = "Block",
						Vfx = "BlockHit",
					})
				end,

				PerfectBlockFunction = function()
					VfxController.Start(100, character, {
						Pack = "Block",
						Vfx = "PerfectBlock",
					})
				end,

				BlockBreakFunction = function()
					args.Pack:EndSkill("Block", true)
					VfxController.Start(100, character, {
						Pack = "Block",
						Vfx = "BlockBreak",
					})
				end,
			})
		end
	end,

	End = function(args: {})
		args.SkillData.BrokeBlock = false
		BlockManager.DisableBlock(args.TempData)
	end,
}
