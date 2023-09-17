--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

--// MODULES
local Modules = ReplicatedStorage.Modules
local SharedModules = Modules.Shared
local CooldownStore = require(SharedModules.CooldownStore)

local ServerModules = ServerStorage.Modules
local Utilities = require(ServerModules.Utilities)
local TempData = require(ServerModules.TempData)

local Communicator = require(script.Communicator)
local SkillStore = require(script.SkillStore)

--// PACKAGES
local Packages = ReplicatedStorage.Packages
local Trove = require(Packages.Trove)
local Red = require(Packages.Red)

--// TYPES
type SkillData = {
	Cooldown: number,
	InputKey: Enum.UserInputType | Enum.KeyCode,
	InputState: "Start" | "End" | "DoubleClick" | "Hold",
	Duration: number?,
}
type SkillFunction = (skillData: SkillData, player: Player, tempData: { [string]: any }) -> ()
type SkillsFunctions = {
	Start: SkillFunction,
	End: SkillFunction?,
	Interrupt: SkillFunction?,
}
type Skill = {
	Data: SkillData,
	Functions: SkillsFunctions,
}
type SkillPack = {
	Name: string,
	Owner: Player,
	TempData: { [string]: any },
	Skills: { [string]: Skill },
	CooldownStore: any,

	StartSkill: (name: string) -> (),
	EndSkill: (name: string) -> (),
	InterruptSkill: (name: string) -> (),
}

--// CLASSES
local SkillPack: SkillPack = {}
SkillPack.__index = SkillPack

--// VARIABLES
local remoteEvent = Red.Server("SkillControl")

--// FUNCTIONS
local function isSkillCanBeStarted(
	tempData: { [string]: any },
	skillName: string,
	cooldownStore: CooldownStore.CooldownStore
)
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
end

local function isSkillCanBeEnded(tempData: { [string]: any }, packName: string, skillName: string, skillFunctions)
	local activeSkill = tempData.ActiveSkill
	if not activeSkill then
		return
	end

	if activeSkill.PackName ~= packName or activeSkill.SkillName ~= skillName or activeSkill.State ~= "ReadyToEnd" then
		return
	end

	if not skillFunctions.End then
		return
	end

	return true
end

local function isSkillCanBeInterrupted(
	tempData: { [string]: any },
	packName: string,
	skillName: string,
	skillData: { [string]: any }
)
	local activeSkill = tempData.ActiveSkill
	if not activeSkill then
		return
	end

	if activeSkill.PackName ~= packName or activeSkill.SkillName ~= skillName or not activeSkill.Trove then
		return
	end

	if not skillData.CanBeInterrupted then
		return
	end

	return true
end

local function getSkill(name: string, pack: SkillPack): Skill
	local skill = pack.Skills[name]
	if not skill then
		error("Skill " .. name .. " not found in skill pack " .. pack.Name .. " for player " .. pack.Owner.Name)
	end
	return skill
end

local function getSkillPack(player: Player, tempData: { [string]: any }, name: string)
	local pack = tempData.SkillPacks[name]
	if not pack then
		error("Player " .. player.Name .. " doesnt have skill pack " .. name)
	else
		return pack
	end
end

local function startSkill(player: Player, packName: string, skillName: string)
	local tempData = TempData.Get(player)
	local pack = getSkillPack(player, tempData, packName)
	pack:StartSkill(skillName)
end

local function endSkill(player: Player, packName: string, skillName: string)
	local tempData = TempData.Get(player)
	local pack = getSkillPack(player, tempData, packName)
	pack:EndSkill(skillName)
end

--// SKILL PACK FUNCTIONS
local function makeSkillPack(name: string)
	local skillPack = SkillStore[name]
	if not skillPack then
		error("Skill pack " .. name .. " not found")
	end

	local cooldownStore = CooldownStore.new()

	local skills = {}
	for skillName, skill in skillPack do
		skills[skillName] = {
			Data = Utilities.DeepTableClone(skill.Data),
			Functions = skill.Functions,
		}

		cooldownStore:Add(skillName, skill.Data.Cooldown)
	end

	return setmetatable({
		Name = name,
		Skills = skills,
		CooldownStore = cooldownStore,
	}, SkillPack)
end

