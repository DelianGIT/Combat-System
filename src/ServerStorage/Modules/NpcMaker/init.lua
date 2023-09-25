--// SERVICES
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// MODULES
local ServerModules = ServerStorage.Modules
local BodyMover = require(ServerModules.BodyMover)
local NpcStore = require(script.NpcStore)
local TempData = require(script.TempData)

--// VARIABLES
local npcFolder = workspace.Living.Npc

local hpIndicator = ReplicatedStorage.Gui.HpIndicator

local spawnedNpc = {}
local NpcMaker = {}

--// SETTING TEMP DATA PROFILE TEMPLATE
TempData.SetProfileTemplate({
	SkillPacks = {},
	CanUseSkills = true
})

--// FUNCTIONS
local function getFolder(name: string)
	local folder = spawnedNpc[name] or {
		Count = 0
	}
	spawnedNpc[name] = folder
	return folder
end

local function makeHpIndicator(character: Model, humanoid: Humanoid)
	local indicator = hpIndicator:Clone()
	indicator.Parent = character.Head

	local amountLabel = indicator.Amount
	humanoid.HealthChanged:Connect(function(health: number)
		local amount = math.floor(health / humanoid.MaxHealth * 100)
		amountLabel.Text = amount .. "%"
	end)
	humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(function()
		local amount = math.floor(humanoid.Health / humanoid.MaxHealth * 100)
		amountLabel.Text = amount .. "%"
	end)
end

--// MODULE FUNCTIONS
function NpcMaker.Spawn(name: string, cframe: CFrame)
	local data = NpcStore[name]
	local folder = getFolder(name)

	local character = data.Character:Clone()
	character:PivotTo(cframe)
	BodyMover.CreateAttachment(character)

	local humanoid = character.Humanoid
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	makeHpIndicator(character, humanoid)

	folder.Count += 1
	name = name .. "_" .. folder.Count
	character.Name = name
	
	local tempData = TempData.Create(character)

	character.Parent = npcFolder

	local npc = {
		Name = name,
		Character = character,
		TempData = tempData
	}
	folder[name] = npc

	task.spawn(data.SpawnedFunction, npc, character, tempData)
end

function NpcMaker.Kill(name: string, number: number)
	local data = NpcStore[name]
	local folder = getFolder(name)
	
	local npc = folder[name.. "_" .. number]
	if not npc then return end

	task.spawn(data.KilledFunction, npc.Character, npc.TempData)
end

return NpcMaker