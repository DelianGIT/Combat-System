--// SERVICES
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

--// CLASSES
local GuiList = {}
GuiList.__index = GuiList

--// VARIABLES
local player = Players.LocalPlayer

local guiFolder = ReplicatedStorage.Gui.SkillsList
local listTemplate = guiFolder.ListTemplate
local skillTemplate = guiFolder.SkillTemplate

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SkillsLists"
screenGui.ResetOnSpawn = false

local closedPosition = UDim2.fromScale(1, 0.5)
local openedPosition = UDim2.fromScale(0.837, 0.5)
local cooldownSize = UDim2.fromScale(0.15, 0.9)
local zeroSize = UDim2.fromScale(0, 0)

local startVector2 = Vector2.new(-1, 0)
local endVector2 = Vector2.new(1, 0)

local redColor = Color3.new(1, 0, 0)
local greenColor = Color3.new(0, 1, 0)

local pressedTweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
local unpressedTweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.In)
local activationTweenInfo1 = TweenInfo.new(0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.In)
local activationTweenInfo2 = TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.In, math.huge)

local activeSkills = {}

--// MODULE FUNCTIONS
function GuiList:Open()
	self.List:TweenPosition(openedPosition, Enum.EasingDirection.In, Enum.EasingStyle.Quad, 0.3, true)
end

function GuiList:Close()
	self.List:TweenPosition(closedPosition, Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.3, true)
end

function GuiList:Pressed(skillName: string)
	local uiStroke = self.Skills[skillName].KeybindStroke
	TweenService:Create(uiStroke, pressedTweenInfo, {
		Thickness = 3,
	}):Play()
end

function GuiList:Unpressed(skillName: string)
	local uiStroke = self.Skills[skillName].KeybindStroke
	TweenService:Create(uiStroke, unpressedTweenInfo, {
		Thickness = 0,
	}):Play()
end

function GuiList:Started(skillName: string, identifier: string)
	local skill = self.Skills[skillName]
	local stroke = skill.NameStroke

	TweenService:Create(stroke, activationTweenInfo1, {
		Thickness = 3
	}):Play()

	local uiGradient = skill.NameGradient
	uiGradient.Offset = startVector2

	local tween = TweenService:Create(uiGradient, activationTweenInfo2, {
		Offset = endVector2
	})
	tween:Play()

	activeSkills[identifier] = {
		Stroke = stroke,
		Tween = tween
	}
end

function GuiList:Ended(identifier: string)
	local activeSkill = activeSkills[identifier]

	local tween = activeSkill.Tween
	tween:Cancel()

	local stroke = activeSkill.Stroke
	TweenService:Create(stroke, activationTweenInfo1, {
		Thickness = 0
	}):Play()

	activeSkills[identifier] = nil
end

function GuiList:StartCooldown(skillName: string, duration: number)
	if duration <= 0 then return end

	local cooldown = self.Skills[skillName].Cooldown
	local frame = cooldown.Frame
	local value = cooldown.Value
	local leftGradient = cooldown.LeftGradient
	local rightGradient = cooldown.RightGradient

	frame:TweenSize(cooldownSize, Enum.EasingDirection.Out, Enum.EasingStyle.Elastic, 0.5, true)
	
	local startTime = os.clock()
	local alphaStep = 1 / (60 * duration)
	local alpha = 0
	local rotationStep = 180 / (30 * duration)
	local side = true

	local connection
	connection = RunService.Heartbeat:Connect(function(deltaTime: number)
		local stabilizer = 60 * deltaTime

		local passedTime = os.clock() - startTime
		if passedTime >= duration then
			connection:Disconnect()
			
			value.Text = 0

			rightGradient.Rotation = 0
			leftGradient.Rotation = 180
			
			local colorSequence = ColorSequence.new(greenColor)
			leftGradient.Color = colorSequence
			rightGradient.Color = colorSequence

			frame:TweenSize(zeroSize, Enum.EasingDirection.In, Enum.EasingStyle.Linear, 0.2, true, function()
				rightGradient.Rotation = -180
				leftGradient.Rotation = 0

				colorSequence = ColorSequence.new(redColor)
				leftGradient.Color = colorSequence
				rightGradient.Color = colorSequence
			end)
		else
			value.Text = math.floor((duration - passedTime) * 10) / 10

			if side then
				if rightGradient.Rotation < 0 then
					rightGradient.Rotation += rotationStep * stabilizer
				else
					rightGradient.Rotation = 0
					side = false
				end
			else
				if leftGradient.Rotation < 180 then
					leftGradient.Rotation += rotationStep * stabilizer
				else
					leftGradient.Rotation = 180
				end
			end

			local colorSequence = ColorSequence.new(redColor:Lerp(greenColor, alpha))
			leftGradient.Color = colorSequence
			rightGradient.Color = colorSequence

			alpha += alphaStep * stabilizer
		end
	end)
end

function GuiList:AddSkill(skillName: string, keybind: Enum.KeyCode | Enum.UserInputType)
	local skill = skillTemplate:Clone()
	skill.Name = skillName
	skill.SkillName.Value.Text = skillName

	local keybindFrame = skill.Keybind
	if keybind == Enum.UserInputType.MouseButton1 then
		keybindFrame.Value.Text = "MB1"
	elseif keybind == Enum.UserInputType.MouseButton2 then
		keybindFrame.Value.Text = "MB2"
	else
		keybindFrame.Value.Text = keybind.Name
	end
		
	skill.Visible = true
	skill.Parent = self.List

	local nameStroke = skill.SkillName.UIStroke
	local cooldownFrame = skill.Cooldown
	self.Skills[skillName] = {
		Frame = skill,
		Cooldown = {
			Frame = cooldownFrame,
			Value = cooldownFrame.Value.Value,
			LeftGradient = cooldownFrame.Left.Frame.UIGradient,
			RightGradient = cooldownFrame.Right.Frame.UIGradient
		},
		KeybindStroke = keybindFrame.UIStroke,
		NameStroke = nameStroke,
		NameGradient = nameStroke.UIGradient,
	}
	
	return skill
end

--// EVENTS
player.CharacterAdded:Once(function()
	screenGui.Parent = player.PlayerGui
end)

--// MODULE FUNCTIONS
return {
	new = function(packName: string)
		local list = listTemplate:Clone()
		list.Name = packName
		list.Visible = true
		list.Parent = screenGui
	
		local guiList = setmetatable({
			List = list,
			Skills = {}
		}, GuiList)

		return guiList
	end
}