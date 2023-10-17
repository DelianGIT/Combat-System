--// SERVICES
local ServerStorage = game:GetService("ServerStorage")

--// MODULES
local ServerModules = ServerStorage.Modules
local BlockManager = require(ServerModules.DamageHandler).BlockManager

--// FUNCTIONS
local function spawned(npc: {}, character: Model, tempData: {})
	tempData.BlockMaxDurability = math.huge
	
	local humanoid = character.Humanoid
	while humanoid.Health > 0 and task.wait(0.5) do
		if not tempData.Blocking then
			BlockManager.EnableBlock(npc, tempData)
		end
	end
end

return {
	SpawnedFunction = spawned,
	Character = ServerStorage.Assets.Npc.Dummy
}