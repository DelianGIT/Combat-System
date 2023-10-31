--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

--// TYPES
type Params = {
	Pack: string,
	Vfx: string,
	Timeout: number?,
	AdditionalData: any,
}

--// VARIABLES
local event = ReplicatedStorage.Events
local remoteEvent = require(event.VfxControl):Server()

local VfxController = {}

--MODULE FUNCTIONS
function VfxController.Start(distance: number, character: Model, params: Params)
	local origin = character.HumanoidRootPart.Position
	for _, player in Players:GetPlayers() do
		if player:DistanceFromCharacter(origin) <= distance then
			remoteEvent:Fire(player, os.time(), character, params)
		end
	end
end

function VfxController.StartExcept(distance: number, exceptPlayers: { Player }, character: Model, params: Params)
	local origin = character.HumanoidRootPart.Position
	for _, player in Players:GetPlayers() do
		if player:DistanceFromCharacter(origin) <= distance and not table.find(exceptPlayers, player) then
			remoteEvent:Fire(player, os.time(), character, params)
		end
	end
end



return VfxController
