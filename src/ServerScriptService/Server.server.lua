--// SERVICES
local ServerScriptService = game:GetService("ServerScriptService")

--// REQUIRING MODULES
for _, module in ServerScriptService:GetChildren() do
	if module:IsA("ModuleScript") then
		task.spawn(require, module)
	end
end
print("Server started")