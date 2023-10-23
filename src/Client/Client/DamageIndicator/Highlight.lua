--// SERVICES
local TweenService = game:GetService("TweenService")

--// CONFIG
local DURATION = 0.25

--// VARIABLES
local highlight = Instance.new("Highlight")
highlight.FillColor = Color3.new(1, 0, 0)
highlight.FillTransparency = 1
highlight.OutlineTransparency = 1
highlight.DepthMode = Enum.HighlightDepthMode.Occluded

local tweenInfo = TweenInfo.new(DURATION / 2, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 0, true)

--// MODULE FUNCTION
return function(target: Model)
	local newHighlight = highlight:Clone()
	newHighlight.Parent = target

	TweenService:Create(newHighlight, tweenInfo, {
		FillTransparency = 0.5
	}):Play()

	task.delay(DURATION, function()
		newHighlight:Destroy()
	end)
end
