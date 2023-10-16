--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// MODULES
local SharedModules = ReplicatedStorage.Modules
local Utilities = require(SharedModules.Utilities)

local Store = require(script.Store)
local CharacterMaker = require(script.CharacterMaker)
local TempData = require(script.TempData)

--// TYPES
type Npc = {
	Name: string,
	Count: number,
	Character: Model,
	TempData: {},
	IsNpc: true
}

--// VARIABLES
local npcFolders = workspace.Living.Npc

local spawnedNpc = {}
local NpcMaker = {}

--// SETTING TEMP DATA PROFILE TEMPLATE
TempData.SetTemplate({
	SkillPacks = {},
	ActiveSkills = {},
	BlockMaxDurability = 50,
	IsNpc = true
})

--// FUNCTIONS
local function stopActiveSkills(tempData: {})
	local activeSkills = tempData.ActiveSkills
	local skillPacks = tempData.SkillPacks

	for identifier, properties in activeSkills do
		local skillName = string.split(identifier, "_")[2]
		local pack = skillPacks[properties.PackName]
		task.spawn(function()
			pack:InterruptSkill(skillName, true)
		end)
	end
end

local function getArray(npcName: string)
	local array = spawnedNpc[npcName]
	if not array then
		array = {Count = 0}
		spawnedNpc[npcName] = array
	end
	return array
end

local function getFolder(npcName: string)
	local folder = npcFolders:FindFirstChild(npcName)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = npcName
		folder.Parent = npcFolders
	end
	return folder
end

--// MODULE FUNCTIONS
function NpcMaker.Spawn(name: string, cframe: CFrame): Npc
	local data = Store[name]

	local array = getArray(name)
	local count = array.Count + 1
	array.Count = count

	local character, humanoid = CharacterMaker.Make(data, cframe)
	local newName = name .. "_" .. count
	character.Name = newName

	local tempData = TempData.Create(character)
	local npc = {
		Name = name,
		Count = count,
		Character = character,
		TempData = tempData
	}

	humanoid.Died:Connect(function()
		stopActiveSkills(tempData)
		NpcMaker.Kill(npc)
	end)

	character.Parent = getFolder(name)
	array[newName] = npc

	local spawnedFunction = data.SpawnedFunction
	if spawnedFunction then
		task.spawn(spawnedFunction, npc, character, tempData)
	end
		
	return npc
end

function NpcMaker.Kill(npc: Npc, killedFunction: (npc: Npc, character: Model, tempData: {}) -> ()?)
	local character = npc.Character
	local humanoid = character.Humanoid
	if humanoid.Health > 0 then
		humanoid.Health = 0
	end

	local name = npc.Name
	local array = getArray(name)
	array[name .. "_" .. npc.Count] = nil
	if Utilities.IsTableEmpty(array) then
		spawnedNpc[name] = nil
	end

	if not killedFunction then
		killedFunction = Store[name].KilledFunction
	end

	if killedFunction then
		task.spawn(killedFunction, npc, character, npc.TempData)
	else
		task.delay(3, function()
			npc.Character:Destroy()
		end)
	end
end

function NpcMaker.Get(name: string, count: number)
	local array = spawnedNpc[name]
	if array then
		return array[name .. "_" .. count]
	end
end

return NpcMaker