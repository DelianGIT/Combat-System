--// SERVICES
local UserInputService = game:GetService("UserInputService")

--// VARIABLES
local spaceKeycode = Enum.KeyCode.Space

--// SKILL
local data = {
	InputKey = Enum.UserInputType.MouseButton1,
	InputState = "Begin"
}

local functions = {
	Prestart = function()
		return UserInputService:IsKeyDown(spaceKeycode)
	end
}

return {
	Data = data,
	Functions = functions
}