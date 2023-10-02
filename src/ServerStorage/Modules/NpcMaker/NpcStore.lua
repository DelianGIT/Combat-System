--// SERVICES
local ServerStorage = game:GetService("ServerStorage")

--// VARIABLES
local modulesFolder = ServerStorage.Npc

local npc = {}

--// CREATING NPCS
for _, module in modulesFolder:GetDescendants() do
	if module:IsA("ModuleScript") then
		local data = require(module)
		npc[module.Name] = data
	end
end

return npc