function SkillPack:StartSkill(name: string)
	local skill = getSkill(name, self)
	local data = skill.Data
	local functions = skill.Functions

	local owner = self.Owner
	local tempData = self.TempData

	local cooldownStore = self.CooldownStore
	if not isSkillCanBeStarted(tempData, name, cooldownStore) then
		remoteEvent:Fire(owner, "StartDidntConfirm")
		return
	end

	local hasEnd = if functions.End then true else false

	local startTime = tick()
	local activeSkill = {
		SkillName = name,
		PackName = self.Name,
		Skill = skill,
		State = "Start",
		StartTime = startTime,
	}
	tempData.ActiveSkill = activeSkill

	local trove = Trove.new()
	activeSkill.Trove = trove

	local communicator = self.Communicator

	local duration = data.Duration
	if duration and hasEnd then
		task.delay(duration, function()
			local futureActiveSkill = tempData.ActiveSkill
			if futureActiveSkill and startTime == futureActiveSkill.StartTime then
				self:EndSkill(name)
			end
		end)
	end

	remoteEvent:Fire(owner, "StartConfirmed")

	local success, err = pcall(functions.Start, data, owner, tempData, trove, communicator)
	if not success then
		warn("Start of skill " .. name .. " of pack " .. self.Name .. " for player " .. owner.Name .. " threw an error: " .. err)
		trove:Clean()
		tempData.ActiveSkill = nil
		cooldownStore:Start(name)
		communicator:DisconnectAll()
		remoteEvent:Fire(owner, "Ended")
	elseif hasEnd then
		activeSkill.State = "ReadyToEnd"
	else
		tempData.ActiveSkill = nil
		cooldownStore:Start(name)
		communicator:DisconnectAll()
		remoteEvent:Fire(owner, "Ended")
	end
end

function SkillPack:EndSkill(name: string)
	local owner = self.Owner
	local tempData = self.TempData

	local activeSkill = tempData.ActiveSkill
	if activeSkill.RequestedForEnd then
		return
	end

	local skill = getSkill(name, self)
	local data = skill.Data
	local functions = skill.Functions

	if not isSkillCanBeEnded(tempData, self.Name, name, functions) then
		remoteEvent:Fire(owner, "EndDidntConfirm")
		return
	end
	activeSkill.RequestedForEnd = true

	if activeSkill.State ~= "ReadyToEnd" then
		repeat
		until activeSkill.State == "ReadyToEnd"
	end
	activeSkill.State = "End"

	local trove = activeSkill.Trove
	local communicator = self.Communicator

	remoteEvent:Fire(owner, "EndConfirmed")

	local success, err = pcall(functions.End, data, owner, tempData, trove, communicator)
	if not success then
		warn("End of skill " .. name .. " of pack " .. self.Name .. " for player " .. owner.Name .. " threw an error: " .. err)
		trove:Clean()
	end

	communicator:DisconnectAll()
	remoteEvent:Fire(owner, "Ended")
	self.CooldownStore:Start(name)
	tempData.ActiveSkill = nil
end

function SkillPack:InterruptSkill(name: string)
	local owner = self.Owner
	local tempData = self.TempData

	local skill = getSkill(name, self)
	local data = skill.Data
	local functions = skill.Functions

	if not isSkillCanBeInterrupted(tempData, self.Name, name, data) then
		return
	end

	local activeSkill = tempData.ActiveSkill
	activeSkill.State = "Interrupt"

	local trove = activeSkill.Trove
	local communicator = self.Communicator

	local interruptFunction = functions.Interrupt
	if interruptFunction then
		remoteEvent:Fire(owner, "Interrupt")

		local success, err = pcall(interruptFunction, data, owner, tempData, trove, communicator)
		if not success then
			warn("Interrupt of skill " .. name .. " of pack " .. self.Name .. " for player " .. owner.Name .. " threw an error: " .. err)
			trove:Clean()
		end
	else
		trove:Clean()
	end

	communicator:DisconnectAll()
	tempData.ActiveSkill = nil
	self.CooldownStore:Start(name)
end

--// EVENTS
remoteEvent:On("Start", startSkill)
remoteEvent:On("End", endSkill)

--// MODULE FUNCTIONS
return {
	GetKeybindsInfoPack = function(packName: string)
		local pack = SkillStore[packName]
		if not pack then
			warn("Skill pack " .. packName .. " not found")
		end

		local keybindsInfo = {}
		for name, skill in pack do
			local data = skill.Data
			local functions = skill.Functions

			keybindsInfo[name] = {
				if functions.End then true else false,
				data.Cooldown,
				data.InputKey,
				data.InputState,
				data.ClickFrame,
				data.HoldDuration,
			}
		end

		return keybindsInfo
	end,

	GiveSkillPack = function(player: Player, tempData: { [string]: any }, name: string)
		local skillPacks = tempData.SkillPacks

		if skillPacks[name] then
			warn("Player " .. player.Name .. " already has skill pack " .. name)
		end

		local pack = makeSkillPack(name)
		pack.Owner = player
		pack.TempData = tempData
		pack.Communicator = Communicator.new(player)

		skillPacks[name] = pack
	end,

	TakeSkillPack = function(player: Player, tempData: { [string]: any }, name: string)
		local skillPacks = tempData.SkillPacks

		local pack = skillPacks[name]
		if not pack then
			warn("Player " .. player.Name .. " doesnt have skill pack name")
		end

		local activeSkill = tempData.ActiveSkill
		if activeSkill then
			pack:InterruptSkill(activeSkill.Name)
		end

		skillPacks[name] = nil
	end,
}
