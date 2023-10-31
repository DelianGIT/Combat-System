--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// MODULES
local Store = require(script.Store)

--// PACKAGES
local Packages = ReplicatedStorage.Packages
local Trove = require(Packages.Trove)

--// TYPES
type Params = {
	Pack: string,
	Vfx: string,
	Timeout: number?,
	AdditionalData: any,
}

--// CONFIG
local TIMEOUT = 3

--// VARIABLES
local remoteEvents = ReplicatedStorage.Events
local remoteEvent = require(remoteEvents.VfxControl):Client()

local VfxLibrary = {}

--// MODULE FUNCTIONS
function VfxLibrary.Start(character: Model, params: Params)
	local packName = params.Pack
	local pack = Store[packName]
	if not pack then
		warn("Vfx pack " .. packName .. " for " .. character.Name .. " not found")
		return
	end

	local vfxName = params.Vfx
	local vfx = pack[vfxName]
	if not vfx then
		warn("Vfx " .. packName .. "_" .. vfxName .. " for " .. character.Name .. " not found")
		return
	end

	local trove = Trove.new()
	local success, err = pcall(vfx, character, trove, params.AdditionalData)
	if not success then
		warn("Vfx " .. packName .. "_" .. vfxName .. " for " .. character.Name .. " threw an error: " .. err)
		trove:Clean()
	end
end

--// EVENTS
remoteEvent:On(function(startTime: number, character: Model, params: Params)
	if not character then
		return
	end

	local timeout = params.Timeout or TIMEOUT
	if os.time() - startTime < timeout then
		VfxLibrary.Start(character, params)
	end
end)

return VfxLibrary
