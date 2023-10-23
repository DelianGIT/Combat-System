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
	Highlight(target)
	ScreenGui(amount)
	BillboardGui(target, amount)
end)

return true