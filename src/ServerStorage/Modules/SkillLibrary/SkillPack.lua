--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

--// MODULES
local SharedModules = ReplicatedStorage.Modules
local CooldownStore = require(SharedModules.CooldownStore)
local Utilities = require(SharedModules.Utilities)

local ServerModules = ServerStorage.Modules
local TempData = require(ServerModules.TempData)

local Store = require(script.Parent.Store)
local Communicator = require(script.Parent.Communicator)
local CallValidator = require(script.Parent.CallValidator)

--// PACKAGES
local Packages = ReplicatedStorage.Packages
local Red = require(Packages.Red)
local Trove = require(Packages.Trove)

--// TYPES
type Skill = {
	Data: { [string]: any },
	Functions: {
		Start: (owner: Player, character: Model, tempData: {}, skillData: {}, trove: {}, event: Communicator.Event, any) -> (),
		End: (owner: Player, character: Model, tempData: {}, skillData: {}, trove: {}, event: Communicator.Event) -> (),
		Interrupt: (owner: Player, character: Model, tempData: {}, skillData: {}, trove: {}, event: Communicator.Event) -> ()
	}
}
type SkillPack = {
	Name: string,
	Owner: Player | {},
	TempData: {},
	Skills: { [string]: Skill },
	CooldownStore: CooldownStore.CooldownStore,
	Communicator: Communicator.Communicator,

	StartSkill: (self: SkillPack, name: string, any) -> (),
	EndSkill: (self: SkillPack, name: string) -> (),
	InterruptSkill: (self: SkillPack, name: string, ignoreChecks: boolean) -> ()
}

--// CLASSES
local SkillPack: SkillPack = {}
SkillPack.__index = SkillPack

--// VARIABLES
local remoteEvent = Red.Server("SkillControl")

--// FUNCTIONS
local function getSkillPack(player: Player, tempData: {}, name: string)
	local pack = tempData.SkillPacks[name]
	if not pack then
		error("Player " .. player.Name .. " doesnt have skill pack " .. name)
	else
		return pack
	end
end

local function makeActiveSkill(packName: string, trove: {}, event: Communicator.Event?, notBlockOtherSkills: boolean)
	local startTime = tick()
	local activeSkill = {
		PackName = packName,
		State = "Start",
		StartTime = startTime,
		Trove = trove,
		Event = event,
		NotBlockOtherSkills = notBlockOtherSkills
	}
	return startTime, activeSkill
end

local function delaySkillEnd(activeSkills: {}, skillName: string, identifier: string, duration: number, pack: {}, startTime: number)
	task.delay(duration, function()
		local activeSkill = activeSkills[identifier]
		if activeSkill and startTime == activeSkill.StartTime then
			pack:EndSkill(skillName)
		end
	end)
end

local function unblockOtherSkills(activeSkills: {}, tempData: {})
	for _, properties in activeSkills do
		if not properties.NotBlockOtherSkills then
			return
		end
	end
	tempData.BlockOtherSkills = false
end

--// SKILL PACK FUNCTIONS
function SkillPack:StartSkill(name: string, ...: any)
	local owner = self.Owner
	local character = owner.Character
	if not character then return end

	local skill = self:GetSkill(name)

	local tempData = self.TempData
	local cooldownStore = tempData.CooldownStore
	local identifier = self.Name .. "_" .. name
	local isPlayer = not tempData.IsNpc
	if not CallValidator.Start(tempData, cooldownStore, name, identifier) then
		if isPlayer then
			remoteEvent:Fire(owner, "StartDidntConfirm", self.Name, name)
		end
		return
	elseif isPlayer then
		remoteEvent:Fire(owner, "StartConfirmed", self.Name, name)
	end

	local communicator, event
	if isPlayer then
		communicator = self.Communicator
		event = communicator:CreateEvent(identifier)
	end

	local skillData = skill.Data
	local notBlockOtherSkills = skillData.NotBlockOtherSkills
	if not notBlockOtherSkills then
		tempData.BlockOtherSkills = true
	end

	local trove = Trove.new()
	local startTime, activeSkill = makeActiveSkill(self.Name, trove, event, notBlockOtherSkills)
	local activeSkills = tempData.ActiveSkills
	activeSkills[identifier] = activeSkill

	local duration = skillData.Duration
	local skillFunctions = skill.Functions
	local hasEnd = skillFunctions.End
	if duration and hasEnd then
		delaySkillEnd(activeSkills, name, identifier, duration, self, startTime)
	end

	local success, err = pcall(skillFunctions.Start, owner, character, tempData, skillData, trove, event, ...)
	if not success then
		warn("Start of " .. identifier .. " for " .. owner.Name .. " threw an error: " .. err)
		
		local humanoid = character.Humanoid
		if owner.Parent == Players and (not humanoid or humanoid.Health >= 0) then
			self:InterruptSkill(name, true)
		end
	elseif hasEnd then
		activeSkill.State = "ReadyToEnd"
	else
		activeSkills[identifier] = nil
		unblockOtherSkills(activeSkills, tempData)

		cooldownStore:Start(name)

		if isPlayer then
			communicator:DestroyEvent(identifier)
			remoteEvent:Fire(owner, "Finished", self.Name, name)
		end
	end
