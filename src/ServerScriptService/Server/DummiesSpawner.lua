--// SERVICES
local ServerStorage = game:GetService("ServerStorage")

--// MODULES
local ServerModules = ServerStorage.Modules
local NpcMaker = require(ServerModules.NpcMaker)

--// VARIABLES
local spawners = workspace.Spawners
local immortalSpawn = spawners.Immortal
local attackingSpawn = spawners.Attacking

--// SPAWNING NPC
NpcMaker.Spawn("ImmortalDummy", immortalSpawn.CFrame)
NpcMaker.Spawn("AttackingDummy", attackingSpawn.CFrame)

return true
