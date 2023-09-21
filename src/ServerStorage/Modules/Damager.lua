--// SERVICES
local ServerStorage = game:GetService("ServerStorage")

--// MODULES
local ServerModules = ServerStorage.Modules
local BlockController = require(ServerModules.BlockController)
local BodyMover = require(ServerModules.BodyMover)

--// VARIABLES
local Damager = {}

--// MODULE FUNCTIONS
function Damager.Deal(attackerCharacter: Model, targetCharacter: Model, attackerData: {[any]: any}, targetData: {[any]: any}, amount: number)
	if targetData.IsBlocking then
		if BlockController.IsPerfectBlocked(targetData) then
			BlockController.PerfectBlock(attackerCharacter, attackerData)
		elseif BlockController.IsBrokeBlock(targetData, amount) then
			BlockController.BreakBlock(targetCharacter, targetData)
		else
			BlockController.DecreaseDurability(targetData, amount)
		end
	else
		local targetHumanoid = targetCharacter.Humanoid
		targetHumanoid:TakeDamage(amount)
	end
end

function Damager.Knockback(character: Model, direction: Vector3, duration: number)
	local linearVelocity = BodyMover.LinearVelocity(character)
	linearVelocity.VectorVelocity = direction

	task.delay(duration, function()
		linearVelocity:Destroy()
	end)
end

return Damager