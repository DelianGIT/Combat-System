--// SERVICES
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// MODULES
local ServerModules = ServerStorage.Modules
local BodyMover = require(ServerModules.BodyMover)
local BlockController = require(ServerModules.BlockController)
local TempData = require(ServerModules.TempData)
local NpcTempData = require(ServerModules.NpcMaker.TempData)
local VfxController = require(ServerModules.VfxController)

--// PACKAGES
local Packages = ReplicatedStorage.Packages
local Red = require(Packages.Red)

--// TYPES
type Vfx = {
	PackName: string,
	VfxName: string,
}

--// VARIABLES
local playersFolder = workspace.Living.Players

local remoteEvent = Red.Server("DamageIndicator")

local Damager = {}

--// MODULE FUNCTIONS
function Damager.Knockback(character: Model, direction: Vector3, duration: number)
	local linearVelocity = BodyMover.LinearVelocity(character)
	linearVelocity.VectorVelocity = direction

	task.delay(duration, function()
		linearVelocity:Destroy()
	end)
end

function Damager.Deal(
	attackerPlayer: Player,
	attackerCharacter: Model,
	attackerTempData: {},
	targetCharacter: Model,
	amount: number,
	hitVfx: Vfx?
)
	local parent = targetCharacter.Parent
	local targetPlayer, targetTempData
	if parent == playersFolder then
		targetPlayer = Players:GetPlayerFromCharacter(targetCharacter)
		targetTempData = TempData.Get(targetPlayer)
	else
		targetTempData = NpcTempData.Get(targetCharacter)
	end

	if targetTempData.IsBlocking then
		BlockController.ProcessBlock(attackerCharacter, attackerTempData, targetPlayer, targetCharacter, targetTempData, amount)
	else
		local targetHumanoid = targetCharacter.Humanoid
		targetHumanoid:TakeDamage(amount)

		if hitVfx then
			VfxController.Start(hitVfx[1], hitVfx[2], targetCharacter)
		end

		if typeof(attackerPlayer) == "Instance" then
			remoteEvent:Fire(attackerPlayer, "Hit", attackerPlayer, targetCharacter, amount)
		end
	end
end

return Damager
