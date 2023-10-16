--// SERVICES
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// CONFIG
local SKILLS_FOLDER = ReplicatedFirst.Skills
local SHARED_DATA_FOLDER = ReplicatedStorage.SkillsData

--// VARIABLES
local Store = {}

--// FUNCTIONS
local function importData(dataFolder: {}, dataToImport: {})
	for key, value in dataToImport do
		dataFolder[key] = value
	end
end

--// REQUIRING SKILLS
for _, folder in SKILLS_FOLDER:GetChildren() do
	local pack = {}
	local sharedData = SHARED_DATA_FOLDER[folder.Name]

	for _, module in folder:GetChildren() do
		local success, result = pcall(require, module)
		if not success then
			warn("Skill module " .. folder.Name .. "_" .. module.Name .. " threw an error: " .. result)
		else
			local sharedSkillData = require(sharedData[module.Name])
			importData(result.Data, sharedSkillData)
	
			pack[module.Name] = result
		end
	end

	Store[folder.Name] = pack
end

return Store