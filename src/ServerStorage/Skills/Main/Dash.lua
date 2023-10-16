--// SERVICES
local ServerStorage = game:GetService("ServerStorage")

--// MODULES
local ServerModules = ServerStorage.Modules
local BodyMover = require(ServerModules.BodyMover)

--// VARIABLES
local zeroVector = Vector3.zero
local maxForce = Vector3.new(9e10, 0, 9e10)-- * math.huge

--// SKILL
local functions = {
	Start = function(_, character: Model)
		local humanoid = character.Humanoid
		local moveDirection = humanoid.MoveDirection
		local lookVector = if moveDirection == zeroVector then character.HumanoidRootPart.CFrame.LookVector else moveDirection

	 	local bodyVelocity = BodyMover.BodyVelocity(character)
		bodyVelocity.MaxForce = maxForce
		bodyVelocity.Velocity = lookVector * 50

		task.delay(0.15, function()
			bodyVelocity:Destroy()
		end)
	end
}

return {
	Data = {},
	Functions = functions,
}
