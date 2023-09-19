--// SERVICES
local RunService = game:GetService("RunService")

--// TYPES
type HitFunction = (hit: Model) -> ()
type Geometry = {
	CFrame: CFrame,
	Size: Vector3
} | {
	Origin: Vector3,
	Direction: Vector3
} | BasePart
type HitboxType = "SpatialQuery" | "Raycast"
type Hitbox = {
	HitFunction: HitFunction,
	Geometry: Geometry,
	Type: HitboxType,
	HighAccuracy: boolean,
	Enabled: true?,

	Enable: (self: Hitbox) -> (),
	Disable: (self: Hitbox) -> (),
	GetHits: (self: Hitbox) -> ({Model} | Model)
}

--// CONFIG
local VISUALIZATION = true

--// CLASSES
local Hitbox = {}
Hitbox.__index = Hitbox

--// VARIABLES
local hitboxesFolder = workspace.Ignore.Hitboxes

local hitboxPart = Instance.new("Part")
hitboxPart.Material = Enum.Material.SmoothPlastic
hitboxPart.Color = Color3.new(1, 0, 0)
hitboxPart.Anchored = true
hitboxPart.CanCollide = false
hitboxPart.Transparency = if VISUALIZATION then 0 else 1

local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Include
raycastParams.FilterDescendantsInstances = {workspace.Living}

local overlapParams = OverlapParams.new()
overlapParams.FilterType = Enum.RaycastFilterType.Include
overlapParams.FilterDescendantsInstances = {workspace.Living}

local heartbeatConnection

local enabledHitboxes = {}
local HitboxMaker = {}

--// FUNCTIONS
local function connectHeartbeat()
	heartbeatConnection = RunService.Heartbeat:Connect(function()
		if #enabledHitboxes then
			heartbeatConnection:Disconnect()
			heartbeatConnection = nil
			return
		end

		for _, hitbox in enabledHitboxes do
			task.spawn(function()
				hitbox:GetHits()
			end)
		end
	end)
end

--// MODULE FUNCTIONS
function HitboxMaker.Raycast(origin: Vector3, direction: Vector3, hitFunction: HitFunction)
	local raycastResult = workspace:Raycast(origin, direction, raycastParams)
	local instance = if raycastResult then raycastResult.Instance else nil

	if instance then
		local character = instance.Parent
		if character:FindFirstChild("Humanoid") then
			task.spawn(hitFunction, character)
			return character
		end
	end
end

function HitboxMaker.SpatialQuery(cframe: CFrame, size: Vector3, highAccuracy: boolean, hitFunction: HitFunction)
	local hits
	if highAccuracy then
		local part = hitboxPart:Clone()
		part.CFrame = cframe
		part.Size = size
		part.Parent = if VISUALIZATION then hitboxesFolder else nil

		hits = workspace:GetPartsInPart(part, overlapParams)
	else
		hits = workspace:GetPartBoundsInBox(cframe, size, overlapParams)
	end

	local hittedCharacters = {}
	for _, hit in hits do
		local character = hit.Parent
		if character:FindFirstChild("Humanoid") and not table.find(hittedCharacters, character) then
			table.insert(hittedCharacters, character)
		end
	end

	if hitFunction then
		for _, character in hittedCharacters do
			task.spawn(hitFunction, character)
		end
	end

	return hittedCharacters
end

function HitboxMaker.MakeHitboxPart()
	return hitboxPart:Clone()
end

--// HITBOX FUNCTIONS
function HitboxMaker.new(geometry: Geometry, highAccuracy: boolean, enabled: boolean, hitFunction: HitFunction): Hitbox
	local hitbox = setmetatable({
		HitFunction = hitFunction,
		Geometry = geometry
	}, Hitbox)

	if geometry.CFrame and geometry.Size then
		hitbox.Type = "SpatialQuery"
		hitbox.HighAccuracy = highAccuracy
	elseif geometry.Origin and geometry.Direction then
		hitbox.Type = "Raycast"
	else
		error("Invalid geometry: " ..  geometry)
	end

	if enabled then
		hitbox:Enable()
	end

	return hitbox
end

function Hitbox:Enable()
	if self.Enabled then return end
	self.Enabled = true

	table.insert(enabledHitboxes, self)

	if not heartbeatConnection then
		connectHeartbeat()
	end
end

function Hitbox:Disable()
	if not self.Enabled then return end
	self.Enabled = nil

	table.remove(enabledHitboxes, table.find(enabledHitboxes, self))
end

function Hitbox:GetHits()
	local geometry = self.Geometry
	local hitboxType = self.Type

	if hitboxType == "Raycast" then
		return HitboxMaker.Raycast(geometry.Origin, geometry.Direction, self.HitFunction)
	else
		return HitboxMaker.SpatialQuery(geometry.CFrame, geometry.Size, self.HighAccuracy, self.HitFunction)
	end
end

return HitboxMaker