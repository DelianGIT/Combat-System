--// SERVICES
local ServerStorage = game:GetService("ServerStorage")

--// MODULES
local ServerModules = ServerStorage.Modules
local BodyMover = require(ServerModules.BodyMover)

--// VARIABLES
local maxForce = Vector3.new(9e10, 0, 9e10)

--// SKILL FUNCTIONS
return {
	Start = function(args: {}, direction: Vector3)
		direction = direction.Unit * Vector3.new(1, 0, 1)

	 	local bodyVelocity = BodyMover.BodyVelocity(args.Character)
		bodyVelocity.MaxForce = maxForce
		bodyVelocity.Velocity = direction * 50

		task.delay(0.15, function()
			bodyVelocity:Destroy()
		end)
	end
}