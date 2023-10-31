--// SERVICES
local ServerStorage = game:GetService("ServerStorage")

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

--// CONFIG
local VISUALIZATION = false

--// VARIABLES
local ignoreFolder = workspace.Ignore

local visualizationPart = ServerStorage.Assets.Other.KnockbackVisualization

local KnockbackManager = {}

--// FUNCTIONS
function makeVisualization(character: Model, direction: Vector3)
	local humanoidRootPart = character.HumanoidRootPart
	local rootPosition = humanoidRootPart.Position
	local magnitude = direction.Magnitude
	local lookAtCFrame = CFrame.lookAt(rootPosition, rootPosition + direction)

	local visualization = visualizationPart:Clone()
	visualization.Size = Vector3.new(0.25, 0.25, magnitude)
	visualization.CFrame = lookAtCFrame * CFrame.new(0, 0, -magnitude / 2)
	visualization.Parent = ignoreFolder

	return visualization
end

--// MODULE FUNCTIONS
function KnockbackManager.MakeConfig(): Config
	return {}
end

function KnockbackManager.Apply(character: Model, tempData: {}, config: Config)
	local existingKnockback = tempData.Knockback
	local priority = config.Priority
	if existingKnockback and existingKnockback.Priority >= priority then
		return
	end

	local direction
	if config.FromPoint then
		local characterPosition = character.HumanoidRootPart.Position
		direction = -(characterPosition - config.Vector)
	else
		direction = config.Vector
	end
	direction = direction.Unit * config.Length

	local bodyVelocity
	if existingKnockback then
		bodyVelocity = existingKnockback.BodyVelocity
	else
		bodyVelocity = BodyMover.BodyVelocity(character)
	end
	bodyVelocity.Velocity = direction
	bodyVelocity.MaxForce = config.Force

	local visualization
	if VISUALIZATION then
		visualization = makeVisualization(character, direction)
	end

	local startTime = os.clock()
	tempData.Knockback = {
		StartTime = startTime,
		Priority = priority,
		BodyVelocity = bodyVelocity,
		Visualization = visualization,
	}

	local duration = config.Duration
	if duration then
		task.delay(duration, function()
			local currentKnockback = tempData.Knockback
			if currentKnockback and currentKnockback.StartTime == startTime then
				KnockbackManager.Cancel(tempData)
			end
		end)
	end
end

function KnockbackManager.Cancel(tempData: {})
	local knockback = tempData.Knockback
	if not knockback then
		return
	end

	knockback.BodyVelocity:Destroy()

	if VISUALIZATION then
		local visualization = knockback.Visualization
		if visualization then
			visualization:Destroy()
		end
	end

	tempData.Knockback = nil
end

return KnockbackManager
