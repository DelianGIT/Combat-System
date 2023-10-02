--// SERVICES
local ServerStorage = game:GetService("ServerStorage")

--// MODULES
local ServerModules = ServerStorage.Modules
local BodyMover = require(ServerModules.BodyMover)

--// VARIABLES
local zeroVector = Vector3.zero

local data = {
	Name = "Dash",
	Cooldown = 2.5,
	InputKey = Enum.KeyCode.Q,
	InputState = "Begin"
}

--// FUNCTIONS
local functions = {
	Start = function(_, character: Model)
		local humanoid = character.Humanoid
		local moveDirection = humanoid.MoveDirection
		local lookVector = if moveDirection == zeroVector then character.HumanoidRootPart.CFrame.lookVector else moveDirection

	 	local linearVelocity = BodyMover.LinearVelocity(character)
		linearVelocity.MaxForce = math.huge
		linearVelocity.VectorVelocity = lookVector * 50

		task.delay(0.15, function()
			linearVelocity:Destroy()
		end)
	end
}

return {
	Data = data,
	Functions = functions,
}
