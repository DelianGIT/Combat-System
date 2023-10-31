--SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
-- local RunService = game:GetService("RunService")

--// CONFIG
local LIFETIME = 2

--// VARIABLES
local ignoreFolder = workspace.Ignore

local damageIndicator = ReplicatedStorage.Gui.DamageIndicator
local label = damageIndicator.BillboardGui.Amount

local oneSize = UDim2.fromScale(1, 1)
local zeroSize = UDim2.fromScale(0, 0)

local spawnTweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out)
local disappearTweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)

local hitTime = 0
local damageAmount = 0

--// FUNCTIONS
local function getRandomOffset()
	local x = math.random(-20, 20) / 10
	local y = math.random(-20, 20) / 19
	return CFrame.new(x, y, 0)
end

local function getRandomRotation()
	local sign = if math.random(0, 1) == 0 then -1 else 1
	return math.random(10, 25) * sign
end

--// MODULE FUNCTION
return function(humanoidRootPart: Part, amount: number)
	damageAmount += amount
	label.Text = "-" .. damageAmount
	label.Rotation = getRandomRotation()
	label.Size = zeroSize

	TweenService:Create(label, spawnTweenInfo, {
		Size = oneSize,
	}):Play()

	local startTime = os.clock()
	hitTime = startTime
	task.delay(LIFETIME, function()
		if hitTime == startTime then
			damageAmount = 0
			local tween = TweenService:Create(label, disappearTweenInfo, {
				Size = zeroSize,
			})
			tween.Completed:Once(function(playbackState: Enum.PlaybackState)
				if playbackState == Enum.PlaybackState.Completed then
					damageIndicator.Parent = nil
				end
			end)
			tween:Play()
		end
	end)

	damageIndicator.CFrame = humanoidRootPart.CFrame * getRandomOffset()
	if damageIndicator.Parent ~= ignoreFolder then
		damageIndicator.Parent = ignoreFolder
	end
end
