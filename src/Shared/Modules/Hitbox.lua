--// SERVICES
local RunService = game:GetService("RunService")

--// TYPES
type HitFunction = (hit: Model) -> ()
type Geometry = {
	CFrame: CFrame,
	Size: Vector3,
} | {
	Origin: Vector3,
	Direction: Vector3,
} | BasePart
type HitboxType = "SpatialQuery" | "Raycast"
type Hitbox = {
	HitFunction: HitFunction,
	Geometry: Geometry,
	Type: HitboxType,
	Blacklist: { Model },
	Precise: boolean,
	Enabled: true?,

	Enable: (self: Hitbox) -> (),
	Disable: (self: Hitbox) -> (),
	GetHits: (self: Hitbox) -> { Model } | Model,
}

--// CONFIG
local VISUALIZATION = false

--// CLASSES
local Hitbox: Hitbox = {}
Hitbox.__index = Hitbox

--// VARIABLES
local hitboxesFolder = workspace.Ignore.Hitboxes

local hitboxPart = Instance.new("Part")
hitboxPart.Material = Enum.Material.SmoothPlastic
hitboxPart.Color = Color3.new(1, 0, 0)
hitboxPart.Anchored = true
hitboxPart.CanCollide = false
hitboxPart.Transparency = if VISUALIZATION then 0.8 else 1

local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Include
raycastParams.FilterDescendantsInstances = { workspace.Living }

local overlapParams = OverlapParams.new()
overlapParams.FilterType = Enum.RaycastFilterType.Include
overlapParams.FilterDescendantsInstances = { workspace.Living }

local enabledHitboxes = {}
local Module = {}

local heartbeatConnection

--// FUNCTIONS
local function connectHeartbeat()
	heartbeatConnection = RunService.Heartbeat:Connect(function()
		if #enabledHitboxes == 0 then
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
function Module.MakeHitboxPart(cframe: CFrame, size: Vector3)
	local part = hitboxPart:Clone()
	part.CFrame = cframe
	part.Size = size
	return part
end

function Module.Raycast(blacklist: { Model }, origin: Vector3, direction: Vector3, hitFunction: HitFunction)
	if VISUALIZATION then
		local size = Vector3.new(0.5, 0.5, direction.Magnitude)
		local cframe = CFrame.lookAt(origin, origin + direction)

		local visualization = Module.MakeHitboxPart(cframe, size)
		visualization.Parent = hitboxesFolder

		task.delay(0.1, function()
			visualization:Destroy()
		end)
	end

	local raycastResult = workspace:Raycast(origin, direction, raycastParams)
	local instance = if raycastResult then raycastResult.Instance else nil

	if instance then
		local character = instance.Parent
		if character:FindFirstChild("Humanoid") and not table.find(blacklist, character) then
			task.spawn(hitFunction, character)
			return character
		end
	end
end

function Module.SpatialQuery(blacklist: { Model }, cframe: CFrame, size: Vector3, precise: boolean, hitFunction: HitFunction)
	local part
	if VISUALIZATION or precise then
		part = Module.MakeHitboxPart(cframe, size)
		part.Parent = hitboxesFolder
	end

	local hits
	if precise then	
		hits = workspace:GetPartsInPart(part, overlapParams)
	else
		hits = workspace:GetPartBoundsInBox(cframe, size, overlapParams)
	end

	if part then
		if VISUALIZATION then
			task.delay(0.1, function()
				part:Destroy()
			end)
		else
			part:Destroy()
		end
	end

	local hittedCharacters = {}
	if hitFunction then
		for _, hit in hits do
			local character = hit.Parent
			if character:FindFirstChild("Humanoid")
				and not table.find(hittedCharacters, character)
				and not table.find(blacklist, character)
			then
				table.insert(hittedCharacters, character)
				task.spawn(hitFunction, character)
			end
		end
	else
		for _, hit in hits do
			local character = hit.Parent
			if character:FindFirstChild("Humanoid")
				and not table.find(hittedCharacters, character)
				and not table.find(blacklist, character)
			then
				table.insert(hittedCharacters, character)
			end
		end
	end

	return hittedCharacters
end

--// HITBOX FUNCTIONS
function Module.new(blacklist: { Model }, geometry: Geometry, precise: boolean, hitFunction: HitFunction): Hitbox
	local hitbox = setmetatable({
		HitFunction = hitFunction,
		Geometry = geometry,
		Blacklist = blacklist,
	}, Hitbox)

	if geometry.CFrame and geometry.Size then
		hitbox.Type = "SpatialQuery"
		hitbox.Precise = precise
	elseif geometry.Origin and geometry.Direction then
		hitbox.Type = "Raycast"
	else
		error("Invalid geometry: " .. geometry)
	end

	return hitbox
end

function Hitbox:Enable()
	if not self.Enabled then
		self.Enabled = true

		table.insert(enabledHitboxes, self)
	
		if not heartbeatConnection then
			connectHeartbeat()
		end
	end
end

function Hitbox:Disable()
	if self.Enabled then
		self.Enabled = nil

		table.remove(enabledHitboxes, table.find(enabledHitboxes, self))
	end
end

function Hitbox:GetHits()
	local geometry = self.Geometry
	local hitboxType = self.Type

	if hitboxType == "Raycast" then
		return Module.Raycast(self.Blacklist, geometry.Origin, geometry.Direction, self.HitFunction)
	else
		return Module.SpatialQuery(self.Blacklist, geometry.CFrame, geometry.Size, self.Precise, self.HitFunction)
	end
end

return Module