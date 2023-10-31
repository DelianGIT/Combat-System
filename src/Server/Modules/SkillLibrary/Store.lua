--// SERVICES
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// CONFIG
local SKILLS_FOLDER = ServerStorage.Skills
local SHARED_DATA_FOLDER = ReplicatedStorage.SkillsData

--// VARIABLES
local store = {}

--// FUNCTIONS
local function importData(folder: {}, data: {})
	for key, value in data do
		folder[key] = value
	end
end

--// REQUIRING SKILLS
for _, dataModule in SKILLS_FOLDER:GetChildren() do
	local packName = dataModule.Name
	local data = require(dataModule)
	local sharedData = require(SHARED_DATA_FOLDER[packName])

	local pack = {}
	for _, skillModule in dataModule:GetChildren() do
		local success, result = pcall(require, skillModule)

		if success then
			local skillName = skillModule.Name

			local skillData = data[skillName] or {}
			importData(skillData, sharedData[skillName])

			pack[skillName] = {
				Data = skillData,
				Functions = result,
			}
		else
			warn("Skill module " .. packName .. "_" .. skillModule.Name .. " threw an error: " .. result)
		end
	end

	store[packName] = pack
end

return store
