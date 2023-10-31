--// SERVICES
local ServerStorage = game:GetService("ServerStorage")

--// MODULES
local ServerModules = ServerStorage.Modules
local SkillLibrary = require(ServerModules.SkillLibrary)

--// FUNCTIONS
local function spawned(npc: {}, character: Model, tempData: {})
	local skillPack = SkillLibrary.GiveSkillPack("Main", npc, tempData)
	local cooldown = skillPack.Skills.Punch.Data.Cooldown.Duration

	local humanoid = character.Humanoid
	while humanoid.Health > 0 and task.wait(cooldown) do
		skillPack:StartSkill("Punch")
	end
end

return {
	SpawnedFunction = spawned,
	Character = ServerStorage.Assets.Npc.Dummy,
}
