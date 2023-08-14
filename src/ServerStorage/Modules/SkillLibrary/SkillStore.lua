--// SERVICES
local ServerStorage = game:GetService("ServerStorage")

--// VARIABLES
local skillsFolder = ServerStorage.Skills

local skillsData = {}
local skillsFunctions = {}

--// CONSTRUCTING SKILLS
for _, packFolder in ipairs(skillsFolder:GetChildren()) do
	local dataPack = {}
	local functionsPack = {}
	
	for _, skill in ipairs(packFolder:GetChildren()) do
		local data, functions = require(skill)
		dataPack[skill.Name] = data
		functionsPack[skill.Name] = functions
	end

	skillsData[packFolder.Name] = dataPack
	skillsFunctions[packFolder.Name] = functionsPack
end

return {
	Data = skillsData,
	Functions = skillsFunctions
}