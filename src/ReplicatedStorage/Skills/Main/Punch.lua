--// SERVICES
local UserInputService = game:GetService("UserInputService")

--// VARIABLES
local spaceKeycode = Enum.KeyCode.Space

--// FUNCTIONS
return {
	Prestart = function()
		return UserInputService:IsKeyDown(spaceKeycode)
	end
}