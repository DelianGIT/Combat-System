--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

--// VARIABLES
local player = Players.LocalPlayer

local blockIndicator = ReplicatedStorage.Gui.BlockIndicator
local background = blockIndicator.Background
local bar = background.Bar

local remoteEvents = ReplicatedStorage.Events
local remoteEvent = require(remoteEvents.BlockIndicator):Client()

local backgroundColor = Color3.new(0.196078, 0.196078, 0.196078)
local barColor = Color3.new(1, 1, 1)
local perfectBlockColor = Color3.new(0.5, 0, 1)
local blockBreakColor = Color3.new(0.196078, 0, 0)

local oneSize = UDim2.fromScale(1, 1)
local zeroSize = UDim2.fromScale(0.25, 0)
local mainSize = UDim2.fromScale(0.25, 4)

local enableDisableTweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
local perfectBlockTweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0, true)
local blockBreakTweenInfo1 = TweenInfo.new(0.15, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
local blockBreakTweenInfo2 = TweenInfo.new(0.5, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)

local durability = 0
local maxDurability = 0

local eventFunctions = {}

--// EVENT FUNCTIONS
function eventFunctions.Enable(blockDurability: number)
	local character = player.Character
	if not character then return end

	durability = blockDurability
	maxDurability = blockDurability

	background.BackgroundColor3 = backgroundColor
	bar.BackgroundColor3 = barColor
	bar.Size = oneSize
	blockIndicator.Size = zeroSize
	blockIndicator.Parent = character.HumanoidRootPart

	TweenService:Create(blockIndicator, enableDisableTweenInfo, {
		Size = mainSize
	}):Play()
end

function eventFunctions.Disable()
	local character = player.Character
	if not character then return end

	local tween = TweenService:Create(blockIndicator, enableDisableTweenInfo, {
		Size = zeroSize
	})
	tween.Completed:Once(function(playbackState: Enum.PlaybackState)
		if playbackState == Enum.PlaybackState.Completed then
			blockIndicator.Parent = nil
		end
	end)
	tween:Play()
end

function eventFunctions.SetDurability(value: number)
	durability = value
	bar.Size = UDim2.fromScale(1, durability / maxDurability)
end

function eventFunctions.PerfectBlock()
	TweenService:Create(bar, perfectBlockTweenInfo, {
		BackgroundColor3 = perfectBlockColor,
	}):Play()
	TweenService:Create(background, perfectBlockTweenInfo, {
		BackgroundColor3 = perfectBlockColor,
	}):Play()
end

function eventFunctions.BlockBreak()
	eventFunctions.ChangeDurability(0)

	TweenService:Create(background, blockBreakTweenInfo1, {
		BackgroundColor3 = blockBreakColor,
	}):Play()

	local tween = TweenService:Create(blockIndicator, blockBreakTweenInfo2, {
		Size = zeroSize
	})
	tween.Completed:Once(function(playbackState: Enum.PlaybackState)
		if playbackState == Enum.PlaybackState.Completed then
			blockIndicator.Parent = nil
		end
	end)
	tween:Play()
end

--// EVENTS
remoteEvent:On(function(action: string, ...: any)
	eventFunctions[action](...)
end)

return true