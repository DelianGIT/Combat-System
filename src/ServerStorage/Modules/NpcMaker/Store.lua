--// SERVICES
local ServerStorage = game:GetService("ServerStorage")

--// CONFIG
local NPC_FOLDER = ServerStorage.Npc

--// VARIABLES
local store = {}

--// CREATING NPCS
for _, module in NPC_FOLDER:GetDescendants() do
	if module:IsA("ModuleScript") then
		local success, result = pcall(require, module)
		if success then
			store[module.Name] = result
		else
			warn("Npc module " .. module.Name .. " threw an error: " .. result)
		end
	end
end

return store