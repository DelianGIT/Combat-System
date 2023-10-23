--// VARIABLES
local zeroVector = Vector3.zero

--// SKILL FUNCTIONS
return {
	Prestart = function(player: Player)
		local character = player.Character
		local humanoid = character.Humanoid
		local moveDirection = humanoid.MoveDirection
		return if moveDirection == zeroVector then character.HumanoidRootPart.CFrame.LookVector else moveDirection
	end
}