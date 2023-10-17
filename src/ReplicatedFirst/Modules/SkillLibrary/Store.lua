--// SERVICES
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// CONFIG
local SKILLS_FOLDER = ReplicatedFirst.Skills
local SHARED_DATA_FOLDER = ReplicatedStorage.SharedSkillsData

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
	for skillName, skillData in data do
		local skillModule = dataModule:FindFirstChild(skillName)

		local result
		if skillModule then
			local success
			success, result = pcall(require, skillModule)
			if not success then
				warn("Skill module " .. packName .. "_" .. skillModule.Name .. " threw an error: " .. result)
				continue
			end
		end

		importData(skillData, sharedData[skillName])

		pack[skillName] = {
			Data = skillData,
			Functions = result
		}
	end

	store[packName] = pack
end

return store