--// REQUIRING MAIN MODULES
task.spawn(require, script.DataLoader)

-- WATING FOR LOADED GAME
repeat
	task.wait()
until game.Loaded

--// REQUIRING SECONDARY MODULES