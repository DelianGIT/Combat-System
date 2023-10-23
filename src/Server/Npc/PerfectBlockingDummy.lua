--// SERVICES
local ServerStorage = game:GetService("ServerStorage")

--// MODULES
local ServerModules = ServerStorage.Modules
local BlockManager = require(ServerModules.DamageLibrary).BlockManager

--// FUNCTIONS
local function spawned(npc: {}, character: Model, tempData: {})
	tempData.CounterSkill = function(_, aCharacter: Model, aTempData: {})
		BlockManager.PerfectBlock(aCharacter, aTempData, npc, character, tempData, {})
		spawned(npc, character, tempData)
	end
end

return {
	SpawnedFunction = spawned,
	Character = ServerStorage.Assets.Npc.Dummy
}