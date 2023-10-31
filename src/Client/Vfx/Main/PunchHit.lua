--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// MODULES
local SharedModules = ReplicatedStorage.Modules
local ParticleEmitter = require(SharedModules.ParticleEmitter)

--// VARIABLES
local effectsFolder = ReplicatedStorage.Effects.Main
local effect = effectsFolder.PunchHit.Attachment

return function(target: Model, _, attacker: Model)
	local tHumanoidRootPart = target.HumanoidRootPart
	local aPosition = attacker.HumanoidRootPart.Position

	local attachment = effect:Clone()
	attachment.Parent = tHumanoidRootPart
	attachment.WorldCFrame = CFrame.lookAt(tHumanoidRootPart.Position, aPosition)

	ParticleEmitter.EmitAndDestroy(tHumanoidRootPart, attachment, true)
end
