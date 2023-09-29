--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

--// MODULES
local Modules = ReplicatedStorage.Modules
local SharedModules = Modules.Shared
local CooldownStore = require(SharedModules.CooldownStore)
local Signal = require(SharedModules.Signal)

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
type SkillFunction = (skillData: SkillData, player: Player, tempData: {}) -> ()
type SkillFunctions = {
	Start: SkillFunction,
	End: SkillFunction?,
	Interrupt: SkillFunction?,
}
type Skill = {
	Data: SkillData,
	Functions: SkillFunctions,
}
type SkillPack = {
	Name: string,
	Owner: Player,
	TempData: {},
	Skills: { [string]: Skill },
	CooldownStore: any,

	StartSkill: (self: SkillPack, name: string) -> (),
	EndSkill: (self: SkillPack, name: string) -> (),
	InterruptSkill: (self: SkillPack, name: string) -> (),
}

--// CLASSES
local SkillPack: SkillPack = {}
SkillPack.__index = SkillPack

--// VARIABLES
local remoteEvent = Red.Server("SkillControl")

local SkillLibrary = {}

--// FUNCTIONS
local function addCooldowns(cooldownStore: CooldownStore.CooldownStore, skills: { [string]: Skill })
	for skillName, properties in skills do
		cooldownStore:Add(skillName, properties.Data.Cooldown)
	end
end

local function delaySkillEnd(name: string, duration: number, pack: SkillPack, startTime: number, tempData: {})
	task.delay(duration, function()
		local currentActiveSkill = tempData.ActiveSkill
		if currentActiveSkill and startTime == currentActiveSkill.StartTime then
			pack:EndSkill(name)
		end
	end)
end

local function makeActiveSkill(packName: string, skillName: string, skill: Skill, trove: {})
	local startTime = tick()
	local activeSkill = {
		SkillName = skillName,
		PackName = packName,
		Skill = skill,
		State = "Start",
		StartTime = startTime,
		Trove = trove
	}
	return startTime, activeSkill
end

local function getSkillPack(player: Player, tempData: {}, name: string)
	local pack = tempData.SkillPacks[name]
	if not pack then
		error("Player " .. player.Name .. " doesnt have skill pack " .. name)
	else
		return pack
	end
end

local function getSkill(name: string, pack: {}): Skill
	local skill = pack.Skills[name]
	if not skill then
		warn("Skill " .. name .. " not found in skill pack " .. pack.Name .. " for player " .. pack.Owner.Name)
	else
		return skill
	end
end

--// SKILL USE CONTROLLERS
local function canStartSkill(skillName: string, tempData: {}, cooldownStore: CooldownStore.CooldownStore)
	if cooldownStore:IsOnCooldown(skillName) then return end
	if tempData.ActiveSkill then return end
	if not tempData.CanUseSkills then return end
	return true
end

local function canEndSkill(tempData: { [string]: any }, packName: string, skillName: string, skillFunctions: SkillFunctions)
	local activeSkill = tempData.ActiveSkill
	if not activeSkill then return end
	if activeSkill.State == "End" then return end
	if activeSkill.PackName ~= packName or activeSkill.SkillName ~= skillName then return end
	if not skillFunctions.End then return end
	return true
end

local function canInterruptSkill(tempData: {}, packName: string, skillName: string, skillData: SkillData)
	local activeSkill = tempData.ActiveSkill
	if not activeSkill then return end
	if activeSkill.PackName ~= packName or activeSkill.SkillName ~= skillName then return end
	if not skillData.CanBeInterrupted then return end
	return true
end

