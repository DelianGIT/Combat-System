--// SERVICES
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

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

--// TYPES
type KeybindsInfo = {
	HasEnd: boolean,
	Key: Enum.KeyCode | Enum.UserInputType,
	State: "Begin" | "End" | "DoubleClick" | "Hold",
	ExternalArg: number?,
}

--// VARIABLES
local player = Players.LocalPlayer

local remoteEvent = Red.Client("SkillControl")

local skillPackItems = ReplicatedStorage.Items.SkillPacks

local skillPacks = {}
local SkillLibrary = {}

local activeSkill, trove

local requestedStart = false
local requestedEnd = false
local waitingForEnd = false
local ending = false

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
	if not waitingForEnd then
		repeat task.wait() until waitingForEnd
	end

	GuiLists.Ended()

	local packName, skillName = table.unpack(activeSkill)
	startCooldown(packName, skillName)

	Communicator.DisconnectAll()
	trove = nil
	activeSkill = nil
	waitingForEnd = false
	ending = false
end

local function interrupt()
	if not activeSkill then return end

	GuiLists.Ended()

	local packName, skillName = table.unpack(activeSkill)
	startCooldown(packName, skillName)

	local pack = skillPacks[packName]
	local interruptFunction = getSkillFunction("Interrupt", skillName, pack)
	if interruptFunction then
		local success, err = pcall(interruptFunction, Communicator, trove)
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
	requestedEnd = false
	waitingForEnd = false
	ending = false
end

--// REQUESTERS
local function requestStart(packName: string, skillName: string)
	if requestedStart or activeSkill then return end

	local pack = skillPacks[packName]
	if not pack or not pack.Keybinds[skillName] then return end

	if pack.CooldownStore:IsOnCooldown(skillName) then
		return
	end

	local prestartFunction = getSkillFunction("Prestart", skillName, pack)
	local result
	if prestartFunction then
		result = prestartFunction()
		if result == "Cancel" then return end
	end

	requestedStart = {packName, skillName}
	if result then
		remoteEvent:Fire("Start", packName, skillName, result)
	else
		remoteEvent:Fire("Start", packName, skillName)
	end
end

local function requestEnd(packName: string, skillName: string)
	if requestedEnd or ending then return end

	if not activeSkill or activeSkill[1] ~= packName or activeSkill[2] ~= skillName then
		return
	end

	local pack = skillPacks[packName]
	local keybinds = pack.Keybinds[skillName]
	if not pack or not keybinds or not keybinds[3] then return end

	if not waitingForEnd then
		repeat task.wait() until waitingForEnd
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
			warn("Start of " .. skillName .. "_" .. packName .. " threw an error: " .. err)
		end
	end

	waitingForEnd = true
end

local function endConfirmed()
	requestedEnd = false
	ending = true

	local packName, skillName = table.unpack(activeSkill)

	local pack = skillPacks[packName]
	local endFunction = getSkillFunction("End", skillName, pack)

	local success, err = pcall(endFunction, Communicator, trove)
	if not success then
		warn("End of " .. skillName .. "_" .. packName .. " threw an error: " .. err)
	end
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
function SkillLibrary.AddSkillPack(packName: string, keybindsInfo: KeybindsInfo)
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
		Skills = SkillStore[packName]
	}
end

function SkillLibrary.RemoveSkillPack(packName: string)
	local pack = skillPacks[packName]
	if pack then
		error("Player already doesn't have skill pack " .. packName)
	end

	for _, keybind in pack.Keybinds do
		keybind:Destroy()
	end

	GuiLists.Destroy(pack.GuiList)
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