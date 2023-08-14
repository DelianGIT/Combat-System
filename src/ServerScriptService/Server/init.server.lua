--// REQUIRING MAIN MODULES

--// REQUIRING SECONDARY MODULES
for _, module in ipairs(script:GetChildren()) do
	task.spawn(require, module)
end