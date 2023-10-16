--SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

--// CONFIG
local FPS_CAP = 60

--// VARIABLES
local player = Players.LocalPlayer
local playerGui = player.PlayerGui
local fpsCounter = playerGui:WaitForChild("FpsCounter")
local amountLabel = fpsCounter.Amount

local greenColor = Color3.fromRGB(0, 255, 0)
local redColor = Color3.fromRGB(255, 0, 0)

local fps = 0
local lastUpdateTime = 0

--// EVENTS
RunService.RenderStepped:Connect(function()
	fps += 1

	if os.clock() - lastUpdateTime >= 1 then
		amountLabel.Text = fps

		local clampedFps = math.clamp(fps, 0, FPS_CAP)
		amountLabel.TextColor3 = redColor:Lerp(greenColor, clampedFps / FPS_CAP)

		lastUpdateTime = os.clock()
		fps = 0
	end
end)

return true
