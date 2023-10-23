--// REQUIRING MODULES
for _, module in script:GetChildren() do
	if module:IsA("ModuleScript") then
		task.spawn(require, module)
	end
end
print("Server started")