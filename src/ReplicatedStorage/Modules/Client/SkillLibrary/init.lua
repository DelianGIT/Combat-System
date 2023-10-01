--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

--// MODULES
local Modules = ReplicatedStorage.Modules

local ClientModules = Modules.Client
local Keybind = require(ClientModules.Keybind)

local SharedModules = Modules.Shared
local CooldownStore = require(SharedModules.CooldownStore)

local GuiLists = require(script.GuiLists)
local SkillStore = require(script.SkillStore)
local Communicator = require(script.Communicator)

--// PACKAGES
local Packages = ReplicatedStorage.Packages
local Red = require(Packages.Red)
local Trove = require(Packages.Trove)

--// VARIABLES
local player = Players.LocalPlayer

local skillPackItems = ReplicatedStorage.Items.SkillPacks

local remoteEvent = Red.Client("SkillControl")

local skillPacks = {}
local SkillLibrary = {}

local requestedStart = false
local requestedEnd = false
local waitingForEnd = false
local ending = false
local readyForEnd = false

local activeSkill, trove

--// FUNCTIONS
local function getSkillFunction(functionName: string, skillName: string, skillPack: {})
	local skills = skillPack.Skills
	local skill = if skills then skills[skillName] else nil
	return if skill then skill[functionName] else nil
end

local function startCooldown(packName: string, skillName: string)
	local skillPack = skillPacks[packName]
	local cooldownDuration = skillPack.CooldownStore:Start(skillName)
	GuiLists.StartCooldown(skillPack.GuiList[skillName], cooldownDuration)
end

local function ended()
	if not readyForEnd then
		repeat
			task.wait()
		until readyForEnd
	end
	readyForEnd = false

	GuiLists.Ended()
	Communicator.DisconnectAll()
	startCooldown(table.unpack(activeSkill))

	trove = nil
	activeSkill = nil
	ending = false
end

local function interrupt()
	if not activeSkill then
		return
	end

	GuiLists.Ended()

	local packName, skillName = table.unpack(activeSkill)
	startCooldown(packName, skillName)

	local pack = skillPacks[packName]
	local interruptFunction = getSkillFunction("Interrupt", skillName, pack)
	if interruptFunction then
		local success, err = pcall(interruptFunction, Communicator, trove)
		if not success then
			warn("Interrupt of " .. packName .. "_" .. skillName .. " threw an error: " .. err)
			trove:Clean()
		end
	else
		trove:Clean()
	end

	Communicator.DisconnectAll()
	
	trove = nil
	activeSkill = nil
	requestedEnd = false
	readyForEnd = false
	waitingForEnd = false
	ending = false
end

--// REQUESTERS
local function requestStart(packName: string, skillName: string)
	if requestedStart or activeSkill then
		return
	end

	local pack = skillPacks[packName]
	if not pack then
		return
	end
	local keybinds = pack.Keybinds[skillName]
	if not keybinds then
		return
	end

	if pack.CooldownStore:IsOnCooldown(skillName) then
		return
	end

	local prestartFunction = getSkillFunction("Prestart", skillName, pack)
	local result
	if prestartFunction then
		result = prestartFunction()
		if result == "Cancel" then
			return
		end
	end

	requestedStart = { packName, skillName, keybinds[3] }
	if result then
		remoteEvent:Fire("Start", packName, skillName, result)
	else
		remoteEvent:Fire("Start", packName, skillName)
	end
end

local function requestEnd(packName: string, skillName: string)
	if requestedEnd or ending then
		return
	end

	if not activeSkill or activeSkill[1] ~= packName or activeSkill[2] ~= skillName then
		return
	end

	local pack = skillPacks[packName]
	if not pack then
		return
	end
	local keybinds = pack.Keybinds[skillName]
	if not keybinds or not keybinds[3] then
		return
	end

	if not waitingForEnd then
		repeat
			if not activeSkill then
				return
			else
				task.wait()
			end
		until waitingForEnd
	end

	requestedEnd = true
	remoteEvent:Fire("End", packName, skillName)
end

--// CONFIRMED FUNCTIONS
local function startConfirmed()
	local packName, skillName = table.unpack(requestedStart)

	activeSkill = requestedStart
	requestedStart = false

	local pack = skillPacks[packName]
	local skillFrame = pack.GuiList[skillName]
	GuiLists.Started(skillFrame)

	trove = Trove.new()
	local startFunction = getSkillFunction("Start", skillName, pack)
	if startFunction then
		local success, err = pcall(startFunction, Communicator, trove)
		if not success then
			warn("Start of " .. packName .. "_" .. skillName .. " threw an error: " .. err)
		end
	end

	if activeSkill[3] then
		waitingForEnd = true
	else
		readyForEnd = true
	end
