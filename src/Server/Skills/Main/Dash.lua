--// SERVICES
local ServerStorage = game:GetService("ServerStorage")

--// MODULES
local ServerModules = ServerStorage.Modules
local VfxController = require(ServerModules.VfxController)
local BodyMover = require(ServerModules.BodyMover)

--// CONFIG
local MAX_FORCE = Vector3.new(1, 0, 1) * 5e5
local LENGTH = 50

--// SKILL FUNCTIONS
return {
	Start = function(args: {}, direction: Vector3)
		local character = args.Character
		VfxController.StartExcept(100, { args.Player },  character, {
			Pack = "Main",
			Vfx = "Dash",
			AdditionalData = direction
		})

		local bodyVelocity = BodyMover.BodyVelocity(character)
		if bodyVelocity then
			bodyVelocity.MaxForce = MAX_FORCE
			bodyVelocity.Velocity = direction.Unit * Vector3.new(1, 0, 1) * LENGTH
	
			task.delay(0.3, function()
				bodyVelocity:Destroy()
			end)
		end
	end,
}
