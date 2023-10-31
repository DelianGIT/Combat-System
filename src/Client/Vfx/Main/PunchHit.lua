--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// MODULES
local SharedModules = ReplicatedStorage.Modules
local ParticleEmitter = require(SharedModules.ParticleEmitter)

--// VARIABLES
local effectsFolder = ReplicatedStorage.Effects.Main
local effect = effectsFolder.PunchHit

return function(target: Model, _, attacker: Model)
	local tHumanoidRootPart = target.HumanoidRootPart
	local aPosition = attacker.HumanoidRootPart.Position

	local part = effect:Clone()
	part.CFrame = CFrame.lookAt(tHumanoidRootPart.Position, aPosition)
	part.Parent = tHumanoidRootPart

	ParticleEmitter.Emit(tHumanoidRootPart, part.Attachment, true)
	
	task.delay(0.5, function()
		part:Destroy()
	end)
end
