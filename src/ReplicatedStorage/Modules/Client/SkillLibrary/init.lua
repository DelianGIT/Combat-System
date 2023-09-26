--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

--// MODULES
local Modules = ReplicatedStorage.Modules

local ClientModules = Modules.Client
local Keybind = require(ClientModules.Keybind)

local SharedModules = Modules.Shared
local CooldownStore = require(SharedModules.CooldownStore)

local SkillStore = require(script.SkillStore)
local Communicator = require(script.Communicator)
local SkillsList = require(script.SkillsList)

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
local player = Players.LocalPlayer

local skillPackItems = ReplicatedStorage.Items.SkillPacks

local remoteEvent = Red.Client("SkillControl")

local activeSkill, trove
local requestedStart, requestedEnd
local waitingForEnd = false
local ending = false

local skillPacks = {}
local SkillController = {}

--// FUNCTIONS
local function startCooldown(packName: string, skillName: string)
	local skillPack = skillPacks[packName]
	local cooldownDuration = skillPack.CooldownStore:Start(skillName)
	SkillsList.StartCooldown(skillPack.GuiList[skillName], cooldownDuration)
end

local function ended()
	if not waitingForEnd then
		repeat task.wait() until waitingForEnd
	end
	waitingForEnd = nil

	SkillsList.Ended()

	local packName, skillName = table.unpack(activeSkill)
	startCooldown(packName, skillName)

	Communicator.DisconnectAll()
	trove = nil
	activeSkill = nil
	ending = false
end

local function interrupted()
	if not activeSkill then
		return
	end

	local packName, skillName = table.unpack(activeSkill)
	startCooldown(packName, skillName)

	local clientSkillPack = SkillStore[packName]
	local clientSkill = clientSkillPack[skillName]
	if not clientSkill then
		return
	end

	local interruptFunction = clientSkill.Interrupt
	if interruptFunction then
		local success, err = pcall(interruptFunction, trove)
		if not success then
			warn("Interrupt of skill " .. skillName .. " of skill pack " .. packName .. " threw an error: " .. err)
			trove:Clean()
		end
	else
		trove:Clean()
	end

	Communicator.DisconnectAll()
	trove = nil
	activeSkill = nil
end

--// CONFIRMED FUNCTIONS
local function startConfirmed()
	local packName, skillName = table.unpack(requestedStart)

	activeSkill = requestedStart
	requestedStart = nil

	local skillPack = skillPacks[packName]
	local skillFrame = skillPack.GuiList[skillName]
	SkillsList.Started(skillFrame)

	local clientSkillPack = SkillStore[packName]
	if clientSkillPack then
		local clientSkill = clientSkillPack[skillName]
		if clientSkill and clientSkill.Start then
			trove = Trove.new()
	
			local success, err = pcall(clientSkill.Start, Communicator, trove)
			if not success then
				warn("Start of skill " .. skillName .. " of skill pack " .. packName .. " threw an error: " .. err)
			end
		end
	end

	if skillPack.Keybinds[skillName] then
		waitingForEnd = true
	end
end

local function endConfirmed()
	requestedEnd = nil
	ending = true

	local packName, skillName = table.unpack(activeSkill)

	local clientSkillPack = SkillStore[packName]
	if not clientSkillPack then return end
	
	local clientSkill = clientSkillPack[skillName]
	if not clientSkill or not clientSkill.End then return end

	local success, err = pcall(clientSkill.End, Communicator, trove)
	if not success then
		warn("End of skill " .. skillName .. " of skill pack " .. packName .. " threw an error: " .. err)
	end
end

local function startDidntConfirm()
	requestedStart = nil
end

local function endDidntConfirm()
	requestedEnd = nil
end

--// REQUEST FUNCTIONS
local function requestSkillStart(packName: string, skillName: string)
	if requestedStart or activeSkill then
		return
	end

	local pack = skillPacks[packName]
	if pack.CooldownStore:IsOnCooldown(skillName) then
		return
	end

	requestedStart = {packName, skillName}
	remoteEvent:Fire("Start", packName, skillName)
end

local function requestSkillEnd(packName: string, skillName: string)
	if requestedEnd or ending or not activeSkill or activeSkill[1] ~= packName or activeSkill[2] ~= skillName then
		return
	end

	requestedEnd = true
	remoteEvent:Fire("End", packName, skillName)
end

--// ITEM FUNCTION
local function enableKeybinds(packName: string)
	local pack = skillPacks[packName]

	for _, keybinds in pack.Keybinds do
		keybinds[1]:Enable()
		keybinds[2]:Enable()
	end
end

local function disableKeybinds(packName: string)
	local pack = skillPacks[packName]

	for _, keybinds in pack.Keybinds do
		keybinds[1]:Disable()
		keybinds[2]:Disable()
	end
end

local function giveSkillPackItem(backpack: Backpack, packName: string)
	local item = skillPackItems[packName]:Clone()

	item.Equipped:Connect(function()
		enableKeybinds(packName)
		SkillsList.Open(packName)
	end)
	item.Unequipped:Connect(function()
		disableKeybinds(packName)
		SkillsList.Close(packName)

		if waitingForEnd then
			requestSkillEnd(table.unpack(activeSkill))
		end
	end)

	item.Parent = backpack
end

--// MODULE FUNCTIONS
function SkillController.AddSkillPack(packName: string, keybindsInfo: KeybindsInfo)
	if skillPacks[packName] then
		error("Player already has skill pack " .. packName)
	end

	local cooldownStore = CooldownStore.new()
	local guiList = SkillsList.CreateList(packName)

	local keybinds = {}
	for skillName, info in keybindsInfo do
		local hasEnd, cooldown, key, state, externalArg = table.unpack(info)

		local skillFrame = SkillsList.AddSkill(guiList, skillName, key)
		local uiStroke = skillFrame.Keybind.UIStroke

		local beginKeybind = Keybind[state](skillName, key, externalArg or function()
			requestSkillStart(packName, skillName)
			SkillsList.Pressed(uiStroke)
		end, externalArg)
		beginKeybind:Disable()

		local endKeybind
		if hasEnd then
			endKeybind = Keybind.End(skillName, key, function()
				requestSkillEnd(packName, skillName)
				SkillsList.Unpressed(uiStroke)
			end)
		else
			endKeybind = Keybind.End(skillName, key, function()
				SkillsList.Unpressed(uiStroke)
			end)
		end
		endKeybind:Disable()

		cooldownStore:Add(skillName, cooldown)
		keybinds[skillName] = { beginKeybind, endKeybind }
	end

	if player.Character then
		giveSkillPackItem(packName)
	end

	skillPacks[packName] = {
		Keybinds = keybinds,
		CooldownStore = cooldownStore,
		GuiList = guiList
	}
end

--// EVENTS
remoteEvent:On("StartConfirmed", startConfirmed)
remoteEvent:On("EndConfirmed", endConfirmed)

remoteEvent:On("StartDidntConfirm", startDidntConfirm)
remoteEvent:On("EndDidntConfirm", endDidntConfirm)

remoteEvent:On("Ended", ended)
remoteEvent:On("Interrupt", interrupted)

player.CharacterAdded:Connect(function()
	for packName, _ in skillPacks do
		giveSkillPackItem(player.Backpack, packName)
	end
end)

return SkillController