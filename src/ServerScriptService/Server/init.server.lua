--// SERVICES
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// REQUIRING MODULES
for _, module in ServerStorage.Modules:GetChildren() do
	require(module)
end

for _, module in ReplicatedStorage.Modules.Shared:GetChildren() do
	require(module)
end

for _, module in script:GetChildren() do
	task.spawn(require, module)
end
print("Server started")
