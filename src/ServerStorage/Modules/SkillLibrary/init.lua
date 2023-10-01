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

local SkillStore = require(script.SkillStore)
local Communicator = require(script.Communicator)
local SkillController = require(script.SkillController)

--// PACKAGES
local Packages = ReplicatedStorage.Packages
local Red = require(Packages.Red)
local Trove = require(Packages.Trove)

--// TYPES
type SkillData = {
	Cooldown: number,
	InputKey: Enum.UserInputType | Enum.KeyCode,
	InputState: "Start" | "End" | "DoubleClick" | "Hold",
	Duration: number?,
}
type SkillFunction = (
	owner: Player | {},
	character: Model,
	tempData: {},
	skillData: SkillData,
	trove: {},
	communicator: Communicator.Communicator
) -> ()
type Skill = {
	Data: SkillData,
	Functions: {
		Start: SkillFunction,
		End: SkillFunction,
		Interrupt: SkillFunction
	},
}
type SkillPack = {
	Name: string,
	Owner: Player,
	TempData: {},
	Skills: { [string]: Skill },
	CooldownStore: CooldownStore.CooldownStore,

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
local function addCooldowns(cooldownStore: CooldownStore.CooldownStore, skills: {[string]: Skill})
	for skillName, properties in skills do
		cooldownStore:Add(skillName, properties.Data.Cooldown)
	end
end

local function makeActiveSkill(packName: string, skillName: string, skill: Skill, trove: {})
	local startTime = tick()
	local activeSkill = {
		SkillName = skillName,
		PackName = packName,
		Skill = skill,
		State = "Start",
		StartTime = startTime,
		Trove = trove,
	}
	return startTime, activeSkill
end

local function delaySkillEnd(name: string, duration: number, pack: SkillPack, startTime: number, tempData: {})
	task.delay(duration, function()
		local currentActiveSkill = tempData.ActiveSkill
		if currentActiveSkill and startTime == currentActiveSkill.StartTime then
			pack:EndSkill(name)
		end
	end)
end

local function getSkillPack(player: Player, tempData: {}, name: string)
	local pack = tempData.SkillPacks[name]
	if not pack then
		error("Player " .. player.Name .. " doesnt have skill pack " .. name)
	else
		return pack
	end
end

local function getSkill(name: string, pack: SkillPack): Skill
	local skill = pack.Skills[name]
	if not skill then
		error("Skill " .. name .. " not found in skill pack " .. pack.Name .. " for player " .. pack.Owner.Name)
	else
		return skill
	end
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

	local cooldownStore = CooldownStore.new()
	addCooldowns(cooldownStore, skills)

	return setmetatable({
		Name = name,
		Skills = skills,
		CooldownStore = cooldownStore
	}, SkillPack)
end

function SkillPack:StartSkill(name: string)
	local owner = self.Owner
	local character = owner.Character
	if not character then
		return
	end

	local skill = getSkill(name, self)

	local isPlayer = typeof(owner) == "Instance"
	local tempData = self.TempData
	local cooldownStore = self.CooldownStore
	if not SkillController.CanStart(name, tempData, cooldownStore) then
		if isPlayer then
			remoteEvent:Fire(owner, "StartDidntConfirm")
		end
		return
	elseif isPlayer then
		remoteEvent:Fire(owner, "StartConfirmed")
	end

	local trove = Trove.new()
	local startTime, activeSkill = makeActiveSkill(self.Name, name, skill, trove)
	tempData.ActiveSkill = activeSkill

	local skillData = skill.Data
	local duration = skillData.Duration
	local skillFunctions = skill.Functions
	local hasEnd = skillFunctions.End
	if duration and hasEnd then
		delaySkillEnd(name, duration, self, startTime, tempData)
	end

	local communicator
	if isPlayer then
		communicator = self.Communicator
		communicator:DisconnectAll()
	end

	local skillEvents = tempData.SkillEvents
	skillEvents.SkillStarting:Fire(self.Name, name)

	local success, err = pcall(skillFunctions.Start, owner, character, tempData, skillData, trove, communicator)
	if not success then
		warn("Start of " .. self.Name .. "_" .. name .. " for " .. owner.Name .. " threw an error: " .. err)
		self:InterruptSkill(name)
	elseif hasEnd then
		activeSkill.State = "ReadyToEnd"
	else
		tempData.ActiveSkill = nil
		skillEvents.SkillEnded:Fire(self.Name, name, "Start")
		cooldownStore:Start(name)

		if isPlayer then
			communicator:DisconnectAll()
			remoteEvent:Fire(owner, "Ended")
		end
	end
end

function SkillPack:EndSkill(name: string)
	local owner = self.Owner
	local character = owner.Character
	if not character then
		return
	end

	local skill = getSkill(name, self)

	local tempData = self.TempData
	local activeSkill = tempData.ActiveSkill
	local skillFunctions = skill.Functions
	local isPlayer = typeof(owner) == "Instance"
	if not SkillController.CanEnd(self.Name, name, activeSkill, skillFunctions) then
		if isPlayer then
			remoteEvent:Fire(owner, "EndDidntConfirm")
		end
		return
	elseif isPlayer then
		remoteEvent:Fire(owner, "EndConfirmed")
	end

	activeSkill.RequestedForEnd = true
	if activeSkill.State ~= "ReadyToEnd" then
		repeat
			task.wait()
		until activeSkill.State == "ReadyToEnd"
	end
	activeSkill.State = "End"

	local skillEvents = tempData.SkillEvents
	skillEvents.SkillEnding:Fire(self.Name, name)

	local skillData = skill.Data
	local trove = Trove.new()
	local communicator = if isPlayer then self.Communicator else nil
	local success, err = pcall(skillFunctions.End, owner, character, tempData, skillData, trove, communicator)
	if not success then
		warn("End of " .. self.Name .. "_" .. name .. " for " .. owner.Name .. " threw an error: " .. err)
		self:InterruptSkill(name)
	else
		tempData.ActiveSkill = nil
		skillEvents.SkillEnded:Fire(self.Name, name, "End")
		self.CooldownStore:Start(name)

		if isPlayer then
			communicator:DisconnectAll()
			remoteEvent:Fire(owner, "Ended")
		end
	end
end

function SkillPack:InterruptSkill(name: string, ignoreChecks: boolean)
	local skill = getSkill(name, self)

	local owner = self.Owner
	local tempData = self.TempData
	local activeSkill = tempData.ActiveSkill
	local skillData = skill.Data
	local isPlayer = typeof(owner) == "Instance"
	if not SkillController.CanInterrupt(ignoreChecks, self.Name, name, activeSkill, skillData) then
		return
	elseif isPlayer then
		remoteEvent:Fire(owner, "Interrupt")
	end

	local skillFunctions = skill.Functions
	local interruptFunction = skillFunctions.Interrupt
	local skillEvents = tempData.SkillEvents
	local trove = activeSkill.Trove
	local communicator = if isPlayer then self.Communicator else nil
	if interruptFunction then
		skillEvents.SkillInterrupting:Fire(self.Name, name)

		local character = owner.Character
		local success, err = pcall(interruptFunction, owner, character, tempData, skillData, trove, communicator)

		if not success then
			warn("Interrupt of " .. self.Name .. "_" .. name .. " for " .. owner.Name .. " threw an error: " .. err)
			trove:Clean()
		end
	else
		trove:Clean()
	end

	tempData.ActiveSkill = nil
	skillEvents.SkillEnded:Fire(self.Name, name, "Interrupt")
	self.CooldownStore:Start(name)

	if isPlayer then
		communicator:DisconnectAll()
	end
end

--// MODULE FUNCTIONS
function SkillLibrary.GiveSkillPack(name: string, player: Player | {}, tempData: {}): SkillPack
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
	end

	existingPacks[name] = pack

	return pack
end

function SkillLibrary.TakeSkillPack(name: string, player: Player, tempData: {})
	local existingPacks = tempData.SkillPacks

	local pack = existingPacks[name]
	if not pack then
		warn("Player " .. player.Name .. " doesn't have skill pack " .. name)
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
			data.HoldDuration
		}
	end

	return keybindsInfo
end

function SkillLibrary.MakeSkillEvents(tempData: {})
	local skillEvents = {}
	skillEvents.SkillStarting = Signal.new()
	skillEvents.SkillEnding = Signal.new()
	skillEvents.SkillInterrupting = Signal.new()
	skillEvents.SkillEnded = Signal.new()
	tempData.SkillEvents = skillEvents
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