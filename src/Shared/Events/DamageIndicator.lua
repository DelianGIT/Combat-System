--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// PACKAGES
local Packages = ReplicatedStorage.Packages
local Red = require(Packages.Red)

--// EVENT
return Red.Event("DamageIndicator", function(...)
	return ...
end)
