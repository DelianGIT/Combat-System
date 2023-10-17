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
type Knockback = {
	StartTime: number,
	Priority: number,

	BodyVelocity: BodyVelocity,
}

--// VARIABLES
local KnockbackManager = {}

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
		bodyVelocity.P = math.huge
	end
	bodyVelocity.Velocity = direction
	bodyVelocity.MaxForce = config.Force

	local startTime = os.clock()
	tempData.Knockback = {
		StartTime = startTime,
		Priority = priority,
		BodyVelocity = bodyVelocity,
	}

	local duration = config.Duration
	if duration then
		task.delay(config.Duration, function()
			local newKnockback = tempData.Knockback
			if newKnockback and newKnockback.StartTime == startTime then
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
	tempData.Knockback = nil
end

return KnockbackManager
