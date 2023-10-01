--// SERVICES
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// VARIABLES
local modulesFolder = ServerStorage.Npc
local charactersFolder = ReplicatedStorage.Npc

local npc = {}

--// CREATING NPCS
for _, module in modulesFolder:GetDescendants() do
	if module:IsA("ModuleScript") then
		local spawnedFunction, killedFunction = table.unpack(require(module))
		local character = charactersFolder[module.Name]

		npc[module.Name] = {
			SpawnedFunction = spawnedFunction,
			KilledFunction = killedFunction,
			Character = character,
		}
	end
end

return npc
