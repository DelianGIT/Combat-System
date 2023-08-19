--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// VARIABLES
local skillPacks = {}

--// CONFIG
local SKILLS_FOLDER = ReplicatedStorage.Skills

--// REQUIRING SKILLS
for _, folder in SKILLS_FOLDER:GetChildren() do
	local pack = {}
	skillPacks[folder.Name] = pack
	
	for _, module in folder:GetChildren() do
		local success, result = pcall(require, module)
		if success then
			pack[module.Name] = result
		else
			warn("Skill module " .. module.Name .. " of pack " .. folder.Name .. " threw an error: " .. result)
		end
	end
end

return skillPacks