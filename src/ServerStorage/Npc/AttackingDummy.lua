--// SERVICES
local ServerStorage = game:GetService("ServerStorage")

--// MODULES
local ServerModules = ServerStorage.Modules
local SkillLibrary = require(ServerModules.SkillLibrary)

--// FUNCTIONS
local function spawned(npc: {}, character: Model, tempData: { [any]: any })
	local skillPack = SkillLibrary.GiveSkillPack("Main", npc, tempData)
	SkillLibrary.MakeSkillEvents(tempData)

	local humanoid = character.Humanoid
	while humanoid.Health > 0 and task.wait(1) do
		skillPack:StartSkill("Punch")
	end
end

local function killed() end

return { spawned, killed }
