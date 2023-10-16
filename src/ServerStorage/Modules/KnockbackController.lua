--// SERVICES
local ServerStorage = game:GetService("ServerStorage")

--// MODULES
local ServerModules = ServerStorage.Modules
local BodyMover = require(ServerModules.BodyMover)

--// CONFIG
local MAX_FORCE = Vector3.one * 1e5

--// VARIABLES
local KnockbackController = {}

--// MODULE FUNCTIONS
function KnockbackController.Apply(character: Model, duration: number, vector: Vector3, fromPoint: boolean?, maxForce: number?)
	local bodyVelocity = BodyMover.BodyVelocity(character)
	bodyVelocity.MaxForce = maxForce or MAX_FORCE
	bodyVelocity.P = math.huge

	if fromPoint then
		local characterPosition = character.HumanoidRootPart.Position
		vector = -(vector - characterPosition).Unit
	end
	bodyVelocity.Velocity = vector

	task.delay(duration, function()
		bodyVelocity:Destroy()
	end)
end

return KnockbackController