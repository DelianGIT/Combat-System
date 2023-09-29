--// SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

--// VARIABLES
local player = Players.LocalPlayer

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SkillsLists"
screenGui.ResetOnSpawn = false

local guiFolder = ReplicatedStorage.Gui.SkillsList
local listTemplate = guiFolder.ListTemplate
local skillTemplate = guiFolder.SkillTemplate

local closedPosition = UDim2.fromScale(1, 0.5)
local openedPosition = UDim2.fromScale(0.837, 0.5)
local cooldownSize = UDim2.fromScale(0.15, 0.9)
local zeroSize = UDim2.fromScale(0, 0)

local redColor = Color3.new(1, 0, 0)
local greenColor = Color3.new(0, 1, 0)

local pressedTweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
local unpressedTweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.In)
local activationTweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.In)

local startVector2 = Vector2.new(-1, 0)
local endVector2 = Vector2.new(1, 0)

local GuiLists = {}

local activeSkillGradient, activeSkill

--// FUNCTIONS
local function tweenColorSequence(leftGradient: UIGradient, rightGradient: UIGradient, duration: number)
	local alphaStep = 1 / (60 * duration)
	local alpha = 0

	local connection
	connection = RunService.Heartbeat:Connect(function(deltaTime: number)
		if alpha >= 1 then
			connection:Disconnect()

			local colorSequence = ColorSequence.new(greenColor)
			leftGradient.Color = colorSequence
			rightGradient.Color = colorSequence
		else
			local colorSequence = ColorSequence.new(redColor:Lerp(greenColor, alpha))
			leftGradient.Color = colorSequence
			rightGradient.Color = colorSequence

			alpha += alphaStep * (60 * deltaTime)
		end
	end)
end

local function startCircularProgressBar(leftGradient: UIGradient, rightGradient: UIGradient, duration: number)
	local halfDuration = duration / 2

	tweenColorSequence(leftGradient, rightGradient, duration)

	local rightTween = TweenService:Create(rightGradient, TweenInfo.new(halfDuration, Enum.EasingStyle.Linear, Enum.EasingDirection.In), {
		Rotation = 0
	})

	rightTween.Completed:Once(function()
		TweenService:Create(leftGradient, TweenInfo.new(halfDuration, Enum.EasingStyle.Linear, Enum.EasingDirection.In), {
			Rotation = 180
		}):Play()
	end)

	rightTween:Play()
end

local function startActivationTween(uiGradient)
	if activeSkill then
		uiGradient.Offset = startVector2
		local tween = TweenService:Create(uiGradient, TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.In), {
			Offset = endVector2
		})

		tween.Completed:Once(function()
			startActivationTween(uiGradient)
		end)

		tween:Play()
	end
end

--// MODULE FUNCTIONS
function GuiLists.Create(packName: string)
	local list = listTemplate:Clone()
	list.Name = packName
	list.Visible = true
	list.Parent = screenGui

	return list
end

function GuiLists.Destroy(list: Frame)
	if activeSkill and activeSkill:IsDescendantOf(list) then
		activeSkill = nil
	end
	if activeSkillGradient and activeSkillGradient:IsDescendantOf(list) then
		activeSkillGradient = nil
	end
end

function GuiLists.Open(list: Frame)
	list:TweenPosition(openedPosition, Enum.EasingDirection.In, Enum.EasingStyle.Quad, 0.3, true)
end

function GuiLists.Close(list: Frame)
	list:TweenPosition(closedPosition, Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.3, true)
end

function GuiLists.AddSkill(list: Frame, skillName: string, keybind: Enum.KeyCode | Enum.UserInputType)
	local skill = skillTemplate:Clone()
	skill.Name = skillName
	skill.SkillName.Value.Text = skillName
	if keybind == Enum.UserInputType.MouseButton1 then
		skill.Keybind.Value.Text = "MB1"
	elseif keybind == Enum.UserInputType.MouseButton2 then
		skill.Keybind.Value.Text = "MB2"
	else
		skill.Keybind.Value.Text = keybind.Name
	end
	skill.Visible = true
	skill.Parent = list
	return skill
end

function GuiLists.StartCooldown(skill: Frame, duration: number)
	local cooldown = skill.Cooldown
	local cooldownValue = cooldown.Value.Value
	local leftGradient = cooldown.Left.Frame.UIGradient
	local rightGradient = cooldown.Right.Frame.UIGradient

	cooldown:TweenSize(cooldownSize, Enum.EasingDirection.Out, Enum.EasingStyle.Elastic, 0.5, true)

	local startTime = tick()
	local connection
	connection = RunService.Heartbeat:Connect(function()
		local passedTime = tick() - startTime
		if passedTime >= duration then
			connection:Disconnect()

			cooldownValue.Text = 0
			cooldown:TweenSize(zeroSize, Enum.EasingDirection.In, Enum.EasingStyle.Linear, 0.2, true, function()
				leftGradient.Rotation = 0
				rightGradient.Rotation = -180

				local colorSequence = ColorSequence.new(redColor)
				leftGradient.Color = colorSequence
				rightGradient.Color = colorSequence
			end)
		else
			cooldownValue.Text = math.floor((duration - passedTime) * 10) / 10
		end
	end)

	startCircularProgressBar(leftGradient, rightGradient, duration)
end

function GuiLists.Pressed(uiStroke: UIStroke)
	TweenService:Create(uiStroke, pressedTweenInfo, {
		Thickness = 3
	}):Play()
end

function GuiLists.Unpressed(uiStroke: UIStroke)
	TweenService:Create(uiStroke, unpressedTweenInfo, {
		Thickness = 0
	}):Play()
end

function GuiLists.Started(skillFrame: Frame)
	local gradient = skillFrame.SkillName.UIStroke.UIGradient
	activeSkillGradient = gradient
	activeSkill = skillFrame

	TweenService:Create(gradient.Parent, activationTweenInfo, {
		Thickness = 3
	}):Play()
	
	startActivationTween(gradient)
end

function GuiLists.Ended()
	activeSkill = nil

	TweenService:Create(activeSkillGradient.Parent, activationTweenInfo, {
		Thickness = 0
	}):Play()

	activeSkillGradient = nil
end

--// EVENTS
player.CharacterAdded:Once(function()
	screenGui.Parent = player.PlayerGui
end)

return GuiLists