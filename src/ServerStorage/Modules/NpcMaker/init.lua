--// SERVICES
local ServerStorage = game:GetService("ServerStorage")

--// MODULES
local ServerModules = ServerStorage.Modules
local BodyMover = require(ServerModules.BodyMover)

local NpcStore = require(script.NpcStore)
local TempData = require(script.TempData)

--// VARIABLES
local npcFolder = workspace.Living.Npc

local hpIndicator = ServerStorage.Assets.Gui.HpIndicator

local spawnedNpc = {}
local NpcMaker = {}

--// SETTING TEMP DATA PROFILE TEMPLATE
TempData.SetProfileTemplate({
	SkillPacks = {},
	ActiveSkills = {},
	CanUseSkills = true,
	BlockMaxDurability = 100,
})

--// FUNCTIONS
local function getFolder(name: string)
	local folder = spawnedNpc[name] or {
		Count = 0,
	}
	spawnedNpc[name] = folder
	return folder
end

local function isTableEmpty(table: {})
	for _, _ in table do
		return false
	end
	return true
end

local function makeCharacter(name: string, count: number, data: {}, cframe: CFrame)
	local character = data.Character:Clone()
	character.Name = name .. "_" .. count
	character:PivotTo(cframe)

	BodyMover.CreateAttachment(character)

	return character
end

local function stopActiveSkills(tempData: {})
	local activeSkills = tempData.ActiveSkills
	local skillPacks = tempData.SkillPacks

	for skillName, properties in activeSkills do
		local pack = skillPacks[properties.PackName]
		task.spawn(function()
			pack:InterruptSkill(skillName, true)
		end)
	end
end

local function makeHpIndicator(character: Model, humanoid: Humanoid)
	local indicator = hpIndicator:Clone()
	indicator.Parent = character.HumanoidRootPart

	local amountLabel = indicator.Amount
	humanoid.HealthChanged:Connect(function(health: number)
		local maxHealth = humanoid.MaxHealth

		if health == maxHealth then
			amountLabel.Text = "∞%"
		else
			local amount = math.floor(health / humanoid.MaxHealth * 100)
			amountLabel.Text = amount .. "%"
		end
	end)
	humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(function()
		local health = humanoid.Health
		local maxHealth = humanoid.MaxHealth

		if health == maxHealth then
			amountLabel.Text = "∞%"
		else
			local amount = math.floor(humanoid.Health / humanoid.MaxHealth * 100)
			amountLabel.Text = amount .. "%"
		end
	end)
end

local function prepairHumanoid(character: Model, npc: {}, tempData: {}, killedFunction: () -> ())
	local humanoid = character.Humanoid
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	makeHpIndicator(character, humanoid)

	humanoid.Died:Connect(function()
		stopActiveSkills(tempData)

		if killedFunction then
			task.spawn(killedFunction, npc, character, tempData)
		end
	end)
end

--// MODULE FUNCTIONS
function NpcMaker.Spawn(name: string, cframe: CFrame)
	local data = NpcStore[name]

	local folder = getFolder(name)
	folder.Count += 1

	local character = makeCharacter(name, folder.Count, data, cframe)
	local tempData = TempData.Create(character)
	local npc = {
		Name = name,
		Character = character,
		TempData = tempData,
	}

	prepairHumanoid(character, npc, tempData, data.KilledFunction)
	character.Parent = npcFolder

	folder[name] = npc

	local spawnedFunction = data.SpawnedFunction
	if spawnedFunction then
		task.spawn(data.SpawnedFunction, npc, character, tempData)
	end

	return npc
end

function NpcMaker.Kill(name: string, number: number)
	local data = NpcStore[name]
	local folder = getFolder(name)

	local npc = folder[name .. "_" .. number]
	if not npc then
		return
	end

	local killedFunction = data.KilledFunction
	if killedFunction then
		task.spawn(data.killedFunction, npc, npc.Character, npc.TempData)
	end

	folder[name] = nil
	if isTableEmpty(folder) then
		spawnedNpc[name] = nil
	end
end

return NpcMaker
