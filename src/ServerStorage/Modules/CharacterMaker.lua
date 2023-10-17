--// SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

--// MODULES
local ServerModules = ServerStorage.Modules
local BodyMover = require(ServerModules.BodyMover)
local DamageHandler = require(ServerModules.DamageHandler)
local WalkSpeedManager = DamageHandler.WalkSpeedManager
local JumpPowerManager = DamageHandler.JumpPowerManager
local StunManager = DamageHandler.StunManager
local KnockbackManager = DamageHandler.KnockbackManager

--// VARIABLES
local charactersFolder = workspace.Living.Players

local hpIndicator = ServerStorage.Assets.Gui.HpIndicator

local CharacterMaker = {}

--// FUNCTIONS
local function makeHpIndicator(player: Player, character: Model, humanoid: Humanoid)
	local indicator = hpIndicator:Clone()
	indicator.PlayerToHideFrom = player
	indicator.Parent = character.HumanoidRootPart

	local amountLabel = indicator.Amount
	humanoid.HealthChanged:Connect(function(health: number)
		local maxHealth = humanoid.MaxHealth

		if health == maxHealth then
			amountLabel.Text = "∞%"
		else
			local amount = math.floor(health / maxHealth * 100)
			amountLabel.Text = amount .. "%"
		end
	end)
	humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(function()
		local health = humanoid.Health
		local maxHealth = humanoid.MaxHealth

		if health == maxHealth then
			amountLabel.Text = "∞%"
		else
			local amount = math.floor(health / maxHealth * 100)
			amountLabel.Text = amount .. "%"
		end
	end)
end

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