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
	local weight = data.Weight
	local fadeTime = data.FadeTime
	if weight or fadeTime then
		animationTrack:AdjustWeight(weight, fadeTime)
	end

	for key, value in data do
		if key ~= "Weight" and key ~= "FadeTime" then
			animationTrack[key] = value
		end
	end
end

--// MODULE FUNCTIONS
function AnimationManager.Load(target: Target, animation: Animation | AnimationTrack, data: AnimationData)
	local animator = getAnimator(target)
	if not animator then
		return
	end

	local animationTrack
	if animation:IsA("Animation") then
		animationTrack = animator:LoadAnimation(animation)
	end

	if data then
		loadData(animationTrack, data)
	end

	animationTrack.Ended:Connect(function()
		animationTrack:Destroy()
	end)

	return animationTrack
end

function AnimationManager.Play(target: Target, animation: Animation | AnimationTrack, fadeInTime: number?, data: AnimationData)
	AnimationManager.Load(target, animation, data):Play(fadeInTime)
end

function AnimationManager.Stop(target: Target, animation: AnimationTrack | Animation | string, fadeOutTime: number?)
	local animator = getAnimator(target)
	if not animator then
		return
	end

	local animationTrack
	if typeof(animation) == "string" then
		local playingAnimations = animator:GetPlayingAnimationTracks()
		for _, playingAnimation in playingAnimations do
			if playingAnimation.Name == animation then
				animationTrack = playingAnimation
			end
		end
	elseif animation:IsA("Animation") then
		local name = animation.Name
		local playingAnimations = animator:GetPlayingAnimationTracks()
		for _, playingAnimation in playingAnimations do
			if playingAnimation.Name == name then
				animationTrack = playingAnimation
			end
		end
	elseif animation:IsA("AnimationTrack") then
		animationTrack = animation
	end
	
	animationTrack:Stop(fadeOutTime)
end

return AnimationManager