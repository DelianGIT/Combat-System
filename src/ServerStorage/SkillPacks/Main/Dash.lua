--// SERVICES
local ServerStorage = game:GetService("ServerStorage")

--// MODULES
local ServerModules = ServerStorage.Modules
local BodyMover = require(ServerModules.BodyMover)

--// VARIABLES
local zeroVector = Vector3.zero

--// SKILL
local functions = {
	Start = function(_, character: Model)
		local humanoid = character.Humanoid
		local moveDirection = humanoid.MoveDirection
		local lookVector = if moveDirection == zeroVector then character.HumanoidRootPart.CFrame.LookVector else moveDirection

	 	local linearVelocity = BodyMover.LinearVelocity(character)
		linearVelocity.MaxForce = math.huge
		linearVelocity.VectorVelocity = lookVector * 50

		task.delay(0.15, function()
			linearVelocity:Destroy()
		end)
	end
}

return {
	Data = {},
	Functions = functions,
}