--// SKILL PACK FUNCTIONS
function SkillPack:StartSkill(name: string)
	local owner = self.Owner
	local character = owner.Character
	if not character then return end
	local isPlayer = typeof(owner) == "Instance"

	local skill = getSkill(name, self)
	if not skill then return end
	local data = skill.Data
	local functions = skill.Functions
	local tempData = self.TempData
	local duration = data.Duration
	local hasEnd = functions.HasEnd

	local cooldownStore, communicator
	if isPlayer then
		cooldownStore = self.CooldownStore
		
		if not canStartSkill(name, tempData, cooldownStore) then
			remoteEvent:Fire(owner, "StartDidntConfirm")
			return
		else
			remoteEvent:Fire(owner, "StartConfirmed")
		end
		
		communicator = self.Communicator
		communicator:DisconnectAll()
	end
	local trove = Trove.new()
	
	local startTime, activeSkill = makeActiveSkill(self.Name, name, skill, trove)
	tempData.ActiveSkill = activeSkill
	
	if duration and hasEnd then
		delaySkillEnd(name, duration, self, startTime, tempData)
	end

	tempData.SkillStarting:Fire(self.Name, name)
	local success, err = pcall(functions.Start, owner, character, tempData, data, trove, communicator)

	if not success then
		warn("Start of " .. name .. "_" .. self.Name .. " for player " .. owner.Name .. " threw an error: " .. err)
		self:QuickInterrupt(name)
	elseif hasEnd then
		activeSkill.State = "ReadyToEnd"
	else
		tempData.ActiveSkill = nil
		tempData.SkillEnded:Fire(self.Name, name, "Start", true)

		if isPlayer then
			cooldownStore:Start(name)
			communicator:DisconnectAll()
			remoteEvent:Fire(owner, "Ended")
		end
	end
end

function SkillPack:EndSkill(name: string)
	local owner = self.Owner
	local character = owner.Character
	if not character then return end
	local isPlayer = typeof(owner) == "Instance"

	local skill = getSkill(name, self)
	if not skill then return end
	local functions = skill.Functions
	local data = skill.Data

	local tempData = self.TempData
	local activeSkill = tempData.ActiveSkill
	if activeSkill.RequestedForEnd then return end
	local trove = activeSkill.Trove

	local communicator
	if isPlayer then
		if not canEndSkill(tempData, self.Name, name, functions) then
			remoteEvent:Fire(owner, "EndDidntConfirm")
			return
		else
			remoteEvent:Fire(owner, "EndConfirmed")
			communicator = self.Communicator
		end
	end
	activeSkill.RequestedForEnd = true

	if activeSkill.State ~= "ReadyToEnd" then
		repeat task.wait() until activeSkill.State == "ReadyToEnd"
	end
	activeSkill.State = "End"

	tempData.SkillEnding:Fire(self.Name, name)
	local success, err = pcall(functions.End, owner, character, tempData, data, trove, communicator)

	if not success then
		warn("End of skill " .. name .. " of pack " .. self.Name .. " for player " .. owner.Name .. " threw an error: " .. err)
		self:QuickInterrupt(name)
	else
		if isPlayer then
			self.CooldownStore:Start(name)
			communicator:DisconnectAll()
			remoteEvent:Fire(owner, "Ended")
		end

		tempData.ActiveSkill = nil
		tempData.SkillEnded:Fire(self.Name, name, "End")
	end
end

function SkillPack:QuickInterrupt(name:string)
	local owner = self.Owner
	local isPlayer = typeof(owner) == "Instance"
	local tempData = self.TempData
	local trove = tempData.ActiveSkill.Trove

	trove:Clean()
	if isPlayer then
		self.CooldownStore:Start(name)
		self.Communicator:DisconnectAll()
		remoteEvent:Fire(owner, "Interrupt")
	end

	tempData.ActiveSkill = nil
	tempData.SkillEnded:Fire(self.Name, name, "Start", false)
end

