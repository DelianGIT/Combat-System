--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

--// MODULES
local ServerModules = ServerStorage.Modules
local BlockController = require(ServerModules.BlockController)
local BodyMover = require(ServerModules.BodyMover)
local TempData = require(ServerModules.TempData)
local NpcTempData = require(ServerModules.NpcMaker.TempData)

--// PACKAGES
local Packages = ReplicatedStorage.Packages
local Red = require(Packages.Red)

--// TYPES
type HitResult = "PerfectBlocked" | "BrokeBlock" | "DecreasedDurability" | "Hit"

--// VARIABLES
local playersFolder = workspace.Living.Players
local npcFolder = workspace.Living.Npc

local remoteEvent = Red.Server("DamageIndicator")

local Damager = {}

--// MODULE FUNCTIONS
function Damager.Deal(attackerPlayer: Player, attackerCharacter: Model, targetCharacter: Model, attackerData: {[any]: any}, amount: number): HitResult
	local targetData
	local parent = targetCharacter.Parent
	if parent == playersFolder then
		local targetPlayer = Players:GetPlayerFromCharacter(targetCharacter)
		targetData = TempData.Get(targetPlayer)
	elseif parent == npcFolder then
		targetData = NpcTempData.Get(targetCharacter)
	else
		return
	end
	
	if targetData.IsBlocking then
		if BlockController.IsPerfectBlocked(targetData) then
			BlockController.PerfectBlock(attackerCharacter, attackerData)
			return "PerfectBlocked"
		elseif BlockController.IsBrokeBlock(targetData, amount) then
			BlockController.BreakBlock(targetCharacter, targetData)
			return "BrokeBlock"
		else
			BlockController.DecreaseDurability(targetData, amount)
			return "DecreasedDurability"
		end
	else
		local targetHumanoid = targetCharacter.Humanoid
		targetHumanoid:TakeDamage(amount)

		if attackerPlayer and typeof(attackerPlayer) == "Instance" then
			remoteEvent:Fire(attackerPlayer, "Hit", attackerPlayer, targetCharacter, amount)
		end

		return "Hit"
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