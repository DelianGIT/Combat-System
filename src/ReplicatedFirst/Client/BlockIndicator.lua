--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

--// PACKAGES
local Packages = ReplicatedStorage.Packages
local Red = require(Packages.Red)

--// VARIABLES
local player = Players.LocalPlayer

local blockIndicator = ReplicatedStorage.Gui.BlockIndicator
local background = blockIndicator.Background
local bar = background.Bar

local remoteEvent = Red.Client("BlockIndicator")

local mainColor = Color3.new(1, 1, 1)
local perfectBlockColor = Color3.new(0.5, 0, 1)
local breakBlockColor = Color3.new(1, 0, 0)

local oneSize = UDim2.fromScale(1, 1)
local zeroSize = UDim2.fromScale(0.25, 0)
local mainSize = UDim2.fromScale(0.25, 4)

local enableDisableTweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
local perfectBlockTweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0, true)
local breakBlockTweenInfo1 = TweenInfo.new(0.15, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
local breakBlockTweenInfo2 = TweenInfo.new(0.5, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)

local durability = 0
local maxDurability = 0

--// FUNCTIONS
local function enable(blockDurability: number)
	local character = player.Character
	if not character then return end

	durability = blockDurability
	maxDurability = blockDurability

	bar.BackgroundColor3 = mainColor
	bar.Size = oneSize
	background.BackgroundColor3 = mainColor
	blockIndicator.Size = zeroSize
	blockIndicator.Parent = character.HumanoidRootPart

	TweenService:Create(blockIndicator, enableDisableTweenInfo, {
		Size = mainSize
	}):Play()
end

local function disable()
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

local function changeDurability(value: number)
	durability = value
	bar.Size = UDim2.fromScale(1, durability / maxDurability)
end

local function perfectBlock()
	TweenService:Create(bar, perfectBlockTweenInfo, {
		BackgroundColor3 = perfectBlockColor,
	}):Play()
	TweenService:Create(background, perfectBlockTweenInfo, {
		BackgroundColor3 = perfectBlockColor,
	}):Play()
end

local function blockBreak()
	changeDurability(0)

	TweenService:Create(bar, breakBlockTweenInfo1, {
		BackgroundColor3 = breakBlockColor,
	}):Play()
	TweenService:Create(background, breakBlockTweenInfo1, {
		BackgroundColor3 = breakBlockColor,
	}):Play()

	local tween = TweenService:Create(blockIndicator, breakBlockTweenInfo2, {
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
remoteEvent:On("Enable", enable)
remoteEvent:On("Disable", disable)
remoteEvent:On("ChangeDurability", changeDurability)
remoteEvent:On("PerfectBlock", perfectBlock)
remoteEvent:On("BlockBreak", blockBreak)

return true