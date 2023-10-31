--// SERVICES
local ServerStorage = game:GetService("ServerStorage")

--// MODULES
local ServerModules = ServerStorage.Modules
local SkillLibrary = require(ServerModules.SkillLibrary)

--// FUNCTIONS
local function spawned(npc: {}, character: Model, tempData: {})
	local skillPack = SkillLibrary.GiveSkillPack("Main", npc, tempData)

	local humanoid = character.Humanoid
	while humanoid.Health > 0 and task.wait(3) do
		if not tempData.Block then
			skillPack:StartSkill("Block")
		end
	end
end

return {
	SpawnedFunction = spawned,
	Character = ServerStorage.Assets.Npc.Dummy,
}
