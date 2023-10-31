--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// MODULES
local SharedModules = ReplicatedStorage.Modules
local ParticleEmitter = require(SharedModules.ParticleEmitter)

--// VARIABLES
local effectsFolder = ReplicatedStorage.Effects.Main
local effect = effectsFolder.Dash

return function(target: Model, _, moveDirection: Vector3)
	local humanoidRootPart = target.HumanoidRootPart
	local position = humanoidRootPart.Position

	local part = effect:Clone()
	part.CFrame = CFrame.lookAt(position, position + moveDirection)
	part.Parent = humanoidRootPart

	if target.Humanoid.FloorMaterial ~= Enum.Material.Air then
		ParticleEmitter.EmitParticle(part.Attachment2.Dust)
	end

	ParticleEmitter.EmitParticle(part.Smoke)
	ParticleEmitter.EmitParticle(part.AirStripes)
	ParticleEmitter.Emit(humanoidRootPart, part.Attachment1, true)
end