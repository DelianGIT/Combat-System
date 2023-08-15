--// SERVICES
local ServerStorage = game:GetService("ServerStorage")

--// VARIABLES
local skillsData = {}
local skillsFunctions = {}

--// CONFIG
local SKILLS_FOLDER = ServerStorage.Skills

--// CONSTRUCTING SKILLS
for _, packFolder in SKILLS_FOLDER:GetChildren() do
	local dataPack = {}
	local functionsPack = {}
	
	for _, skillModule in packFolder:GetChildren() do
		local skill = require(skillModule)
		dataPack[skillModule.Name] = skill[1]
		functionsPack[skillModule.Name] = skill[2]
	end

	skillsData[packFolder.Name] = dataPack
	skillsFunctions[packFolder.Name] = functionsPack
end
print("All skill modules required")

return {
	Data = skillsData,
	Functions = skillsFunctions
}