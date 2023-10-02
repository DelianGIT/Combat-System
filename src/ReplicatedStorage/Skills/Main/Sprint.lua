--// SERVICES
local TweenService = game:GetService("TweenService")

--// VARIABLES
local camera = workspace.CurrentCamera

local startTweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local endTweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

--// FUNCTIONS
local function startFunction()
	TweenService:Create(camera, startTweenInfo, {
		FieldOfView = 90
	}):Play()
end

local function endFunction()
	TweenService:Create(camera, endTweenInfo, {
		FieldOfView = 70
	}):Play()
end

return {
	Start = startFunction,
	End = endFunction,
	Interrupt = endFunction
}