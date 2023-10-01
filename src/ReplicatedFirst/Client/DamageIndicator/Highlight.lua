--// SERVICES
local TweenService = game:GetService("TweenService")

--// VARIABLES
local highlight = Instance.new("Highlight")
highlight.FillColor = Color3.new(1, 0, 0)
highlight.FillTransparency = 1
highlight.OutlineTransparency = 1
highlight.DepthMode = Enum.HighlightDepthMode.Occluded

local highlightTweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 0, true)

--// MODULE FUNCTION
return function(target: Model)
	local newHighlight = highlight:Clone()
	newHighlight.Parent = target

	TweenService:Create(newHighlight, highlightTweenInfo, {
		FillTransparency = 0.5,
	}):Play()

	task.delay(0.2, function()
		newHighlight:Destroy()
	end)
end
