--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

--// MODULES
local SharedModules = ReplicatedStorage.Modules
local Hitbox = require(SharedModules.Hitbox)

--// CONFIG
local HITBOX_SIZE = Vector3.new(5, 5, 5)

--// SKILL FUNCTIONS
return {
	PreStart = function()
		return UserInputService:IsKeyDown(Enum.KeyCode.Space)
	end,

	Start = function(args: {})
		local character = args.Character
		local rootCFrame = character.HumanoidRootPart.CFrame
		local lookVector = rootCFrame.LookVector
		local hitboxCFrame = rootCFrame + lookVector * 3
		local hits = Hitbox.SpatialQuery({ character }, hitboxCFrame, HITBOX_SIZE)
		args.Event:Fire("", lookVector, hits)
	end,
}
