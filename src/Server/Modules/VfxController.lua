--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

--// VARIABLES
local event = ReplicatedStorage.Events
local remoteEvent = require(event.VfxControl):Server()

local VfxController = {}

--MODULE FUNCTIONS
function VfxController.Start(packName: string, vfxName: string, timeout: number?, distance: number, character: Model, ...: any)
	local origin = character.HumanoidRootPart.Position
	for _, player in Players:GetPlayers() do
		if player:DistanceFromCharacter(origin) <= distance then
			remoteEvent:Fire(player, os.time(), timeout, packName, vfxName, character, ...)
		end
	end
end

return VfxController