--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// MODULES
local Store = require(script.VfxStore)

--// PACKAGES
local Packages = ReplicatedStorage.Packages
local Red = require(Packages.Red)
local Trove = require(Packages.Trove)

--// VARIABLES
local remoteEvent = Red.Client("VfxControl")

local VfxLibrary = {}

--// MODULE FUNCTIONS
function VfxLibrary.Start(packName: string, vfxName: string, character:Model, ...:any):()
	if not character then return end

	local pack = Store[packName]
	if not pack then
		error("Vfx pack " .. packName .. " not found")
	end

	local vfx = pack[vfxName]
	if not vfx then
		error("Vfx " .. vfxName .. " not found in pack " .. packName)
	end
	
	local trove = Trove.new()

	local success, err = pcall(vfx, character, trove, ...)
	if not success then
		warn("Vfx "..vfxName.." of pack "..packName.." for "..character.Name.." threw an error: "..err)
		trove:Clean()
	end
end

--// EVENTS
remoteEvent:On("Start", VfxLibrary.Start)

return VfxLibrary
