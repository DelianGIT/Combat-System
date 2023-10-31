--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// MODULES
local SharedModules = ReplicatedStorage.Modules
local Utility = require(SharedModules.Utility)

local Store = require(script.Store)
local CharacterMaker = require(script.CharacterMaker)
local TempData = require(script.TempData)

--// TYPES
type Npc = {
	Name: string,
	Number: number,
	Character: Model,
	TempData: {},
}

--// VARIABLES
local npcFolders = workspace.Living.Npc

local spawnedNpc = {}
local NpcMaker = {}

--// SETTING TEMP DATA PROFILE TEMPLATE
TempData.SetTemplate({
	SkillPacks = {},
	ActiveSkills = {},
	BlockMaxDurability = 25,
	IsNpc = true,
})

--// FUNCTIONS
local function getArray(npcName: string)
	local array = spawnedNpc[npcName]
	if not array then
		array = { Counter = 0 }
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

local function stopActiveSkills(tempData: {})
	local activeSkills = tempData.ActiveSkills
	local skillPacks = tempData.SkillPacks

	for identifier, _ in activeSkills do
		local splittedString = string.split(identifier, "_")
		local pack = skillPacks[splittedString[1]]
		task.spawn(function()
			pack.InterruptSkill(splittedString[2], true)
		end)
	end
end

--// MODULE FUNCTIONS
function NpcMaker.Spawn(name: string, cframe: CFrame): Npc
	local storedData = Store[name]

	local array = getArray(name)
	local counter = array.Counter + 1
	array.Counter = counter

	local character, humanoid = CharacterMaker.Make(storedData, cframe)
	local identifier = name .. "_" .. counter
	character.Name = identifier

	local tempData = TempData.Create(character)
	local npc = {
		Name = name,
		Number = counter,
		Character = character,
		TempData = tempData,
	}

	humanoid.Died:Connect(function()
		stopActiveSkills(tempData)
		NpcMaker.Kill(npc)
	end)

	character.Parent = getFolder(name)
	array[identifier] = npc

	local spawnedFunction = storedData.SpawnedFunction
	if spawnedFunction then
		task.spawn(spawnedFunction, npc, character, tempData)
	end

	return npc
end

function NpcMaker.Kill(npc: Npc)
	local character = npc.Character
	local humanoid = character.Humanoid
	if humanoid.Health > 0 then
		humanoid.Health = 0
	end

	local name = npc.Name
	local array = getArray(name)
	array[name .. "_" .. npc.Number] = nil
	if Utility.IsTableEmpty(array) then
		spawnedNpc[name] = nil
	end

	local killedFunction = Store[name].KilledFunction
	if killedFunction then
		task.spawn(killedFunction, npc, character, npc.TempData)
	else
		npc.Character:Destroy()
	end

	local folder = getFolder(name)
	if #folder:GetChildren() == 0 then
		folder:Destroy()
	end
end

function NpcMaker.Get(name: string, number: number)
	local array = spawnedNpc[name]
	if array then
		return array[name .. "_" .. number]
	end
end

return NpcMaker
