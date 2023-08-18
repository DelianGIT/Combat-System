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
		local data, functions = require(module)
		pack[module.Name] = {
			Data = data,
			Functions = functions
		}
	end
end
print("All skill packs required")

return skillPacks