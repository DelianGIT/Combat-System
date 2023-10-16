--// SERVICES
local TweenService = game:GetService("TweenService")

--// VARIABLES
local camera = workspace.CurrentCamera

local startTweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local endTweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

--// SKILL
local data = {
	InputKey = Enum.KeyCode.W,
	InputState = "DoubleClick",
	ClickFrame = 0.25,
	HasEnd = true
}

local functions = {
	Start = function()
		TweenService:Create(camera, startTweenInfo, {
			FieldOfView = 90
		}):Play()
	end,

	End = function()
		TweenService:Create(camera, endTweenInfo, {
			FieldOfView = 70
		}):Play()
	end
}
functions.Interrupt = functions.End

return {
	Data = data,
	Functions = functions
}