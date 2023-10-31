--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// MODULES
local SharedModules = ReplicatedStorage.Modules
local ParticleEmitter = require(SharedModules.ParticleEmitter)

--// VARIABLES
local effectsFolder = ReplicatedStorage.Effects.Block
local effect = effectsFolder.BlockHit.Attachment

return function(character: Model)
	ParticleEmitter.EmitAndDestroy(character.HumanoidRootPart, effect)
end
