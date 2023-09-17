--// VARIABLES
local data = {
	Name = "FirstSkill",
	Cooldown = 1,
	InputKey = Enum.KeyCode.Space,
	InputState = "Begin",
	Duration = 5,
}

--// FUNCTIONS
local functions = {
	Start = function()
		print("Server Start")
	end,

	End = function()
		print("Server End")
	end,

	Interrupt = function()
		print("Server Interrupt")
	end,
}

return {
	Data = data,
	Functions = functions,
}
