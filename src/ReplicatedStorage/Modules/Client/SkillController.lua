--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// MODULES
local Modules = ReplicatedStorage.Modules
local ClientModules = Modules.Client
local SharedModules = Modules.Shared
local Keybind = require(ClientModules.Keybind)
local CooldownController = require(SharedModules.CooldownController)

--// PACKAGES
local Packages = ReplicatedStorage.Packages
local Red = require(Packages.Red)

--// TYPES
type KeybindsInfo = {
	HasEnd: boolean,
	Key: Enum.KeyCode | Enum.UserInputType,
	State: "Begin" | "End" | "DoubleClick" | "Hold",
	ExternalArg: number,
}

--// VARIABLES
local remoteEvent = Red.Client("SkillControl")

local waitingForStartConfirmation = false
local requestedForEnd = false

local packs = {}
local activeSkills = {}
local SkillController = {}

--// FUNCTIONS
local function startSkill(packName: string, skillName: string)
	if waitingForStartConfirmation then print(1) return end

	if packs[packName].CooldownStore:IsOnCooldown(skillName) then
		return
	end

	if activeSkills[packName][skillName] then
		return
	end

	waitingForStartConfirmation = packName..skillName
	remoteEvent:Fire("Start", packName, skillName)
end

local function endSkill(packName: string, skillName: string)
	if requestedForEnd then
		return
	end
	
	if not activeSkills[packName][skillName] then
		return
	end
	
	if waitingForStartConfirmation then
		if waitingForStartConfirmation == packName..skillName then
			requestedForEnd = true
			repeat until not waitingForStartConfirmation
		else
			return
		end
	end
	
	remoteEvent:Fire("End", packName, skillName)
end

local function skillStarted(packName:string, skillName:string)
	waitingForStartConfirmation = false
	activeSkills[packName][skillName] = true
end

local function skillEnded(packName:string, skillName:string)
	requestedForEnd = false
	packs[packName].CooldownStore:Start(skillName)
	activeSkills[packName][skillName] = nil
end

local function skillDidntStart()
	waitingForStartConfirmation = nil
end

local function skillDidntEnd()
	requestedForEnd = nil
end

--// MODULE FUNCTIONS
function SkillController.AddSkillPack(packName: string, keybindsInfo: KeybindsInfo)
	if packs[packName] then
		error("Pack " .. packName .. " already added")
	end

	local cooldownStore = CooldownController.CreateCooldownStore()

	local keybinds = {}
	for skillName, info in keybindsInfo do
		local hasEnd, cooldown, key, state, externalArg = table.unpack(info)

		local beginKeybind = Keybind[state](skillName, key, externalArg or function()
			startSkill(packName, skillName)
		end, externalArg)

		local endKeybind
		if hasEnd then
			endKeybind = Keybind.End(skillName, key, function()
				endSkill(packName, skillName)
			end)
		end

		cooldownStore:Add(skillName, cooldown)
		keybinds[skillName] = if endKeybind then { beginKeybind, endKeybind } else beginKeybind
	end

	packs[packName] = {
		Keybinds = keybinds,
		CooldownStore = cooldownStore,
	}
	activeSkills[packName] = {}

	print("Skill pack "..packName.." added")
end

function SkillController.RemoveSkillPack(packName: string)
	local pack = packs[packName]
	if not pack then
		error("Pack " .. packName .. " not found")
	end

	for _, keybind in pack.Keybinds do
		keybind:Destroy()
	end

	packs[packName] = nil
	activeSkills[packName] = nil

	print("Skill pack "..packName.." removed")
end

--// EVENTS
remoteEvent:On("AddPack", SkillController.AddSkillPack)
remoteEvent:On("RemovePack", SkillController.RemoveSkillPack)
remoteEvent:On("Started", skillStarted)
remoteEvent:On("Ended", skillEnded)
remoteEvent:On("DidntStart", skillDidntStart)
remoteEvent:On("DidntEnd", skillDidntEnd)

return SkillController
