--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

--// PACKAGES
local Packages = ReplicatedStorage.Packages
local Red = require(Packages.Red)

--// VARIABLES
local remoteEvent = Red.Server("VfxControl")

local VfxController = {}

--// CONFIG
local RENDER_DISTANCE = 1024

--MODULE FUNCTIONS
function VfxController.Start(origin:Vector3, packName:string, vfxName:string, character:Model, ...:any)
	for _, player in Players:GetPlayers() do
		if player:DistanceFromCharacter(origin) <= RENDER_DISTANCE then
			remoteEvent:Fire(player, "Start", packName, vfxName, character, ...)
		end
	end
end

return VfxController