--// SERVICES
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// MODULES
local ServerModules = ServerStorage.Modules
local BodyMover = require(ServerModules.BodyMover)

--// VARIABLES
local charactersFolder = workspace.Living.Players

local hpIndicator = ReplicatedStorage.Gui.HpIndicator

local CharacterMaker = {}

--// FUNCTIONS
local function makeHpIndicator(player: Player, character: Model, humanoid: Humanoid)
	local indicator = hpIndicator:Clone()
	indicator.PlayerToHideFrom = player
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
function CharacterMaker.Make(player: Player)
	local existingCharacter = player.Character
	if existingCharacter then
		existingCharacter:Destroy()
	end

	player.CharacterAdded:Once(function(newCharacter: Model)
		RunService.Heartbeat:Once(function()
			newCharacter.Archivable = true
			newCharacter.Parent = charactersFolder
			newCharacter.Archivable = false
		end)

		local humanoid = newCharacter.Humanoid
		humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		humanoid.Died:Connect(function()
			CharacterMaker.Make(player)
		end)
		makeHpIndicator(player, newCharacter, humanoid)

		BodyMover.CreateAttachment(newCharacter)
	end)

	player:LoadCharacter()
end

return CharacterMaker