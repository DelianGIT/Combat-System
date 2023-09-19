--// TYPES
type HitFunction = (hit: Model) -> ()
type Geometry = {
	CFrame: CFrame,
	Size: Vector3
} | BasePart

--// CONFIG
local VISUALIZATION = true

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

local HitboxMaker = {}

--// MODULE FUNCTIONS
function HitboxMaker.Raycast(origin: Vector3, direction: Vector3, hitFunction: HitFunction)
	local raycastResult = workspace:Raycast(origin, direction, raycastParams)
	if raycastResult then
		task.spawn(hitFunction, raycastResult)
		return raycastResult
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

function HitboxMaker.new(geometry: Geometry, hitFunction: HitFunction)
	
end