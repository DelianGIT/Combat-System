--// SERVICES
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// CONFIG
local PACKS_FOLDER = ReplicatedFirst.SkillPacks
local SHARED_DATA_FOLDER = ReplicatedStorage.SkillsData

--// VARIABLES
local storedPacks = {}

--// FUNCTIONS
local function importData(dataFolder: {}, dataToImport: {})
	for key, value in dataToImport do
		dataFolder[key] = value
	end
end

--// REQUIRING SKILLS
for _, folder in PACKS_FOLDER:GetChildren() do
	local pack = {}
	local sharedPackData = SHARED_DATA_FOLDER[folder.Name]

	for _, module in folder:GetChildren() do
		local success, skill = pcall(require, module)
		if not success then
			warn("Skill module " .. folder.Name .. "_" .. module.Name .. " threw an error: " .. skill)
			continue
		end

		local sharedSkillData = require(sharedPackData[module.Name])
		importData(skill.Data, sharedSkillData)

		pack[module.Name] = skill
	end

	storedPacks[folder.Name] = pack	
end

return storedPacks
