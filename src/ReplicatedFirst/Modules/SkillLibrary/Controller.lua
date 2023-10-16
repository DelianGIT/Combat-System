--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

--// MODULES
local Communicator = require(script.Parent.Communicator)

--// PACKAGES
local Packages = ReplicatedStorage.Packages
local Red = require(Packages.Red)
local Trove = require(Packages.Trove)

--// VARIABLES
local player = Players.LocalPlayer

local remoteEvent = Red.Client("SkillControl")

local blockOtherSkills = false

local skillPacks = {}
local activeSkills = {}
local requestedStart = {}
local requestedEnd = {}
local Controller = {}

--// FUNCTIONS
local function getSkillFunction(functionName: string, skillName: string, skills: {})
	local skill = skills[skillName]
	local functions = if skill then skill.Functions else nil
	return if functions then functions[functionName] else nil
end

local function startCooldown(packName: string, skillName: string)
	local pack = skillPacks[packName]
	local cooldownDuration = pack.CooldownStore:Start(skillName)
	pack.GuiList:StartCooldown(skillName, cooldownDuration)
end

local function unblockOtherSkills()
	for _, properties in activeSkills do
		if not properties.NotBlockOtherSkills then
			return
		end
	end
	blockOtherSkills = false
end

--// OTHER SKILL FUNCTIONS
local function finished(packName: string, skillName: string)
	local identifier = packName .. "_" .. skillName

	local activeSkill = activeSkills[identifier]
	if not activeSkill then
		repeat
			activeSkill = activeSkills[identifier]
			task.wait()
		until activeSkill
	end

	if activeSkill.State ~= "WaitingForFinish" then
		repeat
			task.wait()
		until activeSkill.State == "WaitingForFinish"
	end

	local event = activeSkill.Event
	if event then
		event:Destroy()
	end

	skillPacks[packName].GuiList:Ended(identifier)
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

	local event = activeSkill.Event
	local trove = activeSkill.Trove

	local interruptFunction = getSkillFunction("Interrupt", packName, skillName)
	if interruptFunction then
		local success, err = pcall(interruptFunction, player, event, trove)
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

	skillPacks[packName].GuiList:Ended(identifier)
	startCooldown(packName, skillName)

	if event then
		event:Destroy()
	end

	activeSkills[identifier] = nil
	requestedEnd[identifier] = false
	unblockOtherSkills()
end

--// CONFIRMED FUNCTIONS
local function startConfirmed(packName: string, skillName: string)
	local identifier = packName .. "_" .. skillName
	local activeSkill = requestedStart[identifier]
	activeSkill.State = "Start"
	activeSkills[identifier] = activeSkill
	requestedStart[identifier] = nil

	local pack = skillPacks[packName]
	pack.GuiList:Started(skillName, identifier)

	local startFunction = getSkillFunction("Start", skillName, pack.Skills)
	if startFunction then
		local trove = Trove.new()
		activeSkill.Trove = trove

		local event = Communicator.new(identifier)
		activeSkill.Event = event

		local success, err = pcall(startFunction, player, event, trove)
		if not success then
			warn("Start of " .. identifier .. " threw an error: " .. err)
		end
	end

	if activeSkill.HasEnd then
		activeSkill.State = "WaitingForEnd"
	else
		activeSkill.State = "WaitingForFinish"
	end
end

local function endConfirmed(packName: string, skillName: string)
	local identifier = packName .. "_" .. skillName
	requestedEnd[identifier] = nil

	local activeSkill = activeSkills[identifier]
	activeSkill.State = "End"

	local pack = skillPacks[packName]
	local endFunction = getSkillFunction("End", skillName, pack.Skills)
	if endFunction then
		local success, err = pcall(endFunction, player, activeSkill.Event, activeSkill.Trove)
		if not success then
			warn("End of " .. identifier .. " threw an error: " .. err)
		end
	end

	activeSkill.State = "WaitingForFinish"
end

local function startDidntConfirm(packName: string, skillName: string)
	requestedStart[packName .. "_" .. skillName] = nil
end

local function endDidntConfirm(packName: string, skillName: string)
	requestedEnd[packName .. "_" .. skillName] = nil
end

--// MODULE FUNCTIONS
function Controller.Start(packName: string, skillName: string)
	local identifier = packName .. "_" .. skillName
	if requestedStart[identifier] then
		return
	end

	if blockOtherSkills or activeSkills[identifier] then
		return
	end

	local pack = skillPacks[packName]
	local skill = pack.Skills[skillName]

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

function Controller.End(packName: string, skillName: string)
	local identifier = packName .. "_" .. skillName
	if requestedEnd[identifier] then
		return
	end

	local activeSkill = activeSkills[identifier]
	if not activeSkill or not activeSkill.HasEnd or activeSkill.State == "End" then
		return
	end

	if activeSkill.State ~= "WaitingForEnd" then
		repeat
			if not activeSkills[identifier] or activeSkill.State == "WaitingForEndConfirmation" then
				return
			else
				task.wait()
			end
		until activeSkill.State ~= "WaitingForEnd"
	end
	activeSkill.State = "WaitingForEndConfirmation"

	requestedEnd[identifier] = true
	remoteEvent:Fire("End", packName, skillName)
end

Controller.SkillPacks = skillPacks
Controller.ActiveSkills = activeSkills

--// EVENTS
remoteEvent:On("StartConfirmed", startConfirmed)
remoteEvent:On("EndConfirmed", endConfirmed)

remoteEvent:On("StartDidntConfirm", startDidntConfirm)
remoteEvent:On("EndDidntConfirm", endDidntConfirm)

remoteEvent:On("Finished", finished)
remoteEvent:On("Interrupt", interrupt)

return Controller