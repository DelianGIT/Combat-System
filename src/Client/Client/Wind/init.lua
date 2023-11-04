--// CONFIG
local ENABLED = false
if not ENABLED then
	return true
end

--// MODULES
local WindService = require(script.WindService)

--// VARIABLES
local wind = WindService.new({
	Velocity = Vector3.new(0.5, 0, 0),
	Amount = 1,
	Frequency = 0.75,
	Lifetime = 5,
	Amplitude = 0.1,
	Range = 100,
	Height = 25,
	Time = 0.5
})

--// STARTING
wind:Start()

return true