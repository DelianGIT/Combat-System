--// SERVICES
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// MODULES
local ClientModules = ReplicatedFirst.Modules
local Utilities = require(ClientModules.Utilities)

--// EFFECTS
local effectsFolder = ReplicatedStorage.Effects
local perfectBlockEffect = effectsFolder.PerfectBlock.Attachment

return function(character: Model)
	local effect = perfectBlockEffect:Clone()
	effect.Parent = character.HumanoidRootPart
	Utilities.Emit(effect)
	Utilities.DelayDestruction(1, effect)
end
