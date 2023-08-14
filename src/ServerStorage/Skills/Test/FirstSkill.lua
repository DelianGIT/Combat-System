--// VARIABLES
local data = {
	Name = "FirstSkill",
	Cooldown = 1,
	InputKey = Enum.KeyCode.Space,
	InputState = "Begin",
	Duration = 5
}

--// FUNCTIONS
local functions = {
	Start = function()
		print("Begin")
	end,

	End = function()
		print("End")
	end,

	Interrupt = function()
		print("Interrupt")
	end,
}

return {data, functions}