--// SERVICES
local ServerStorage = game:GetService("ServerStorage")

--// MODULES
local ServerModules = ServerStorage.Modules
local BodyMover = require(ServerModules.BodyMover)

--// VARIABLES
local hpIndicator = ServerStorage.Assets.Gui.HpIndicator

local function calculatePercentage(health: number, maxHealth)
	if health == maxHealth then
		return "∞%"
	else
		local amount = math.floor(health / maxHealth * 100)
		return amount .. "%"
	end
end

local function makeHpIndicator(character: Model, humanoid: Humanoid)
	local indicator = hpIndicator:Clone()
	indicator.Parent = character.HumanoidRootPart

	local amountLabel = indicator.Amount
	humanoid.HealthChanged:Connect(function(health: number)
		amountLabel.Text = calculatePercentage(health, humanoid.MaxHealth)
	end)
	humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(function()
		amountLabel.Text = calculatePercentage(humanoid.Health, humanoid.MaxHealth)
	end)
end

local function prepareHumanoid(character: Model)
	local humanoid = character.Humanoid
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None

	makeHpIndicator(character, humanoid)
	
	return humanoid
end

--// MODULE FUNCTIONS
return {
	Make = function(data: {}, cframe: CFrame)
		local character = data.Character:Clone()
		character:PivotTo(cframe)
	
		BodyMover.CreateAttachment(character)
		local humanoid = prepareHumanoid(character)
	
		return character, humanoid
	end
}