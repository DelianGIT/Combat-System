--// REQUIRING MODULES
for _, module in script:GetChildren() do
	task.spawn(require, module)
end
print("Server started")
