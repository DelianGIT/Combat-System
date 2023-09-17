--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// MODULES
local Modules = ReplicatedStorage.Modules
local ClientModules = Modules.Client
local SharedModules = Modules.Shared
local Keybind = require(ClientModules.Keybind)
local CooldownStore = require(SharedModules.CooldownStore)

local Communicator = require(script.Communicator)
local SkillStore = require(script.SkillStore)

--// PACKAGES
local Packages = ReplicatedStorage.Packages
local Red = require(Packages.Red)
local Trove = require(Packages.Trove)

--// TYPES
type KeybindsInfo = {
	HasEnd: boolean,
	Key: Enum.KeyCode | Enum.UserInputType,
	State: "Begin" | "End" | "DoubleClick" | "Hold",
	ExternalArg: number?,
}

--// VARIABLES
local remoteEvent = Red.Client("SkillControl")

local trove
local activeSkill
local waitingForStartConfirmation
local waitingForEndConfirmation

local skillPacks = {}
local SkillController = {}

--// FUNCTIONS
local function requestSkillStart(packName: string, skillName: string)
	if waitingForStartConfirmation or activeSkill then
		return
	end

	local pack = skillPacks[packName]
	if pack.CooldownStore:IsOnCooldown(skillName) then
		return
	end

	waitingForStartConfirmation = packName .. "_" .. skillName
	remoteEvent:Fire("Start", packName, skillName)
end

local function requestSkillEnd(packName: string, skillName: string)
	if waitingForEndConfirmation or not activeSkill then
		return
	end

	waitingForEndConfirmation = true
	remoteEvent:Fire("End", packName, skillName)
end

local function startConfirmed()
	local packName, skillName = table.unpack(string.split(waitingForStartConfirmation, "_"))
	activeSkill = waitingForStartConfirmation
	waitingForStartConfirmation = nil

	local skillPack = SkillStore[packName]
	local skill = skillPack[skillName]
	if not skill or not skill.Start then
		return
	end

	local newTrove = Trove.new()
	trove = newTrove

	local success, err = pcall(skill.Start, Communicator, newTrove)
	if not success then
		warn("Start of skill " .. skillName .. " of skill pack " .. packName .. " threw an error: " .. err)
	end
end

local function endConfirmed()
	waitingForEndConfirmation = nil

	local packName, skillName = table.unpack(string.split(activeSkill, "_"))
	local pack = skillPacks[packName]
	pack.CooldownStore:Start(skillName)

	local skillPack = SkillStore[packName]
	local skill = skillPack[skillName]
	if not skill or not skill.End then
		return
	end

	local success, err = pcall(skill.End, Communicator, trove)
	if not success then
		warn("End of skill " .. skillName .. " of skill pack " .. packName .. " threw an error: " .. err)
	end
end

local function ended()
	local packName, skillName = table.unpack(string.split(activeSkill, "_"))

	local pack = skillPacks[packName]
	pack.CooldownStore:Start(skillName)

	Communicator.DisconnectAll()
	trove = nil
	activeSkill = nil
end

local function interrupt()
	if not activeSkill then
		return
	end

	local packName, skillName = table.unpack(string.split(activeSkill, "_"))
	local skillPack = SkillStore[packName]
	local skill = skillPack[skillName]
	if not skill then
		return
	end

	local interruptFunction = skill.Interrupt
	if interruptFunction then
		local success, err = pcall(interruptFunction, trove)
		if not success then
			warn("Interrupt of skill " .. skillName .. " of skill pack " .. packName .. " threw an error: " .. err)
			trove:Clean()
		end
	else
		trove:Clean()
	end

	ended()
end

local function startDidntConfirm()
	waitingForStartConfirmation = nil
end

local function endDidntConfirm()
	waitingForEndConfirmation = nil
end

--// MODULE FUNCTIONS
function SkillController.AddSkillPack(packName: string, keybindsInfo: KeybindsInfo)
	if skillPacks[packName] then
		error("Player already has skill pack " .. packName)
	end

	local cooldownStore = CooldownStore.new()

	local keybinds = {}
	for skillName, info in keybindsInfo do
		local hasEnd, cooldown, key, state, externalArg = table.unpack(info)

		local beginKeybind = Keybind[state](skillName, key, externalArg or function()
			requestSkillStart(packName, skillName)
		end, externalArg)

		local endKeybind
		if hasEnd then
			endKeybind = Keybind.End(skillName, key, function()
				requestSkillEnd(packName, skillName)
			end)
		end

		cooldownStore:Add(skillName, cooldown)
		keybinds[skillName] = if endKeybind then { beginKeybind, endKeybind } else beginKeybind
	end

	skillPacks[packName] = {
		Keybinds = keybinds,
		CooldownStore = cooldownStore,
	}
end

function SkillController.RemoveSkillPack(packName: string)
	local pack = skillPacks[packName]
	if not pack then
		error("Player doesn't have skill pack " .. packName)
	end

	for _, keybinds in pack.Keybinds do
		if keybinds[1] then
			keybinds[1]:Destroy()
			keybinds[2]:Destroy()
		else
			keybinds:Destroy()
		end
	end

	skillPacks[packName] = nil
end

--// EVENTS
remoteEvent:On("AddPack", SkillController.AddSkillPack)
remoteEvent:On("RemovePack", SkillController.RemoveSkillPack)

remoteEvent:On("StartConfirmed", startConfirmed)
remoteEvent:On("EndConfirmed", endConfirmed)

remoteEvent:On("StartDidntConfirm", startDidntConfirm)
remoteEvent:On("EndDidntConfirm", endDidntConfirm)

remoteEvent:On("Ended", ended)
remoteEvent:On("Interrupt", interrupt)

return SkillController
