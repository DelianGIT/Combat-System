--// SERVICES
local ReplicatedFirst = game:GetService("ReplicatedFirst")

--// MODULES
local ClientModules = ReplicatedFirst.Modules
local VfxLibrary = require(ClientModules.VfxLibrary)

--// VARIABLES
local zeroVector = Vector3.zero

--// SKILL FUNCTIONS
function preStart(player: Player)
	local character = player.Character
	local humanoid = character.Humanoid
	local moveDirection = humanoid.MoveDirection
	return if moveDirection == zeroVector then character.HumanoidRootPart.CFrame.LookVector else moveDirection
end

function start(args: {})
	VfxLibrary.Start(args.Character, {
		Pack = "Main",
		Vfx = "Dash",
		AdditionalData = preStart(args.Player)
	})
end


return {
	PreStart = preStart,
	Start = start
}