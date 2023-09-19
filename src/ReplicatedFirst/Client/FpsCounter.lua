--SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

--// VARIABLES
local player = Players.LocalPlayer
local playerGui = player.PlayerGui
local fpsCounter = playerGui:WaitForChild("FpsCounter")
local amountLabel = fpsCounter.Amount

local fps = 0
local lastUpdateTime = 0

local greenColor = Color3.fromRGB(0, 255, 0)
local redColor = Color3.fromRGB(255, 0, 0)

--// CONFIG
local FPS_CAP = 60

--// LOCALIZED FUNCTIONS
local clock = os.clock
local clamp = math.clamp

--// EVENTS
RunService.RenderStepped:Connect(function()
	fps += 1

	if clock - lastUpdateTime >= 1 then
		amountLabel.Text = fps

		local clampedFps = clamp(fps, 0, FPS_CAP)
		amountLabel.TextColor3 = redColor:Lerp(greenColor, clampedFps / FPS_CAP)

		lastUpdateTime = clock
		fps = 0
	end
end)

return true
