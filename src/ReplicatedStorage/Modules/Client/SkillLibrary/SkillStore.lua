--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// CONFIG
local SKILLS_FOLDER = ReplicatedStorage.Skills

--// VARIABLES
local storedSkills = {}

--// REQUIRING SKILLS
for _, folder in SKILLS_FOLDER:GetChildren() do
	local skills = {}

	for _, module in folder:GetChildren() do
		local success, result = pcall(require, module)
		if success then
			skills[module.Name] = result
		else
			warn("Skill module " .. module.Name .. " of pack " .. folder.Name .. " threw an error: " .. result)
		end
	end

	storedSkills[folder.Name] = skills
end

return storedSkills
