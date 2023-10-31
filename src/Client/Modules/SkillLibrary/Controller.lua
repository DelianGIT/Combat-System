--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

--// MODULES
local Communicator = require(script.Parent.Communicator)

--// PACKAGES
local Packages = ReplicatedStorage.Packages
local Trove = require(Packages.Trove)

--// VARIABLES
local player = Players.LocalPlayer

local remoteEvents = ReplicatedStorage.Events
local remoteEvent = require(remoteEvents.SkillControl):Client()

local blockOtherSkills = false

local eventFunctions = {}
local requestedEnd = {}
local requestedStart = {}
local skillPacks = {}
local activeSkills = {}
local Controller = {}

--// FUNCTIONS
local function getSkillFunction(functionName: string, skill: {})
	local functions = if skill then skill.Functions else nil
	return if functions then functions[functionName] else nil
end

local function startCooldown(pack: {}, skillName: string)
	local cooldownDuration = pack.CooldownStore:Start(skillName)
	pack.GuiList:StartCooldown(skillName, cooldownDuration)
end

local function unblockOtherSkills(array: {})
	for _, properties in array do
		if not properties.NotBlockOtherSkills then
			return
		end
	end
	blockOtherSkills = false
end

--// EVENT FUNCTIONS
function eventFunctions.Finished(packName: string, skillName: string)
	local identifier = packName .. "_" .. skillName
	local activeSkill = activeSkills[identifier]
	if not activeSkill then
		repeat
			task.wait()
			activeSkill = activeSkills[identifier]
		until activeSkill
	end

	if activeSkill.State ~= "ReadyToFinish" then
		repeat
			task.wait()
		until activeSkill.State == "ReadyToFinish"
	end

	local event = activeSkill.Event
	if event then
		event:Destroy()
	end

	local pack = skillPacks[packName]
	local hasEnd = activeSkill.HasEnd
	if hasEnd then
		pack.GuiList:Finished(identifier)
	end

	local skill = pack.Skills[skillName]
	if skill.Data.Cooldown.Type == "End" then
		startCooldown(pack, skillName)
	end

	activeSkills[identifier] = nil
	unblockOtherSkills(activeSkills)
end

function eventFunctions.Interrupted(packName: string, skillName: string)
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
	local pack = skillPacks[packName]
	local skill = pack.Skills[skillName]
	local interruptFunction = getSkillFunction("Interrupt", skill)
	if interruptFunction then
		local success, err = pcall(interruptFunction, player, player.Character, event, trove)
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

	local hasEnd = activeSkill.HasEnd
	if hasEnd then
		pack.GuiList:Finished(identifier)
	end

	if skill.Data.Cooldown.Type == "End" then
		startCooldown(pack, skillName)
	end

	if event then
		event:Destroy()
	end

	activeSkills[identifier] = nil
	requestedEnd[identifier] = nil
	unblockOtherSkills(activeSkills)
end

function eventFunctions.StartValid(packName: string, skillName: string, additionalData: any)
	local pack = skillPacks[packName]
	local skill = pack.Skills[skillName]
	local skillData = skill.Data

	local identifier = packName .. "_" .. skillName
	local activeSkill = requestedStart[identifier]
	if activeSkill then
		activeSkill.State = "Start"
		requestedStart[identifier] = nil
	else
		activeSkill = {
			State = "Start",
			HasEnd = skillData.HasEnd,
			NotBlockOtherSkills = skillData.NotBlockOtherSkills,
		}
	end
	activeSkills[identifier] = activeSkill

	local hasEnd = activeSkill.HasEnd
	if hasEnd then
		pack.GuiList:Started(skillName, identifier)
	end

	local startFunction = getSkillFunction("Start", skill)
	if startFunction then
		local trove = Trove.new()
		activeSkill.Trove = trove

		local event = Communicator.new(identifier)
		activeSkill.Event = event

		local success, err = pcall(startFunction, {
			Player = player,
			Character = player.Character,
			Event = event,
			Trove = trove,
		}, additionalData)
		if not success then
			warn("Start of " .. identifier .. " threw an error: " .. err)
		end
	end

	if skillData.Cooldown.Type == "Begin" then
		startCooldown(pack, skillName)
	end

	if hasEnd then
		activeSkill.State = "ReadyToEnd"
	else
		activeSkill.State = "ReadyToFinish"
	end
end

function eventFunctions.EndValid(packName: string, skillName: string, additionalData: any)
	local identifier = packName .. "_" .. skillName
	requestedEnd[identifier] = nil

	local activeSkill = activeSkills[identifier]
	activeSkill.State = "End"

	local pack = skillPacks[packName]
	local endFunction = getSkillFunction("End", pack.Skills[skillName])
	if endFunction then
		local success, err = pcall(endFunction, {
			Player = player,
			Character = player.Character,
			Event = activeSkill.Event,
			Trove = activeSkill.Trove,
		}, additionalData)
		if not success then
			warn("End of " .. identifier .. " threw an error: " .. err)
		end
	end

	activeSkill.State = "ReadyToFinish"
end

function eventFunctions.StartNotValid(packName: string, skillName: string)
	requestedStart[packName .. "_" .. skillName] = nil
	unblockOtherSkills(requestedStart)
end

function eventFunctions.EndNotValid(packName: string, skillName: string)
	requestedEnd[packName .. "_" .. skillName] = nil
	unblockOtherSkills(requestedEnd)
end

--// MODULE FUNCTIONS
function Controller.RequestStart(packName: string, skillName: string)
	if not player.Character then
		return
	end

	local identifier = packName .. "_" .. skillName
	if requestedStart[identifier] then
		return
	end

	if blockOtherSkills or activeSkills[identifier] then
		return
	end

	local pack = skillPacks[packName]
	local skill = pack.Skills[skillName]
	if not skill then
		return
	end

	if pack.CooldownStore:IsOnCooldown(skillName) then
		return
	end

	local preStartFunction = getSkillFunction("PreStart", skill)
	local result
	if preStartFunction then
		result = preStartFunction(player)
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
		NotBlockOtherSkills = notBlockOtherSkills,
	}

	if result then
		remoteEvent:Fire("Start", packName, skillName, result)
	else
		remoteEvent:Fire("Start", packName, skillName)
	end
end

function Controller.RequestEnd(packName: string, skillName: string)
	if not player.Character then
		return
	end

	local identifier = packName .. "_" .. skillName
	if requestedEnd[identifier] then
		return
	end

	local activeSkill = activeSkills[identifier]
	if not activeSkill or not activeSkill.HasEnd or activeSkill.State == "End" then
		return
	end

	if activeSkill.State ~= "ReadyToEnd" then
		repeat
			if not activeSkills[identifier] then
				return
			else
				task.wait()
			end
		until activeSkill.State == "ReadyToEnd"

		if activeSkill.State == "WaitingForEndValiation" then
			return
		end
	end
	activeSkill.State = "WaitingForEndValiation"

	local pack = skillPacks[packName]
	local skill = pack.Skills[skillName]
	local preEndFunction = getSkillFunction("PreEnd", skill)
	local result
	if preEndFunction then
		result = preEndFunction(player)
	end

	requestedEnd[identifier] = true
	if result then
		remoteEvent:Fire("End", packName, skillName, result)
	else
		remoteEvent:Fire("End", packName, skillName)
	end
end

Controller.SkillPacks = skillPacks
Controller.ActiveSkills = activeSkills

--// EVENTS
remoteEvent:On(function(action: string, packName: string, skillName: string, ...: any)
	eventFunctions[action](packName, skillName, ...)
end)

return Controller
