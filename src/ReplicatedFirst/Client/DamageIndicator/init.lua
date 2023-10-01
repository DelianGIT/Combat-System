--SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// PACKAGES
local Packages = ReplicatedStorage.Packages
local Red = require(Packages.Red)

--// MODULES
local Highlight = require(script.Highlight)
local ScreenGui = require(script.ScreenGui)
local BillboardGui = require(script.BillboardGui)

--// VARIABLES
local remoteEvent = Red.Client("DamageIndicator")

--// EVENTS
remoteEvent:On("Hit", function(attacker: Model, target: Model, amount: number)
	Highlight(target)
	ScreenGui(amount)
	BillboardGui(attacker, target, amount)
end)

return true
