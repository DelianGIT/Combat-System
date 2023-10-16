--// SERVICES
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

--// VARIABLES
local player = Players.LocalPlayer
local playerGui = player.PlayerGui

local screenGui = playerGui:WaitForChild("DamageIndicator")
local mainFrame = screenGui.Main
local damageLabel = mainFrame.Damage
local damageStroke = damageLabel.UIStroke
local hitsLabel = mainFrame.Hits
local hitsStroke = hitsLabel.UIStroke
local timerFrame = mainFrame.Timer

local startTimerSize = UDim2.fromScale(1.25, 0.083)
local endTimerSize = UDim2.fromScale(0, 0.083)
local startMainFrameSize = UDim2.fromScale(0.104, 0.148)
local endMainFrameSize = UDim2.fromScale(0.13, 0.185)

local transparencyTweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.In)
local timerTweenInfo = TweenInfo.new(2, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
local mainFrameTweenInfo = TweenInfo.new(0.05, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 0, true)

local hitsAmount = 0
local damageAmount = 0
local rotationSign = 1

local active = false

--// FUNCTIONS
local function tweenTransparency(value: number)
	TweenService:Create(damageLabel, transparencyTweenInfo, {
		TextTransparency = value,
	}):Play()
	TweenService:Create(damageStroke, transparencyTweenInfo, {
		Transparency = value,
	}):Play()
	TweenService:Create(hitsLabel, transparencyTweenInfo, {
		TextTransparency = value,
	}):Play()
	TweenService:Create(hitsStroke, transparencyTweenInfo, {
		Transparency = value,
	}):Play()
	TweenService:Create(timerFrame, transparencyTweenInfo, {
		BackgroundTransparency = value,
	}):Play()
end

local function changeLabels(amount: number)
	hitsAmount += 1
	hitsLabel.Text = hitsAmount .. " Hits"

	damageAmount += amount
	damageLabel.Text = damageAmount
end

local function updateTimer()
	timerFrame.Size = startTimerSize

	local timerTween = TweenService:Create(timerFrame, timerTweenInfo, {
		Size = endTimerSize
	})
	timerTween.Completed:Once(function(playbackState: Enum.PlaybackState)
		if playbackState == Enum.PlaybackState.Completed then
			tweenTransparency(1)
			active = false
			hitsAmount = 0
			damageAmount = 0
		end
	end)
	timerTween:Play()
end

local function updateSize()
	mainFrame.Size = startMainFrameSize
	TweenService:Create(mainFrame, mainFrameTweenInfo, {
		Size = endMainFrameSize,
	}):Play()
end

local function changeRotation()
	rotationSign *= -1
	mainFrame.Rotation = math.random(1, 15) * rotationSign
end

--// MODULE FUNCTION
return function(amount: number)
	if not active then
		tweenTransparency(0)
		active = true
	end

	changeLabels(amount)
	updateTimer()
	updateSize()
	changeRotation()
end