end

local function endConfirmed()
	requestedEnd = false
	waitingForEnd = false
	ending = true

	local packName, skillName = table.unpack(activeSkill)

	local pack = skillPacks[packName]
	local endFunction = getSkillFunction("End", skillName, pack)
	if endFunction then
		local success, err = pcall(endFunction, Communicator, trove)
		if not success then
			warn("End of " .. packName .. "_" .. skillName .. " threw an error: " .. err)
		end
	end
	
	readyForEnd = true
end

local function startDidntConfirm()
	requestedStart = false
end

local function endDidntConfirm()
	requestedEnd = false
end

--// ITEM FUNCTIONS
local function toggleKeybinds(packName: string, enabled: boolean)
	local pack = skillPacks[packName]

	if enabled then
		for _, keybinds in pack.Keybinds do
			keybinds[1]:Enable()
			keybinds[2]:Enable()
		end
	else
		for _, keybinds in pack.Keybinds do
			keybinds[1]:Disable()
			keybinds[2]:Disable()
		end
	end
end

local function giveSkillPackItem(backpack: Backpack, packName: string, guiList: Frame)
	local item = skillPackItems[packName]:Clone()

	item.Equipped:Connect(function()
		toggleKeybinds(packName, true)
		GuiLists.Open(guiList)
	end)
	item.Unequipped:Connect(function()
		toggleKeybinds(packName, false)
		GuiLists.Close(guiList)

		if waitingForEnd then
			requestEnd(table.unpack(activeSkill))
		end
	end)

	item.Parent = backpack
end

--// MODULE FUNCTIONS
function SkillLibrary.AddSkillPack(packName: string, keybindsInfo: {})
	if skillPacks[packName] then
		error("Player already has skill pack " .. packName)
	end

	local cooldownStore = CooldownStore.new()
	local guiList = GuiLists.Create(packName)

	local keybinds = {}
	for skillName, info in keybindsInfo do
		local hasEnd, cooldown, key, state, externalArg = table.unpack(info)

		local skillFrame = GuiLists.AddSkill(guiList, skillName, key)
		local uiStroke = skillFrame.Keybind.UIStroke

		local beginKeybind = Keybind[state](skillName, key, externalArg or function()
			requestStart(packName, skillName)
			GuiLists.Pressed(uiStroke)
		end, externalArg)
		beginKeybind:Disable()

		local endKeybind
		if hasEnd then
			endKeybind = Keybind.End(skillName, key, function()
				requestEnd(packName, skillName)
				GuiLists.Unpressed(uiStroke)
			end)
		else
			endKeybind = Keybind.End(skillName, key, function()
				GuiLists.Unpressed(uiStroke)
			end)
		end
		endKeybind:Disable()

		cooldownStore:Add(skillName, cooldown)
		keybinds[skillName] = { beginKeybind, endKeybind, hasEnd }
	end

	if player.Character then
		giveSkillPackItem(packName, guiList)
	end

	skillPacks[packName] = {
		Keybinds = keybinds,
		CooldownStore = cooldownStore,
		GuiList = guiList,
		Skills = SkillStore[packName],
	}
end

function SkillLibrary.RemoveSkillPack(packName: string)
	local pack = skillPacks[packName]
	if pack then
		error("Player doesn't have skill pack " .. packName)
	end

	for _, keybind in pack.Keybinds do
		keybind:Destroy()
	end

	GuiLists.Destroy(pack.GuiList)

	skillPacks[packName] = nil
end

--// EVENTS
remoteEvent:On("StartConfirmed", startConfirmed)
remoteEvent:On("EndConfirmed", endConfirmed)

remoteEvent:On("StartDidntConfirm", startDidntConfirm)
remoteEvent:On("EndDidntConfirm", endDidntConfirm)

remoteEvent:On("Ended", ended)
remoteEvent:On("Interrupt", interrupt)

player.CharacterAdded:Connect(function()
	for packName, properties in skillPacks do
		giveSkillPackItem(player.Backpack, packName, properties.GuiList)
	end
end)

return SkillLibrary