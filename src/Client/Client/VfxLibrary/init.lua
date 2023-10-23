--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// MODULES
local Store = require(script.Store)

--// PACKAGES
local Packages = ReplicatedStorage.Packages
local Trove = require(Packages.Trove)

--// VARIABLES
local remoteEvents = ReplicatedStorage.Events
local remoteEvent = require(remoteEvents.VfxControl):Client()

local VfxLibrary = {}

--// MODULE FUNCTIONS
function VfxLibrary.Start(startTime: number, timeout: number?, packName: string, vfxName: string, character: Model, ...: any)
	if not character then
		return
	end

	if timeout and os.time() - startTime >= timeout then
		return
	end

	local pack = Store[packName]
	if not pack then
		warn("Vfx pack " .. packName .. " for " .. character.Name .. " not found")
		return
	end

	local vfx = pack[vfxName]
	if not vfx then
		warn("Vfx " .. packName .. "_" .. vfxName .. " for " .. character.Name .. " not found")
		return
	end

	local trove = Trove.new()
	local success, err = pcall(vfx, character, trove, ...)
	if not success then
		warn("Vfx " .. packName .. "_" .. vfxName .. " for " .. character.Name .. " threw an error: " .. err)
		trove:Clean()
	end
end

--// EVENTS
remoteEvent:On(VfxLibrary.Start)

return VfxLibrary