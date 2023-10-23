--// SERVICES
local ServerStorage = game:GetService("ServerStorage")

--// CONFIG
local NPC_FOLDER = ServerStorage.Npc

--// VARIABLES
local store = {}

--// CREATING NPCS
for _, module in NPC_FOLDER:GetDescendants() do
	if not module:IsA("ModuleScript") then
		continue
	end

	local success, result = pcall(require, module)
	if success then
		store[module.Name] = result
	else
		warn("Npc module " .. module.Name .. " threw an error: " .. result)
	end
end

return store