--// SERVICES
local ServerStorage = game:GetService("ServerStorage")

--// MODULES
local ServerModules = ServerStorage.Modules
local NpcMaker = require(ServerModules.NpcMaker)

--// VARIABLES
local spawners = workspace.Spawners
local immortalSpawn = spawners.Immortal
local attackingSpawn = spawners.Attacking
local blockingSpawn = spawners.Blocking

--// FUNCTIONS
local function spawnDummy(name: string, spawner: Part)
	local npc = NpcMaker.Spawn(name, spawner.CFrame)
	local character = npc.Character
	character.Humanoid.Died:Connect(function()
		task.wait(5)
		character:Destroy()
		spawnDummy(name, spawner)
	end)
end

--// SPAWNING NPC
spawnDummy("ImmortalDummy", immortalSpawn)
spawnDummy("AttackingDummy", attackingSpawn)
spawnDummy("BlockingDummy", blockingSpawn)

return true
