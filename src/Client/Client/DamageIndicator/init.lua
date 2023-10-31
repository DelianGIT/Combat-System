--SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// MODULES
local Highlight = require(script.Highlight)
local ScreenGui = require(script.ScreenGui)
local BillboardGui = require(script.BillboardGui)

--// VARIABLES
local remoteEvents = ReplicatedStorage.Events
local remoteEvent = require(remoteEvents.DamageIndicator):Client()

--// EVENTS
remoteEvent:On(function(target: Model, amount: number)
	if not target then
		return
	end

	local humanoidRootPart = target:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then
		return
	end

	Highlight(target)
	BillboardGui(humanoidRootPart, amount)
	ScreenGui(amount)
end)

return true
