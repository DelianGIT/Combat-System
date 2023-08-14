--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

--// MODULES
local Modules = ReplicatedStorage.Modules
local SharedModules = Modules.Shared
local CooldownController = require(SharedModules.CooldownController)

local ServerModules = ServerStorage.Modules
local TempData = require(ServerModules.TempData)
local Store = require(script.Store)

--// PACKAGES
local Packages = ReplicatedStorage.Packages
local Red = require(Packages.Red)
local Trove = require(Packages.Trove)

--// TYPES
type SkillUseState = "Start" | "End" | "Interrupt"
type SkillState = "Start" | "ReadyToEnd" | "End" | "Interrupt"
type Data = { [string]: any }
type SkillFunction = (player: Player, playerTempData: Data, skillData: Data) -> nil

--// VARIABLES
local remoteEvent = Red.Server("SkillControl")

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
	tempData: Data,
	skillData: Data,
	skillFunctions,
	useState: SkillUseState,
	packName: string,
	skillName: string
)
	if useState == "Start" then
		local cooldownStore = tempData.Cooldowns[packName]
		if cooldownStore:IsOnCooldown(skillName) then
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

local function getPlayerSkill(tempData: Data, packName: string, skillName: string)
	local pack = tempData.SkillPacks[packName]
	if not pack then
		return
	end

	local skillData = pack[skillName]
	if not skillData then
		return
	end

	return skillData, Store.Functions[packName][skillName]
end

--// SKILL USE FUNCTIONS
function SkillUseFunctions.Start(
	player: Player,
	packName:string,
	skillName:string,
	tempData: Data,
	skillData: Data,
	startFunction: SkillFunction,
	endFunction: SkillFunction
)
	local activeSkill = {
		Pack = packName,
		Skill = skillName,
	}
	tempData.ActiveSkill = activeSkill

	local startTime = tick()
	activeSkill.StartTime = startTime

	local trove = Trove.new()

	local duration = skillData.Duration
	if duration then
		task.delay(duration, function()
			if startTime == activeSkill.StartTime then
				SkillUseFunctions.End(player, packName, skillName, tempData, skillData, endFunction)
			end
		end)
	end

	activeSkill.State = "Start"
	local success, err = pcall(startFunction, player, tempData, skillData, trove)

	if endFunction and tempData.ActiveSkill then
		activeSkill.State = "ReadyToEnd"
	else
		remoteEvent:Fire(player, "Ended", packName, skillName)
		tempData.ActiveSkill = nil
		tempData.Cooldowns[packName]:Start(skillName)
	end

	return success, err
end

function SkillUseFunctions.End(player: Player, packName:string, skillName:string, tempData: Data, skillData: Data, endFunction: SkillFunction)
	local activeSkill = tempData.ActiveSkill
	if activeSkill.State ~= "ReadyToEnd" then
		repeat
			task.wait()
		until activeSkill.State == "ReadyToEnd"
	end

	local trove = activeSkill.Trove

	activeSkill.State = "End"
	tempData.Cooldowns[packName]:Start(skillName)

	local success, err = pcall(endFunction, player, tempData, skillData, trove)

	remoteEvent:Fire(player, "Ended", packName, skillName)
	tempData.ActiveSkill = nil

	return success, err
end

function SkillUseFunctions.Interrupt(player:Player, tempData: Data, packName:string, skillName:string)
	tempData.ActiveSkill.State = "Interrupt"
	tempData.ActiveSkill.Trove:Clean()

	remoteEvent:Fire(player, "Ended", packName, skillName)

	tempData.Cooldowns[packName]:Start(skillName)
	tempData.ActiveSkill = nil
end

--// MODULE FUNCTIONS
function SkillLibrary.GiveSkillPack(player: Player, packName: string)
	local tempData = TempData.GetData(player)
	if tempData.SkillPacks[packName] then
		warn(player.Name .. " already has skill pack " .. packName)
		return
	end

	local skillsFunctions = Store.Functions[packName]
	local skillsData = Store.Data[packName]
	if not skillsData or not skillsFunctions then
		warn("Skill pack " .. packName .. " not found")
		return
	end
	skillsData = deepTableClone(skillsData)

	local cooldownStore = CooldownController.CreateCooldownStore()
	tempData.Cooldowns[packName] = cooldownStore
	tempData.SkillPacks[packName] = skillsData

	local keybindsInfo = {}
	for name, data in pairs(skillsData) do
		keybindsInfo[name] = {
			if skillsFunctions[name].End then true else false,
			data.Cooldown,
			data.InputKey,
			data.InputState,
			data.ClickFrame,
			data.HoldDuration,
		}

		cooldownStore:Add(name, data.Cooldown)
	end

	remoteEvent:Fire(player, "AddPack", packName, keybindsInfo)
end

function SkillLibrary.TakeSkillPack(player: Player, packName: string)
	local tempData = TempData.GetData(player)
	if not tempData.SkillPacks[packName] then
		warn(player.Name .. " doesnt have skill pack " .. packName)
		return
	end

	tempData.SkillPacks[packName] = nil

	remoteEvent:Fire(player, "RemovePack", packName)
end

function SkillLibrary.UseSkill(player: Player, useState: SkillUseState, packName: string, skillName: string)
	local tempData = TempData.GetData(player)
	local skillData, skillFunctions = getPlayerSkill(tempData, packName, skillName)

	if not isSkillCanBeUsed(tempData, skillData, skillFunctions, useState, packName, skillName) then
		if useState == "Start" then
			remoteEvent:Fire(player, "DidntStart")
		elseif useState == "End" then
			remoteEvent:Fire(player, "DidntEnd")
		end
		return
	end

	local success, err
	if useState == "Start" then
		success, err = SkillUseFunctions.Start(player, packName, skillName, tempData, skillData, skillFunctions.Start, skillFunctions.End)
		remoteEvent:Fire(player, "Started", packName, skillName)
	elseif useState == "End" then
		success, err = SkillUseFunctions.End(player, packName, skillName, tempData, skillData, skillFunctions.End)
	elseif useState == "Interrupt" then
		SkillUseFunctions.Interrupt(player, tempData, packName, skillName)
	end

	if success == false then
		warn(useState .. " of " .. player.Name .. "'s skill of pack " .. packName .. " threw an error: " .. err)
	end
end

--// EVENTS
remoteEvent:On("Start", function(player:Player, packName:string, skillName:string)
	SkillLibrary.UseSkill(player, "Start", packName, skillName)
end)

remoteEvent:On("End", function(player:Player, packName:string, skillName:string)
	SkillLibrary.UseSkill(player, "End", packName, skillName)
end)

return SkillLibrary
