--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

--// TYPES
type HitFunction = (hit: Model) -> ()
type Type = "Raycast" | "SpatialQuery"
type RaycastConfig = {
	Blacklist: { Model }?,
	Offset: Vector3,
	Direction: Vector3,
}
type SpatialQueryConfig = {
	Blacklist: { Model }?,
	Offset: CFrame,
	Size: Vector3,
	Precise: boolean
}
type Request = {
	Player: Player,
	HitFunction: HitFunction,
	FireTime: number,
	Offset: Vector3 | CFrame,
	Type: Type
}

--// CONFIG
local ALLOWABLE_TIME_DIFFERENCE = 3
local ALLOWABLE_DISTANCE = 15

--// VARIABLES
local livingFolder = workspace.Living

local remoteEvents = ReplicatedStorage.Events
local remoteEvent = require(remoteEvents.HitboxControl):Server()

local requests = {}
local ClientHitbox = {}

--// MODULE FUNCTIONS
function ClientHitbox.Request(player: Player, hitboxType: Type, config: RaycastConfig | SpatialQueryConfig, hitFunction: HitFunction)
	local id = HttpService:GenerateGUID(false)
	requests[id] = {
		Player = player,
		HitFunction = hitFunction,
		FireTime = os.clock(),
		Offset = config.Offset,
		Type = hitboxType
	}

	task.delay(ALLOWABLE_TIME_DIFFERENCE, function()
		ClientHitbox.Cancel(id)
	end)

	remoteEvent:Fire(player, id, hitboxType, config)

	return id
end

function ClientHitbox.Cancel(id: string)
	requests[id] = nil
end

function ClientHitbox.Validate(player:Player, hit: Model, hitboxPosition: Vector3, allowableDistance: number?)
	if not allowableDistance then
		local ping = player:GetNetworkPing()
		allowableDistance = ALLOWABLE_DISTANCE + (ping / 100)
	end

	local primaryPart = hit.HumanoidRootPart
	local hitPosition = if primaryPart then primaryPart.Position else nil
	local magnitude = if hitPosition then (hitPosition - hitboxPosition).Magnitude else nil

	if not hit:IsDescendantOf(livingFolder)
	or not hit:IsA("Model")
	or not hit:FindFirstChild("Humanoid")
	or not magnitude or (magnitude > allowableDistance)
	then return end

	return true
end

--// EVENTS
remoteEvent:On(function(player: Player, id: string, hits: { any })
	local request = requests[id]
	if not request or request.Player ~= player then
		return
	end
	requests[id] = nil

	local character = player.Character
	if not hits or not character then
		return
	end

	if os.clock() - request.FireTime > ALLOWABLE_TIME_DIFFERENCE then
		return
	end
	
	local hitboxPosition
	if request.Type == "Raycast" then
		hitboxPosition = character.HumanoidRootPart.Position + request.Offset
	else
		hitboxPosition = (character.HumanoidRootPart.CFrame + request.Offset).Position
	end

	local ping = player:GetNetworkPing()
	local allowableDistance = ALLOWABLE_DISTANCE + (ping / 100)

	local hitFunction = request.HitFunction
	for _, hit in hits do
		if ClientHitbox.Validate(player, hit, hitboxPosition, allowableDistance) then
			hitFunction(hit)
		end
	end
end)

return ClientHitbox