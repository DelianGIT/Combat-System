--SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

--// VARIABLES
local ignoreFolder = workspace.Ignore

local damageIndicator = ReplicatedStorage.Gui.DamageIndicator

local spawnSize = UDim2.fromScale(1.5, 1.5)
local zeroSize = UDim2.fromScale(0, 0)

local offset = Vector3.new(0, 5, 0)

local spawnTweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out, 0, true)
local offsetTweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
local disappearTweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0, false, 0.35)

--// FUNCTIONS
local function doTweens(_: Part, billboardGui: BillboardGui)
	TweenService:Create(billboardGui, spawnTweenInfo, {
		Size = spawnSize
	}):Play()

	TweenService:Create(billboardGui, disappearTweenInfo, {
		Size = zeroSize
	}):Play()

	local tween = TweenService:Create(billboardGui, offsetTweenInfo, {
		StudsOffsetWorldSpace = offset
	})
	tween.Completed:Once(function()
		billboardGui:Destroy()
	end)
	tween:Play()
end

local function getRandomOffset()
	local x = math.random(-2, 2)
	-- local y = math.random(-5, 5)
	local z = math.random(-2, 2)
	return CFrame.new(x, 0, z)
end

--// MODULE FUNCTION
return function(target: Model, amount: number)
	local part = damageIndicator:Clone()
	part.CFrame = target.HumanoidRootPart.CFrame * getRandomOffset()

	local billboardGui = part.BillboardGui
	local label = billboardGui.Amount
	label.Text = "-" .. amount
	label.Rotation = math.random(-2.5, 2.5) * 10

	part.Parent = ignoreFolder
	doTweens(part, billboardGui)
end