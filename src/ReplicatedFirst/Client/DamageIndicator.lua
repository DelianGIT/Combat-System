--SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

--// PACKAGES
local Packages = ReplicatedStorage.Packages
local Red = require(Packages.Red)

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

local highlight = Instance.new("Highlight")
highlight.FillColor = Color3.new(1, 0, 0)
highlight.FillTransparency = 1
highlight.OutlineTransparency = 1

local transparencyTweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.In)
local timerTweenInfo = TweenInfo.new(1.5, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
local highlightTweenInfo = TweenInfo.new(0.05, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 0, true)
local mainTweenInfo = TweenInfo.new(0.05, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 0, true)

local startTimerSize = UDim2.fromScale(1.25, 0.083)
local endTimerSize = UDim2.fromScale(0, 0.083)
local startMainFrameSize = UDim2.fromOffset(200, 120)
local endMainFrameSize = UDim2.fromOffset(250, 150)

local remoteEvent = Red.Client("DamageIndicator")

local hitsAmount = 0
local damageAmount = 0
local sign = 1

local guiActive = false

local timerTween, timerTweenConnection
local mainTween, mainTweenConnection

--// HIGHLIGHT FUNCTIONS
local function doHighlight(character: Model)
	local newHighlight = highlight:Clone()
	newHighlight.Parent = character

	TweenService:Create(newHighlight, highlightTweenInfo, {
		FillTransparency = 0.5
	}):Play()

	task.delay(0.1, function()
		newHighlight:Destroy()
	end)
end

--// SCREEN GUI FUNCTIONS
local function tweenTransparency(value: number)
	TweenService:Create(damageLabel, transparencyTweenInfo, {
		TextTransparency = value
	}):Play()
	TweenService:Create(damageStroke, transparencyTweenInfo, {
		Transparency = value
	}):Play()
	TweenService:Create(hitsLabel, transparencyTweenInfo, {
		TextTransparency = value
	}):Play()
	TweenService:Create(hitsStroke, transparencyTweenInfo, {
		Transparency = value
	}):Play()
	TweenService:Create(timerFrame, transparencyTweenInfo, {
		BackgroundTransparency = value
	}):Play()
end

local function startTimer()
	if timerTween then
		timerTweenConnection:Disconnect()
		timerTween:Cancel()
	end
	timerFrame.Size = startTimerSize

	timerTween = TweenService:Create(timerFrame, timerTweenInfo, {
		Size = endTimerSize
	})
	timerTweenConnection = timerTween.Completed:Connect(function()
		timerTweenConnection:Disconnect()
		timerTweenConnection = nil
		timerTween = nil

		tweenTransparency(1)
		guiActive = false
		hitsAmount = 0
		damageAmount = 0
	end)

	timerTween:Play()
end

local function changeLabels(amount: number)
	hitsAmount += 1
	hitsLabel.Text = hitsAmount .. " Hits"

	damageAmount += amount
	damageLabel.Text = damageAmount
end

local function changeSize()
	if mainTween then
		mainTweenConnection:Disconnect()
		mainTween:Cancel()
	end
	mainFrame.Size = startMainFrameSize

	mainTween = TweenService:Create(mainFrame, mainTweenInfo, {
		Size = endMainFrameSize
	})
	mainTweenConnection = mainTween.Completed:Connect(function()
		mainTweenConnection:Disconnect()
		mainTweenConnection = nil
		mainTween = nil
	end)

	mainTween:Play()
end

local function changeRotation()
	sign *= -1
	mainFrame.Rotation = math.random(1, 10) * sign
end

local function doScreenGui(amount: number)
	if not guiActive then
		tweenTransparency(0)
		guiActive = true
	end

	startTimer()
	changeLabels(amount)
	changeSize()
	changeRotation()
end

--// EVENTS
remoteEvent:On("Hit", function(character: Model, amount: number)
	doHighlight(character)
	doScreenGui(amount)
end)

return true