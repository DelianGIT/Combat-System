--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

--// MODULES
local Modules = ReplicatedStorage.Modules
local SharedModules = Modules.Shared
local Cooldowns = require(SharedModules.Cooldowns)

local ServerModules = ServerStorage.Modules
local TempData = require(ServerModules.TempData)
local SkillStore = require(script.SkillStore)

--// PACKAGES
local Packages = ReplicatedStorage.Packages
local Trove = require(Packages.Trove)

--// TYPES
type SkillUseState = "Start" | "End" | "Interrupt"
type SkillState = "Start" | "ReadyToEnd" | "End" | "Interrupt"

type Data = { [string]: any }

type SkillFunction = (player: Player, playerTempData: Data, skillData: Data) -> nil

--// VARIABLES
local SkillUseFunctions = {}
local SkillLibrary = {}

--// FUNCTIONS
local function deepTableClone(tableToClone: { any })
	local result = {}

	for key, value in pairs(tableToClone) do
		if type(value) == "table" then
			result[key] = deepTableClone(value)
		else
			result[key] = value
		end
	end

	return result
end

local function isSkillCanBeUsed(
	player: Player,
	tempData: Data,
	skillData: Data,
	skillFunctions,
	useState: SkillUseState,
	packName: string,
	skillName: string
)
	if useState == "Start" then
		if Cooldowns.IsOnCooldown(player.Name .. "_" .. packName .. "_" .. skillName) then
			return
		end

		if tempData.ActiveSkill then
			return
		end

		if not tempData.CanUseSkills then
			return
		end

		return true
	elseif useState == "End" then
		local activeSkill = tempData.ActiveSkill
		if activeSkill.Pack ~= packName or activeSkill.Skill ~= skillName or activeSkill.State ~= "ReadyToEnd" then
			return
		end

		if not skillFunctions.End then
			return
		end

		return true
	elseif useState == "Interrupt" then
		local activeSkill = tempData.ActiveSkill
		if activeSkill.Pack ~= packName or activeSkill.Skill ~= skillName or not activeSkill.Trove then
			return
		end

		if not skillData.CanBeInterrupted then
			return
		end

		return true
	end
end

local function getSkill(tempData: Data, packName: string, skillName: string)
	local pack = tempData.SkillPacks[packName]
	if not pack then
		return
	end

	local skillData = pack[skillName]
	if not skillData then
		return
	end

	return skillData, SkillStore[packName][skillName]
end

--// SKILL USE FUNCTIONS
function SkillUseFunctions.Start(
	player: Player,
	tempData: Data,
	skillData: Data,
	startFunction: SkillFunction,
	endFunction: SkillFunction
)
	local activeSkill = tempData.ActiveSkill
	local startTime = tick()
	activeSkill.StartTime = startTime

	local trove = Trove.new()

	local duration = skillData.Duration
	if duration then
		task.delay(duration, function()
			if startTime == activeSkill.StartTime then
				SkillUseFunctions.End()
			end
		end)
	end

	activeSkill.State = "Start"
	local success, err = pcall(startFunction, player, tempData, skillData, trove)

	if endFunction and tempData.ActiveSkill then
		activeSkill.State = "ReadyToEnd"
	end

	return success, err
end

function SkillUseFunctions.End(player: Player, tempData: Data, skillData: Data, endFunction: SkillFunction)
	local activeSkill = tempData.ActiveSkill
	if activeSkill.State ~= "ReadyToEnd" then
		repeat
			task.wait()
		until activeSkill.State == "ReadyToEnd"
	end

	local trove = activeSkill.Trove

	activeSkill.State = "End"
	return pcall(endFunction, player, tempData, skillData, trove)
end

function SkillUseFunctions.Interrupt(tempData: Data)
	tempData.ActiveSkill.State = "Interrupt"
	tempData.ActiveSkill.Trove:Clean()
end

--// MODULE FUNCTIONS
function SkillLibrary.GiveSkillPack(player: Player, name: string)
	local tempData = TempData.GetData(player)
	if not tempData then
		return
	end

	local skillPack = SkillStore.Data[name]
	if not skillPack then
		warn("Skill pack " .. name .. " not found")
		return
	end

	tempData.SkillPacks[name] = deepTableClone(skillPack)
end

function SkillLibrary.UseSkill(player: Player, useState: SkillUseState, packName: string, skillName: string)
	local tempData = TempData.GetData(player)
	if not tempData then
		return
	end

	local skillData, skillFunctions = getSkill(tempData, packName, skillName)

	if not isSkillCanBeUsed(player, tempData, skillData, skillFunctions, useState, packName, skillName) then
		return
	end

	local activeSkill = {
		Pack = packName,
		Skill = skillName,
	}
	tempData.ActiveSkill = activeSkill

	local success, err
	if useState == "Start" then
		success, err = SkillUseFunctions.Start(player, tempData, skillData, skillFunctions.Start, skillFunctions.End)
	elseif useState == "End" then
		success, err = SkillUseFunctions.End(player, tempData, skillData, skillFunctions.End)
	elseif useState == "Interrupt" then
		SkillUseFunctions.Interrupt(tempData)
	end

	if not success then
		warn(useState .. " of " .. player.Name .. "'s skill of pack " .. packName .. " threw an error: " .. err)
	end

	player.ActiveSkill = nil
end

return SkillLibrary