function SkillPack:InterruptSkill(name: string, ignoreChecks: boolean)
	local owner = self.Owner
	local character = owner.Character
	local tempData = self.TempData
	local isPlayer = typeof(owner) == "Instance"

	local skill = getSkill(name, self)
	local data = skill.Data
	local functions = skill.Functions

	local activeSkill = tempData.ActiveSkill
	local trove = activeSkill.Trove

	local communicator
	if isPlayer then
		if not ignoreChecks and not canInterruptSkill(tempData, self.Name, name, data) then
			return
		else
			remoteEvent:Fire(owner, "Interrupt")
			communicator = self.Communicator
		end
	end

	local interruptFunction = functions.Interrupt
	if interruptFunction then
		tempData.SkillInterrupting:Fire(self.Name, name)
		local success, err = pcall(interruptFunction, owner, character, tempData, data, trove, communicator)

		if not success then
			warn("Interrupt of " .. name .. "_" .. self.Name .. " for player " .. owner.Name .. " threw an error: " .. err)
			trove:Clean()
		end
		tempData.SkillEnded:Fire(self.Name, name, "Interrupt", success)
	else
		trove:Clean()
		tempData.SkillEnded:Fire(self.Name, name, "Interrupt", true)
	end

	if isPlayer then
		self.CooldownStore:Start(name)
		communicator:DisconnectAll()
	end
	tempData.ActiveSkill = nil
end

--// SKILL PACK FUNCTIONS
local function makeSkillPack(name: string): SkillPack
	local storedSkills = SkillStore[name]
	if not storedSkills then
		error("Skill pack " .. name .. " not found")
	end

	local skills = {}
	for skillName, properties in storedSkills do
		skills[skillName] = {
			Data = Utilities.DeepTableClone(properties.Data),
			Functions = properties.Functions,
		}
	end

	return setmetatable({
		Name = name,
		Skills = skills
	}, SkillPack)
end

--// MODULE FUNCTIONS
function SkillLibrary.GiveSkillPack(name: string, player: Player | {}, tempData: {})
	local existingPacks = tempData.SkillPacks
	if existingPacks[name] then
		warn("Player " .. player.Name .. " already has skill pack " .. name)
		return
	end

	local pack = makeSkillPack(name)
	pack.Owner = player
	pack.TempData = tempData
	if typeof(player) == "Instance" then
		pack.Communicator = Communicator.new(player)

		local cooldownStore = CooldownStore.new()
		pack.CooldownStore = cooldownStore
		addCooldowns(cooldownStore, pack.Skills)
	end

	existingPacks[name] = pack

	return pack
end

function SkillLibrary.TakeSkillPack(name: string, player: Player, tempData: {})
	local existingPacks = tempData.SkillPacks

	local pack = existingPacks[name]
	if not pack then
		warn("Player " .. player.Name .. " doesnt have skill pack " .. name)
	end

	local activeSkill = tempData.ActiveSkill
	if activeSkill then
		pack:InterruptSkill(activeSkill.Name)
	end

	existingPacks[name] = nil
end

function SkillLibrary.GetSkillsKeybindsInfo(packName: string)
	local storedSkills = SkillStore[packName]
	if not storedSkills then
		warn("Skill pack " .. packName .. " not found")
	end

	local keybindsInfo = {}
	for skillName, properties in storedSkills do
		local data = properties.Data
		local functions = properties.Functions

		keybindsInfo[skillName] = {
			if functions.End then true else false,
			data.Cooldown,
			data.InputKey,
			data.InputState,
			data.ClickFrame,
			data.HoldDuration,
			data.NotDisplay
		}
	end

	return keybindsInfo
end

function SkillLibrary.MakeSkillEvents(tempData: {})
	tempData.SkillStarting = Signal.new()
	tempData.SkillEnding = Signal.new()
	tempData.SkillInterrupting = Signal.new()
	tempData.SkillEnded = Signal.new()
end

--// EVENTS
remoteEvent:On("Start", function(player: Player, packName: string, skillName: string)
	local tempData = TempData.Get(player)
	local pack = getSkillPack(player, tempData, packName)
	pack:StartSkill(skillName)
end)
remoteEvent:On("End", function(player: Player, packName: string, skillName: string)
	local tempData = TempData.Get(player)
	local pack = getSkillPack(player, tempData, packName)
	pack:EndSkill(skillName)
end)

return SkillLibrary
