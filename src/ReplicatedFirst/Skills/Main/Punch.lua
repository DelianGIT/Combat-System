--// SERVICES
local UserInputService = game:GetService("UserInputService")

--// VARIABLES
local spaceKeycode = Enum.KeyCode.Space

--// SKILL FUNCTIONS
return {
	Prestart = function()
		return UserInputService:IsKeyDown(spaceKeycode)
	end
}