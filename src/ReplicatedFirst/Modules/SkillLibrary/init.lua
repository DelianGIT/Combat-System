--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local Players = game:GetService("Players")

--// MODULES
local ClientModules = ReplicatedFirst.Modules
local Keybind = require(ClientModules.Keybind)

local SharedModules = ReplicatedStorage.Modules
local CooldownStore = require(SharedModules.CooldownStore)

local GuiLists = require(script.GuiLists)
local SkillPacksStore = require(script.SkillPacksStore)
local Communicator = require(script.Communicator)

--// PACKAGES
local Packages = ReplicatedStorage.Packages
local Red = require(Packages.Red)
local Trove = require(Packages.Trove)

--// VARIABLES
local player = Players.LocalPlayer

local skillPacksItems = ReplicatedStorage.Items.SkillPacks

local remoteEvent = Red.Client("SkillControl")

local blockOtherSkills = false

local requestedStart = {}
local requestedEnd = {}
local activeSkills = {}
local skillPacks = {}
local SkillLibrary = {}

--// FUNCTIONS
local function getSkillFunction(functionName: string, skillName: string, skills: {})
	local skill = skills[skillName]
	local functions = if skill then skill.Functions else nil
	return if functions then functions[functionName] else nil
end

local function getSkillPack(name: string)
	local pack = skillPacks[name]
	if pack then
		return pack
	else
		error("Skill pack " .. name .. " not found")
	end
end

local function getSkill(name: string, packName: string, pack: {})
	local skill = pack.Skills[name]
	if skill then
		return skill
	else
		error("Skill " .. name .. " not found in skill pack " .. packName)
	end
end

local function startCooldown(packName: string, skillName: string)
	local pack = getSkillPack(packName)
	local cooldownDuration = pack.CooldownStore:Start(skillName)
	GuiLists.StartCooldown(pack.GuiList[skillName], cooldownDuration)
end

local function unblockOtherSkills()
	for _, properties in activeSkills do
		if not properties.NotBlockOtherSkills then
			return
		end
	end
	blockOtherSkills = false
end

local function ended(packName: string, skillName: string)
	local identifier = packName .. "_" .. skillName

	local activeSkill = activeSkills[identifier]
	if not activeSkill then
		repeat
			activeSkill = activeSkills[identifier]
			task.wait()
		until activeSkill
	end

	if activeSkill.State ~= "ReadyForEnd" then
		repeat
			task.wait()
		until activeSkill.State == "ReadyForEnd"
	end

	local communicator = activeSkill.Communicator
	if communicator then
		communicator:Destroy()
	end

	GuiLists.Ended()
	startCooldown(packName, skillName)

	activeSkills[identifier] = nil
	unblockOtherSkills()
end


local function interrupt(packName: string, skillName: string)
	local identifier = packName .. "_" .. skillName

	if requestedStart[identifier] then
		repeat
			task.wait()
		until not requestedStart[identifier]
	end
	
	local activeSkill = activeSkills[identifier]
	if not activeSkill then
		return
	end

	local communicator = activeSkill.Communicator
	local trove = activeSkill.Trove

	local interruptFunction = getSkillFunction("Interrupt", packName, skillName)
	if interruptFunction then
		local success, err = pcall(interruptFunction, player, communicator, trove)
		if not success then
			warn("Interrupt of " .. identifier .. " threw an error: " .. err)
			if trove then
				trove:Clean()
			end
		end
	else
		if trove then
			trove:Clean()
		end
	end

	GuiLists.Ended()
	startCooldown(packName, skillName)
	communicator:Destroy()

	activeSkills[identifier] = nil
	requestedEnd [identifier]= false
	unblockOtherSkills()
end

--// REQUESTERS
local function requestStart(packName: string, skillName: string)
	local identifier = packName .. "_" .. skillName
	if requestedStart[identifier] then
		return
	end

	if blockOtherSkills or activeSkills[identifier] then
		return
	end

	local pack = getSkillPack(packName)
	local skill = getSkill(skillName, packName, pack)

	if pack.CooldownStore:IsOnCooldown(skillName) then
		return
	end

	local prestartFunction = getSkillFunction("Prestart", packName, skillName)
	local result
	if prestartFunction then
		result = prestartFunction()
		if result == "Cancel" then
			return
		end
	end

	local skillData = skill.Data
	local notBlockOtherSkills = skillData.NotBlockOtherSkills
	if not notBlockOtherSkills then
		blockOtherSkills = true
	end
	
	requestedStart[identifier] = {
		HasEnd = skillData.HasEnd,
		NotBlockOtherSkills = notBlockOtherSkills
	}

	if result then
		remoteEvent:Fire("Start", packName, skillName, result)
	else
		remoteEvent:Fire("Start", packName, skillName)
	end
end

local function requestEnd(packName: string, skillName: string)
	local identifier = packName .. "_" .. skillName
	if requestedEnd[identifier] then
		return
	end

	local activeSkill = activeSkills[identifier]
	if not activeSkill or not activeSkill.HasEnd or activeSkill.State == "End" then
		return
	end

	local pack = getSkillPack(packName)
	getSkill(skillName, packName, pack)

	if activeSkill.State ~= "WaitingForEnd" then
		repeat
			if not activeSkills[identifier] or activeSkill.State == "NotWaitingForEnd" then
				return
			else
				task.wait()
			end
		until activeSkill.State ~= "WaitingForEnd"
	end
	activeSkill.State = "NotWaitingForEnd"
	
	requestedEnd[identifier] = true
	remoteEvent:Fire("End", packName, skillName)