end

function SkillPack:EndSkill(name: string)
	local owner = self.Owner
	local character = owner.Character
	if not character then return end

	local skill = self:GetSkill(name)

	local tempData = self.TempData
	local activeSkills = tempData.ActiveSkills
	local identifier = self.Name .. "_" .. name
	local activeSkill = activeSkills[identifier]
	local skillFunctions = skill.Functions
	local isPlayer = not tempData.IsNpc
	if not CallValidator.End(activeSkill, skillFunctions) then
		if isPlayer then
			remoteEvent:Fire(owner, "EndDidntConfirm", self.Name, name)
		end
		return
	elseif isPlayer then
		remoteEvent:Fire(owner, "EndConfirmed", self.Name, name)
	end

	activeSkill.RequestedForEnd = true
	if activeSkill.State ~= "ReadyToEnd" then
		repeat
			task.wait()
		until activeSkill.State == "ReadyToEnd"
	end
	activeSkill.State = "End"

	local communicator, event
	if isPlayer then
		communicator = self.Communicator
		event = activeSkill.Event
	end

	local success, err = pcall(skillFunctions.End, owner, character, tempData, skill.Data, activeSkill.Trove, event)
	if not success then
		warn("End of " .. identifier .. " for " .. owner.Name .. " threw an error: " .. err)
		
		local humanoid = character.Humanoid
		if owner.Parent == Players and (not humanoid or humanoid.Health >= 0) then
			self:InterruptSkill(name, true)
		end
	else
		activeSkills[identifier] = nil
		unblockOtherSkills(activeSkills, tempData)

		self.CooldownStore:Start(name)

		if isPlayer then
			communicator:DestroyEvent(identifier)
			remoteEvent:Fire(owner, "Finished", self.Name, name)
		end
	end
end

function SkillPack:InterruptSkill(name: string, ignoreChecks: boolean)
	local skill = self:GetSkill(name)

	local tempData = self.TempData
	local activeSkills = tempData.ActiveSkills
	local identifier = self.Name .. "_" .. name
	local activeSkill = activeSkills[identifier]
	local owner = self.Owner
	local skillData = skill.Data
	local isPlayer = not tempData.IsNpc
	if not CallValidator.Interrupt(ignoreChecks, activeSkill, skillData) then
		return
	elseif isPlayer then
		remoteEvent:Fire(owner, "Interrupt", self.Name, name)
	end

	local communicator, event
	if isPlayer then
		communicator = self.Communicator
		event = activeSkill.Event
	end

	local interruptFunction = skill.Functions.Interrupt
	local trove = activeSkill.Trove
	if interruptFunction then
		local character = owner.Character
		local success, err = pcall(interruptFunction, owner, character, tempData, skillData, trove, event)

		if not success then
			warn("Interrupt of " .. identifier .. " for " .. owner.Name .. " threw an error: " .. err)
			trove:Clean()
		end
	else
		trove:Clean()
	end

	activeSkills[identifier] = nil
	unblockOtherSkills(activeSkills, tempData)

	self.CooldownStore:Start(name)

	if isPlayer then
		communicator:DestroyEvent(identifier)
	end
end

function SkillPack:GetSkill(name: string)
	local skill = self.Skills[name]
	if not skill then
		error("Skill " .. name .. " not found in skill pack " .. self.Name .. " for player " .. self.Owner.Name)
	else
		return skill
	end
end

--// EVENTS
remoteEvent:On("Start", function(player: Player, packName: string, skillName: string, additionalData: any)
	local tempData = TempData.Get(player)
	local pack = getSkillPack(player, tempData, packName)
	pack:StartSkill(skillName, additionalData)
end)
remoteEvent:On("End", function(player: Player, packName: string, skillName: string)
	local tempData = TempData.Get(player)
	local pack = getSkillPack(player, tempData, packName)
	pack:EndSkill(skillName)
end)

--// MODULE FUNCTIONS
return {
	new = function(name: string, owner: Player | {}, tempData: {}): SkillPack
		local storedPack = Store[name]
		if not storedPack then
			error("Skill pack " .. name .. " not found")
		end

		local cooldownStore = tempData.CooldownStore
		if not cooldownStore then
			cooldownStore = CooldownStore.new()
			tempData.CooldownStore = cooldownStore
		end

		local communicator
		if not tempData.IsNpc then
			communicator = tempData.Communicator
			if not communicator then
				communicator = Communicator.new(owner)
				tempData.Communicator = communicator
			end
		end	

		local skills = {}
		for skillName, properties in storedPack do
			skills[skillName] = {
				Data = Utilities.DeepTableClone(properties.Data),
				Functions = properties.Functions,
			}
			cooldownStore:Add(skillName, properties.Data.Cooldown)
		end

		return setmetatable({
			Name = name,
			Owner = owner,
			TempData = tempData,
			Skills = skills,
			CooldownStore = cooldownStore,
			Communicator = communicator
		}, SkillPack)
	end
}