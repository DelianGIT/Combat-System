--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// MODULES
local SharedModules = ReplicatedStorage.Modules
local Hitbox = require(SharedModules.Hitbox)

--// CONFIG
local HITBOX_SIZE = Vector3.new(5, 5, 5)

--// SKILL FUNCTIONS
return {
	Start = function(_, character: Model, event: {}, _)
		local rootCFrame = character.HumanoidRootPart.CFrame
		local lookVector = rootCFrame.LookVector
		local hitboxCFrame = rootCFrame + lookVector * 3
		local hits = Hitbox.SpatialQuery({ character }, hitboxCFrame, HITBOX_SIZE)
		event:Fire("", lookVector, hits)
	end
}