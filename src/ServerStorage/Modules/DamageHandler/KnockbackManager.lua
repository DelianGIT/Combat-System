--// SERVICES
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// MODULES
local ServerModules = ServerStorage.Modules
local BodyMover = require(ServerModules.BodyMover)

--// TYPES
export type Config = {
	Priority: number,
	Force: number,
	Duration: number,
	Length: number,

	FromPoint: boolean,

	Vector: Vector3,
}
type Knockback = {
	StartTime: number,
	Priority: number,

	BodyVelocity: BodyVelocity,
}

--// CONFIG
local VISUALIZATION = false
local MAX_FORCE = Vector3.one * math.huge

--// VARIABLES
local visualizationPart = ReplicatedStorage.Other.KnockbackVisualization

local KnockbackManager = {}

--// FUNCTIONS
function addVisualization(character: Model, direction: Vector3)
	local humanoidRootPart = character.HumanoidRootPart
	local rootPosition = humanoidRootPart.Position
	local magnitude = direction.Magnitude

	local visualization = visualizationPart:Clone()
	visualization.Size = Vector3.new(0.5, 0.5, magnitude)
	visualization.CFrame = CFrame.lookAt(rootPosition, rootPosition + direction)
	visualization.CFrame += visualization.CFrame.LookVector * magnitude / 2
	visualization.Parent = character
	
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = humanoidRootPart
	weld.Part1 = visualization
	weld.Parent = visualization
end

function removeVisualization(character: Model)
	local visualization = character:FindFirstChild("KnockbackVisualization")
	if visualization then
		visualization:Destroy()
	end
end

--// MODULE FUNCTIONS
function KnockbackManager.MakeConfig(): Config
	return {}
end

function KnockbackManager.Apply(character: Model, tempData: {}, config: Config): Knockback
	local existingKnockback = tempData.Knockback
	local priority = config.Priority
	if existingKnockback and existingKnockback.Priority >= priority then
		return
	end

	local direction = config.Vector
	if config.FromPoint then
		local characterPosition = character.HumanoidRootPart.Position
		direction = -(direction - characterPosition).Unit
	end
	direction = direction.Unit * config.Length

	local bodyVelocity
	if existingKnockback then
		bodyVelocity = existingKnockback.BodyVelocity
	else
		bodyVelocity = BodyMover.BodyVelocity(character)
	end
	bodyVelocity.Velocity = direction
	bodyVelocity.MaxForce = config.Force or MAX_FORCE

	local startTime = os.clock()
	tempData.Knockback = {
		StartTime = startTime,
		Priority = priority,
		BodyVelocity = bodyVelocity,
	}

	if VISUALIZATION then
		addVisualization(character, direction)
	end

	local duration = config.Duration
	if duration then
		task.delay(duration, function()
			local newKnockback = tempData.Knockback
			if newKnockback and newKnockback.StartTime == startTime then
				KnockbackManager.Cancel(character, tempData)
			end
		end)
	end
end

function KnockbackManager.Cancel(character: Model, tempData: {})
	local knockback = tempData.Knockback
	if not knockback then
		return
	end

	knockback.BodyVelocity:Destroy()
	tempData.Knockback = nil

	removeVisualization(character)
end

return KnockbackManager
