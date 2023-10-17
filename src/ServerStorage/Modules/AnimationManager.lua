--// TYPES
type AnimationData = {
	Looped: boolean?,
	Priority: Enum.AnimationPriority?,
	Speed: number?,
	Weight: number?,
	FadeTime: number?
}
type Target = Model | Humanoid | AnimationController | Animator

--// VARIABLES
local AnimationManager = {}

--// FUNCTIONS
local function getAnimator(target: Target)
	if target:IsA("Model") then
		local controller = target:FindFirstChild("Humanoid") or target:FindFirstChild("AnimationController")
		if controller then
			return controller:FindFirstChild("Animator")
		end
	elseif target:IsA("Humanoid") or target:IsA("AnimationController") then
		return target:FindFirstChild("Animator")
	elseif target:IsA("Animator") then
		return target
	end
end

local function loadData(animationTrack: AnimationTrack, data: AnimationData)
	local weight = data.Weight or 1
	local fadeTime = data.FadeTime or 0.100000001
	animationTrack:AdjustWeight(weight, fadeTime)

	for key, value in data do
		if key ~= "Weight" and key ~= "FadeTime" then
			animationTrack[key] = value
		end
	end
end

--// MODULE FUNCTIONS
function AnimationManager.Play(target: Target, animation: Animation | AnimationTrack, data: AnimationData)
	local animator = getAnimator(target)
	if not animator then
		return
	end

	local animationTrack
	if animation:IsA("Animation") then
		animationTrack = animator:LoadAnimation(animation)
	end

	loadData(animationTrack, data)

	animationTrack.Ended:Connect(function()
		animationTrack:Destroy()
	end)

	return animationTrack
end

function AnimationManager.Stop(target: Target, animation: AnimationTrack | Animation | string)
	local animator = getAnimator(target)
	if not animator then
		return
	end

	local animationTrack
	local isString = typeof(animation) == "string"
	if isString or animation:IsA("Animation") then
		local name
		if isString then
			name = animation
		else
			name = animation.Name
		end

		local playingAnimations = animator:GetPlayingAnimationTracks()

		for _, playingAnimation in playingAnimations do
			if playingAnimation.Name == name then
				animationTrack = playingAnimation
			end
		end
	elseif animation:IsA("AnimationTrack") then
		animationTrack = animation
	end

	animationTrack:Stop()
end

return AnimationManager