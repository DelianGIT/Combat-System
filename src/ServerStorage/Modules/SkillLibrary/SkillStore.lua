--// SERVICES
local ServerStorage = game:GetService("ServerStorage")

--// VARIABLES
local skillPacks = {}

--// CONFIG
local SKILLS_FOLDER = ServerStorage.Skills

--// REQUIRING SKILLS
for _, folder in SKILLS_FOLDER:GetChildren() do
	local pack = {}
	skillPacks[folder.Name] = pack
	
	for _, module in folder:GetChildren() do
		pack[module.Name] = require(module)
	end
end
print("All skill packs required")

return skillPacks