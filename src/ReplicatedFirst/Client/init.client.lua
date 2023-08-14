-- WATING FOR LOADED GAME
repeat
	task.wait()
until game.Loaded

--// REQUIRING MODULES
for _, module in ipairs(script:GetChildren()) do
	task.spawn(require, module)
end