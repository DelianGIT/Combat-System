--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// MODULES
local SharedModules = ReplicatedStorage.Modules
local ParticleEmitter = require(SharedModules.ParticleEmitter)

--// VARIABLES
local effectsFolder = ReplicatedStorage.Effects.Main
local effect = effectsFolder.BlockHit.Attachment

return function(character: Model)
	ParticleEmitter.Emit(character.HumanoidRootPart, effect)
end