--// SERVICES
local ServerStorage = game:GetService("ServerStorage")

--// MODULES
local ServerModules = ServerStorage.Modules
local SkillLibrary = require(ServerModules.SkillLibrary)

--// FUNCTIONS
local function spawned(npc: {}, character: Model, tempData: {})
	local skillPack = SkillLibrary.GiveSkillPack("Main", npc, tempData)
	local skillData = skillPack.Skills.Block.Data
	skillData.AlwaysPerfectBlock = true
	skillData.Cooldown.Duration = 1

	local humanoid = character.Humanoid
	while humanoid.Health > 0 and task.wait(1) do
		if not tempData.Block then
			skillPack:StartSkill("Block")
		end
	end
end

return {
	SpawnedFunction = spawned,
	Character = ServerStorage.Assets.Npc.Dummy,
}
