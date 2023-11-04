--// SERVICES
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

--// TYPES
type Skill = {
	Keybind: Enum.KeyCode | Enum.UserInputType,
	Frame: Frame,
	Cooldown: {
		Pressed: boolean,
		Frame: Frame,
		Label: TextLabel,
		LeftGradient: UIGradient,
		RightGradient: UIGradient,
	},
	KeybindStroke: UIStroke,
	NameStroke: UIStroke,
	NameGradient: UIGradient,
}
type GuiList = {
	List: Frame,
	Skills: { [string]: Skill },

	Open: (self: GuiList) -> (),
	Close: (self: GuiList) -> (),
	Pressed: (self: GuiList, skillName: string) -> (),
	Unpressed: (self: GuiList, skillName: string) -> (),
	Started: (self: GuiList, skillName: string, identifier: string) -> (),
	Finished: (self: GuiList, identifier: string) -> (),
	StartCooldown: (self: GuiList, skillName: string, duration: number) -> (),
	AddSkill: (self: GuiList, skillName: string, keybind: Enum.KeyCode | Enum.UserInputType) -> (),
}

--// CLASSES
local GuiList: GuiList = {}
GuiList.__index = GuiList

--// VARIABLES
local player = Players.LocalPlayer

local guiFolder = ReplicatedStorage.Gui.SkillsList
local listTemplate = guiFolder.ListTemplate
local skillTemplate = guiFolder.SkillTemplate

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SkillsLists"
screenGui.ResetOnSpawn = false

local closedPosition = UDim2.fromScale(1, 0.935) --UDim2.fromScale(1, 0.5)
local openedPosition = UDim2.fromScale(0.835, 0.935) --UDim2.fromScale(0.837, 0.5)
local cooldownSize = UDim2.fromScale(0.15, 0.9)
local zeroSize = UDim2.fromScale(0, 0)

local redColor = Color3.new(1, 0, 0)
local greenColor = Color3.new(0, 1, 0)

local pressedTweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
local unpressedTweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.In)
local activationTweenInfo1 = TweenInfo.new(0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.In)

local keybindNames = {
	[Enum.UserInputType.MouseButton1] = "MB1",
	[Enum.UserInputType.MouseButton2] = "MB2",
	[Enum.KeyCode.LeftShift] = "Shift",
	[Enum.KeyCode.LeftControl] = "Ctrl",
}
local activeSkills = {}

--// MODULE FUNCTIONS
function GuiList:Open()
	for skillName, properties in self.Skills do
		if not properties.Pressed then
			continue
		end

		local keybind = properties.Keybind
		local keybindType = keybind.EnumType

		if
			keybindType == Enum.KeyCode and not UserInputService:IsKeyDown(keybind)
			or not UserInputService:IsMouseButtonPressed(keybind)
		then
			self:Unpressed(skillName)
		end
	end

	self.List:TweenPosition(openedPosition, Enum.EasingDirection.In, Enum.EasingStyle.Quad, 0.3, true)
end

function GuiList:Close()
	self.List:TweenPosition(closedPosition, Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.3, true)
end

function GuiList:Pressed(skillName: string)
	self.Skills[skillName].Pressed = true

	local uiStroke = self.Skills[skillName].KeybindStroke
	TweenService:Create(uiStroke, pressedTweenInfo, {
		Thickness = 3,
	}):Play()
end

function GuiList:Unpressed(skillName: string)
	self.Skills[skillName].Pressed = false

	local uiStroke = self.Skills[skillName].KeybindStroke
	TweenService:Create(uiStroke, unpressedTweenInfo, {
		Thickness = 0,
	}):Play()
end

function GuiList:Started(skillName: string, identifier: string)
	local skill = self.Skills[skillName]
	local stroke = skill.NameStroke

	TweenService:Create(stroke, activationTweenInfo1, {
		Thickness = 3,
	}):Play()

	local uiGradient = skill.NameGradient
	uiGradient.Rotation = -180

	local connection
	connection = RunService.Heartbeat:Connect(function(deltaTime: number)
		local rotation = uiGradient.Rotation + (60 * deltaTime) * 3
		uiGradient.Rotation = if math.clamp(rotation, -180, 180) % 180 == 0 then -180 else rotation
	end)

	activeSkills[identifier] = {
		Stroke = stroke,
		Connection = connection,
	}
end

function GuiList:Finished(identifier: string)
	local activeSkill = activeSkills[identifier]

	activeSkill.Connection:Disconnect()

	local stroke = activeSkill.Stroke
	TweenService:Create(stroke, activationTweenInfo1, {
		Thickness = 0,
	}):Play()

	activeSkills[identifier] = nil
end

function GuiList:StartCooldown(skillName: string, duration: number)
	if duration <= 0 then
		return
	end

	local cooldown = self.Skills[skillName].Cooldown
	local frame = cooldown.Frame
	local label = cooldown.Label
	local leftGradient = cooldown.LeftGradient
	local rightGradient = cooldown.RightGradient

	rightGradient.Rotation = -180
	leftGradient.Rotation = 0

	local colorSequence = ColorSequence.new(redColor)
	leftGradient.Color = colorSequence
	rightGradient.Color = colorSequence

	frame:TweenSize(cooldownSize, Enum.EasingDirection.Out, Enum.EasingStyle.Elastic, 0.5, true)

	local startTime = os.clock()
	local alphaStep = 1 / (60 * duration)
	local alpha = 0
	local rotationStep = 180 / (30 * duration)
	local side = true
	local connection
	connection = RunService.Heartbeat:Connect(function(deltaTime: number)
		local stabilizer = 60 * deltaTime

		if alpha >= 1 then
			connection:Disconnect()

			label.Text = 0

			rightGradient.Rotation = 0
			leftGradient.Rotation = 180

			colorSequence = ColorSequence.new(greenColor)
			leftGradient.Color = colorSequence
			rightGradient.Color = colorSequence

			frame:TweenSize(zeroSize, Enum.EasingDirection.In, Enum.EasingStyle.Linear, 0.2, true)
		else
			local passedTime = os.clock() - startTime
			label.Text = math.floor((duration - passedTime) * 10) / 10

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

			colorSequence = ColorSequence.new(redColor:Lerp(greenColor, alpha))
			leftGradient.Color = colorSequence
			rightGradient.Color = colorSequence

			alpha += alphaStep * stabilizer
		end
	end)
end

function GuiList:AddSkill(skillName: string, keybind: Enum.KeyCode | Enum.UserInputType, layoutOrder: number)
	local skill = skillTemplate:Clone()
	skill.Name = skillName
	skill.LayoutOrder = layoutOrder
	skill.SkillName.Value.Text = skillName

	local keybindFrame = skill.Keybind
	keybindFrame.Value.Text = keybindNames[keybind] or keybind.Name

	skill.Visible = true
	skill.Parent = self.List

	local nameStroke = skill.SkillName.UIStroke
	local cooldownFrame = skill.Cooldown
	self.Skills[skillName] = {
		Keybind = keybind,
		Frame = skill,
		Cooldown = {
			Frame = cooldownFrame,
			Label = cooldownFrame.Value.TextLabel,
			LeftGradient = cooldownFrame.Left.Frame.UIGradient,
			RightGradient = cooldownFrame.Right.Frame.UIGradient,
			Pressed = {},
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
			Skills = {},
		}, GuiList)

		return guiList
	end,
}
