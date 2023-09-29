--SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

--// VARIABLES
local billboardGuiPart = ReplicatedStorage.Gui.DamageIndicator

local amountLabelTweenInfo1 = TweenInfo.new(1, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out)
local amountLabelTweenInfo2 = TweenInfo.new(0.5, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0, false, 1)

local amountLabelSize = UDim2.fromScale(1, 1)
local zeroSize = UDim2.fromScale(0, 0)

local attackersPastInfo = {}

--// FUNCTIONS
local function getOffset()
	return Vector3.new(math.random(-20, 20) / 10, math.random(-20, 20) / 10, 0)
end

local function prepareGui(guiPart: Part, amountLabel: TextLabel, dealtDamage: number, target: Model)
	amountLabel.Text = "-" .. dealtDamage
	amountLabel.Rotation = math.random(-200, 200) / 10
	amountLabel.Size = zeroSize
	guiPart.Position = target.HumanoidRootPart.Position + getOffset()
	guiPart.Parent = target
end

local function startTweens(guiPart: Part, amountLabel: TextLabel, attacker: Players | Model)
	amountLabel.Size = zeroSize

	local tween = TweenService:Create(amountLabel, amountLabelTweenInfo1, {
		Size = amountLabelSize
	})

	tween.Completed:Once(function(playbackState1: Enum.PlaybackState)
		if playbackState1 ~= Enum.PlaybackState.Completed then return end

		tween = TweenService:Create(amountLabel, amountLabelTweenInfo2, {
			Size = zeroSize
		})

		tween.Completed:Once(function(playbackState2: Enum.PlaybackState)
			if playbackState2 ~= Enum.PlaybackState.Completed then return end
			guiPart:Destroy()
			attackersPastInfo[attacker] = nil
		end)

		tween:Play()
	end)

	tween:Play()
end

--// MODULE FUNCTION
return function(attacker: Player | Model, target: Model, amount: number)
	local guiPart, dealtDamage
	local pastInfo = attackersPastInfo[attacker]
	if pastInfo then
		pastInfo[2] += amount
		guiPart, dealtDamage = table.unpack(pastInfo)
	else
		guiPart = billboardGuiPart:Clone()
		dealtDamage = amount
		pastInfo = {guiPart, dealtDamage}
		attackersPastInfo[attacker] = pastInfo
	end

	local amountLabel = guiPart.BillboardGui.Amount
	prepareGui(guiPart, amountLabel, dealtDamage, target)

	startTweens(guiPart, amountLabel, attacker)
end