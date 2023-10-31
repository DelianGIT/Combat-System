--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage") --// VARIABLES
local Players = game:GetService("Players")

--// TYPES
type RaycastConfig = {
	Blacklist: { Model }?,
	Offset: Vector3,
	Direction: Vector3,
}
type SpatialQueryConfig = {
	Blacklist: { Model }?,
	Offset: CFrame,
	Size: Vector3,
	Precise: boolean,
}

--// MODULES
local SharedModules = ReplicatedStorage.Modules
local HitboxMaker = require(SharedModules.Hitbox)

--// VARIABLES
local player = Players.LocalPlayer

local remoteEvents = ReplicatedStorage.Events
local remoteEvent = require(remoteEvents.HitboxControl):Client()

--// EVENTS
remoteEvent:On(function(id: string, hitboxType: string, config: RaycastConfig | SpatialQueryConfig)
	local character = player.Character
	if not character then
		remoteEvent:Fire(id)
		return
	end

	local position
	if hitboxType == "Raycast" then
		position = character.HumanoidRootPart.Position + config.Offset
	else
		position = character.HumanoidRootPart.CFrame + config.Offset
	end

	local secondArgument = config.Direction or config.Size
	local hits = HitboxMaker[hitboxType](config.Blacklist, position, secondArgument, config.Precise)
	remoteEvent:Fire(id, hits)
end)

return true
