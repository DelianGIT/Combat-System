--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// MODULES
local Modules = ReplicatedStorage.Modules
local ClientModules = Modules.Client
local Utilities = require(ClientModules.Utilities)

--// EFFECTS
local effectsFolder = ReplicatedStorage.Effects
local blockBreakEffect = effectsFolder.BlockBreak.Attachment

return function(character: Model)
	local effect = blockBreakEffect:Clone()
	effect.Parent = character.HumanoidRootPart
	Utilities.Emit(effect)
	Utilities.DelayDestruction(1, effect)
end