end


--// CONFIRMED FUNCTIONS
local function startConfirmed(packName: string, skillName: string)
	local identifier = packName .. "_" .. skillName
	local activeSkill = requestedStart[identifier]
	activeSkill.State = "Start"
	activeSkills[identifier] = activeSkill
	requestedStart[identifier] = nil

	local pack = getSkillPack(packName)
	local skillFrame = pack.GuiList[skillName]
	GuiLists.Started(skillFrame)

	local startFunction = getSkillFunction("Start", skillName, pack.Skills)
	if startFunction then
		local trove = Trove.new()
		activeSkill.Trove = trove

		local communicator = Communicator.new(identifier)
		activeSkill.Communicator = communicator

		local success, err = pcall(startFunction, player, communicator, trove)
		if not success then
			warn("Start of " .. identifier .. " threw an error: " .. err)
		end
	end
	
	if activeSkill.HasEnd then
		activeSkill.State = "WaitingForEnd"
	else
		activeSkill.State = "ReadyForEnd"
	end
end

local function endConfirmed(packName: string, skillName: string)
	local identifier = packName .. "_" .. skillName
	requestedEnd[identifier] = nil
	
	local activeSkill = activeSkills[identifier]
	activeSkill.State = "End"

	local pack = getSkillPack(packName)
	local endFunction = getSkillFunction("End", skillName, pack.Skills)
	if endFunction then
		local success, err = pcall(endFunction, player, activeSkill.Communicator, activeSkill.Trove)
		if not success then
			warn("End of " .. packName .. "_" .. skillName .. " threw an error: " .. err)
		end
	end

	activeSkill.State = "ReadyForEnd"
end

local function startDidntConfirm(packName: string, skillName: string)
	requestedStart[packName .. "_" .. skillName] = nil
end

local function endDidntConfirm(packName: string, skillName: string)
	requestedEnd[packName .. "_" .. skillName] = nil
end

--// ITEM FUNCTIONS
local function toggleKeybinds(packName: string, enabled: boolean)
	local pack = getSkillPack(packName)

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
	local item = skillPacksItems[packName]:Clone()

	item.Equipped:Connect(function()
		toggleKeybinds(packName, true)
		GuiLists.Open(guiList)
	end)
	item.Unequipped:Connect(function()
		toggleKeybinds(packName, false)
		GuiLists.Close(guiList)
		
		for identifier, properties in activeSkills do
			local packName2, skillName = table.unpack(string.split(identifier, "_"))
			if packName2 == packName and properties.State == "WaitingForEnd" then
				requestEnd(packName, skillName)
			end
		end
	end)

	item.Parent = backpack
end

--// FUNCTIONS
local function makeKeybinds(packName: string, skillName: string, skillData: {}, uiStroke: UIStroke)
	local inputKey = skillData.InputKey

	local externalArg = skillData.HoldDuration or skillData.ClickFrame
	local beginKeybind
	if externalArg then
		beginKeybind = Keybind[skillData.InputState](skillName, inputKey, externalArg, function()
			requestStart(packName, skillName)
			GuiLists.Pressed(uiStroke)
		end)
	else
		beginKeybind = Keybind[skillData.InputState](skillName, inputKey, function()
			requestStart(packName, skillName)
			GuiLists.Pressed(uiStroke)
		end)
	end
	beginKeybind:Disable()

	local endKeybind
	if skillData.HasEnd then
		endKeybind = Keybind.End(skillName, inputKey, function()
			requestEnd(packName, skillName)
			GuiLists.Unpressed(uiStroke)
		end)
	else
		endKeybind = Keybind.End(skillName, inputKey, function()
			GuiLists.Unpressed(uiStroke)
		end)
	end
	endKeybind:Disable()

	return {beginKeybind, endKeybind}
end

--// MODULE FUNCTIONS
function SkillLibrary.AddSkillPack(packName: string)
	if skillPacks[packName] then
		error("Player already has skill pack " .. packName)
	end
	
	local cooldownStore = CooldownStore.new()
	local guiList = GuiLists.Create(packName)

	local skillPack = SkillPacksStore[packName]
	local keybinds = {}
	for skillName, properties in skillPack do
		local skillData = properties.Data

		local skillFrame = GuiLists.AddSkill(guiList, skillName, skillData.InputKey)
		local uiStroke = skillFrame.Keybind.UIStroke

		keybinds[skillName] = makeKeybinds(packName, skillName, skillData, uiStroke)
		cooldownStore:Add(skillName, skillData.Cooldown)
	end

	if player.Character then
		giveSkillPackItem(packName, guiList)
	end

	skillPacks[packName] = {
		Keybinds = keybinds,
		CooldownStore = cooldownStore,
		GuiList = guiList,
		Skills = skillPack,
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
	local backpack = player.Backpack

	for packName, properties in skillPacks do
		giveSkillPackItem(backpack, packName, properties.GuiList)
	end
end)

return SkillLibrary