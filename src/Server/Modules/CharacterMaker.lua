--// SERVICES
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

--// MODULES
local ServerModules = ServerStorage.Modules
local BodyMover = require(ServerModules.BodyMover)
local DamageLibrary = require(ServerModules.DamageLibrary)
local WalkSpeedManager = DamageLibrary.WalkSpeedManager
local JumpPowerManager = DamageLibrary.JumpPowerManager
local StunManager = DamageLibrary.StunManager
local KnockbackManager = DamageLibrary.KnockbackManager

--// VARIABLES
local charactersFolder = workspace.Living.Players

local hpIndicator = ServerStorage.Assets.Gui.HpIndicator

local CharacterMaker = {}

--// FUNCTIONS
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

local function calculatePercentage(health: number, maxHealth)
	if health == maxHealth then
		return "∞%"
	else
		local amount = math.floor(health / maxHealth * 100)
		return amount .. "%"
	end
end

local function makeHpIndicator(player: Player, character: Model, humanoid: Humanoid)
	local indicator = hpIndicator:Clone()
	indicator.PlayerToHideFrom = player
	indicator.Parent = character.HumanoidRootPart

	local amountLabel = indicator.Amount
	humanoid.HealthChanged:Connect(function(health: number)
		amountLabel.Text = calculatePercentage(health, humanoid.MaxHealth)
	end)
	humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(function()
		amountLabel.Text = calculatePercentage(humanoid.Health, humanoid.MaxHealth)
	end)
end

local function prepareHumanoid(player: Player, tempData: {}, character: Model)
	local humanoid = character.Humanoid
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None

	humanoid.Died:Connect(function()
		stopActiveSkills(tempData)

		JumpPowerManager.Cancel(character, tempData)
		WalkSpeedManager.Cancel(character, tempData)
		StunManager.Cancel(character, tempData)
		KnockbackManager.Cancel(tempData)

		CharacterMaker.Make(player, tempData)
	end)

	makeHpIndicator(player, character, humanoid)
end

local function moveCharacterToFolder(character: Model)
	RunService.Heartbeat:Once(function()
		character.Archivable = true
		character.Parent = charactersFolder
		character.Archivable = false
	end)
end

--// MODULE FUNCTIONS
function CharacterMaker.Make(player: Player, tempData: {})
	if player.Parent ~= Players then
		return
	end

	local existingCharacter = player.Character
	if existingCharacter then
		existingCharacter:Destroy()
	end

	player.CharacterAdded:Once(function(newCharacter: Model)
		moveCharacterToFolder(newCharacter)
		prepareHumanoid(player, tempData, newCharacter)
		BodyMover.CreateAttachment(newCharacter)
	end)

	player:LoadCharacter()
end

return CharacterMaker
