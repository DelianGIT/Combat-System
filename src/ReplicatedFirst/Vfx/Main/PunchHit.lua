--// SERVICES
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// MODULES
local ClientModules = ReplicatedFirst.Modules
local Utilities = require(ClientModules.Utilities)

--// EFFECTS
local effectsFolder = ReplicatedStorage.Effects
local hitEffect = effectsFolder.PunchHit.Attachment

return function(character: Model)
	local effect = hitEffect:Clone()
	effect.Parent = character.HumanoidRootPart
	Utilities.Emit(effect)
	Utilities.DelayDestruction(1, effect)
end
