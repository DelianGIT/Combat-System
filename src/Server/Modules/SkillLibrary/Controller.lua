--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

--// MODULES
local SharedModules = ReplicatedStorage.Modules
local CooldownStore = require(SharedModules.CooldownStore)
local Utility = require(SharedModules.Utility)

local ServerModules = ServerStorage.Modules
local TempData = require(ServerModules.TempData)

local Store = require(script.Parent.Store)
local Communicator = require(script.Parent.Communicator)
local Validator = require(script.Parent.Validator)

--// PACKAGES
local Packages = ReplicatedStorage.Packages
local Trove = require(Packages.Trove)

--// TYPES
type FunctionArgs = {
	Player: Player | {},
	Character: Model,
	TempData: {},
	SkillData: { [string]: any },
	Pack: SkillPack,
	Trove: {},
	Event: Communicator.Event?,
}
type Skill = {
	Data: { [string]: any },
	Functions: {
		PreStart: (args: FunctionArgs, any) -> any | "Cancel",
		Start: (args: FunctionArgs, any) -> (),
		PreEnd: (args: FunctionArgs, any) -> any,
		End: (args: FunctionArgs, any) -> (),
		Interrupt: (args: FunctionArgs) -> (),
	},
}
type SkillPack = {
	Name: string,
	Owner: Player | {},
	TempData: {},
	Skills: { [string]: Skill },
	Communicator: Communicator.Communicator,
	CooldownStore: CooldownStore.CooldownStore,

	StartSkill: (self: SkillPack, name: string, any) -> (),
	EndSkill: (self: SkillPack, name: string, any) -> (),
	InterruptSkill: (self: SkillPack, name: string, ignoreChecks: boolean) -> (),
}

--// CLASSES
local SkillPack: SkillPack = {}
SkillPack.__index = SkillPack

--// VARIABLES
local remoteEvents = ReplicatedStorage.Events
local remoteEvent = require(remoteEvents.SkillControl):Server()

--// FUNCTIONS
local function getSkillPack(player: Player, tempData: {}, name: string)
	local pack = tempData.SkillPacks[name]
	if not pack then
		error("Player " .. player.Name .. " doesnt have skill pack " .. name)
	else
		return pack
	end
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
	if not character then
		return
	end

	local skill = self:GetSkill(name)
	local skillData = skill.Data
	local identifier = self.Name .. "_" .. name

	local tempData = self.TempData
	local cooldownStore = self.CooldownStore
	if not Validator.Start(name, identifier, tempData, skillData, cooldownStore) then
		if not tempData.IsNpc then
			remoteEvent:Fire(owner, "StartNotValid", self.Name, name)
		end
		return
	end

	local skillFunctions = skill.Functions
	local preStartFunction = skillFunctions.PreStart
	local result
	if preStartFunction then
		result = preStartFunction({
			Player = owner,
			Character = character,
			TempData = tempData,
			SkillData = skillData,
		}, ...)
		if result == "Cancel" then
			remoteEvent:Fire(owner, "StartNotValid", self.Name, name)
			return
		end
	end

	if not tempData.IsNpc then
		if result then
			remoteEvent:Fire(owner, "StartValid", self.Name, name, result)
		else
			remoteEvent:Fire(owner, "StartValid", self.Name, name)
		end
	end

	local communicator = self.Communicator
	local event
	if communicator then
		event = communicator:CreateEvent(identifier)
	end

	local notBlockOtherSkills = skillData.NotBlockOtherSkills
	if not notBlockOtherSkills then
		tempData.BlockOtherSkills = true
	end

	local trove = Trove.new()
	local startTime = tick()
	local activeSkill = {
		State = "Start",
		StartTime = startTime,
		NotBlockOtherSkills = notBlockOtherSkills,
		Trove = trove,
		Event = event,
	}
	local activeSkills = tempData.ActiveSkills
	activeSkills[identifier] = activeSkill

	local duration = skillData.Duration
	local hasEnd = skillFunctions.End
	if duration and hasEnd then
		task.delay(duration, function()
			activeSkill = activeSkills[identifier]
			if activeSkill and startTime == activeSkill.StartTime then
				self:EndSkill(name)
			end
		end)
	end

	local cooldown = skillData.Cooldown
	local cooldownType = cooldown.Type
	if cooldownType == "Begin" then
		cooldownStore:Start(name)
	end

	task.spawn(function(...)
		local success, err = pcall(skillFunctions.Start, {
			Player = owner,
			Character = character,
			TempData = tempData,
			SkillData = skillData,
			Pack = self,
			Trove = trove,
			Event = event,
		}, ...)

		if not success then
			warn("Start of " .. identifier .. " for " .. owner.Name .. " threw an error: " .. err)

			local humanoid = character.Humanoid
			if humanoid.Health >= 0 then
				if not tempData.IsNpc then
					if owner.Parent == Players then
						self:InterruptSkill(name, true)
					end
				else
					self:InterruptSkill(name, true)
				end
			end
		elseif hasEnd then
			activeSkill.State = "ReadyToEnd"
		else
			activeSkills[identifier] = nil
			unblockOtherSkills(activeSkills, tempData)

			if cooldownType == "End" then
				cooldownStore:Start(name)
			end

			if not tempData.IsNpc then
				communicator:DestroyEvent(identifier)
				remoteEvent:Fire(owner, "Finished", self.Name, name)
			end
		end
	end, ...)

	return true
end

function SkillPack:EndSkill(name: string, ...: any)
	local owner = self.Owner
	local character = owner.Character
	if not character then
		return
	end

	local skill = self:GetSkill(name)
	local skillFunctions = skill.Functions
	local identifier = self.Name .. "_" .. name

	local tempData = self.TempData
	local activeSkills = tempData.ActiveSkills
	local activeSkill = activeSkills[identifier]
	if not Validator.End(activeSkill, skillFunctions) then
		if not tempData.IsNpc then
			remoteEvent:Fire(owner, "EndNotValid", self.Name, name)
		end
		return
	end

	activeSkill.RequestedForEnd = true
	if activeSkill.State ~= "ReadyToEnd" then
		repeat
			task.wait()
		until activeSkill.State == "ReadyToEnd"
	end
	activeSkill.State = "End"

	local skillData = skill.Data
	local preEndFunction = skillFunctions.PreEnd
	local result
	if preEndFunction then
		result = preEndFunction({
			Player = owner,
			Character = character,
			TempData = tempData,
			SkillData = skillData,
		}, ...)
	end

	if not tempData.IsNpc then
		if result then
			remoteEvent:Fire(owner, "EndValid", self.Name, name, result)
		else
			remoteEvent:Fire(owner, "EndValid", self.Name, name)
		end
	end

	local communicator = self.Communicator
	local event
	if communicator then
		event = activeSkill.Event
	end

	task.spawn(function(...)
		local success, err = pcall(skillFunctions.End, {
			Player = owner,
			Character = character,
			TempData = tempData,
			SkillData = skillData,
			Pack = self,
			Trove = activeSkill.Trove,
			Event = event,
		}, ...)

		if not success then
			warn("End of " .. identifier .. " for " .. owner.Name .. " threw an error: " .. err)

			local humanoid = character.Humanoid
			if humanoid.Health >= 0 then
				if not tempData.IsNpc then
					if owner.Parent == Players then
						self:InterruptSkill(name, true)
					end
				else
					self:InterruptSkill(name, true)
				end
			end
		else
			activeSkills[identifier] = nil
			unblockOtherSkills(activeSkills, tempData)

			if skillData.Cooldown.Type == "End" then
				self.CooldownStore:Start(name)
			end

			if not tempData.IsNpc then
				communicator:DestroyEvent(identifier)
				remoteEvent:Fire(owner, "Finished", self.Name, name)
			end
		end
	end, ...)

	return true
end

function SkillPack:InterruptSkill(name: string, ignoreChecks: boolean)
	local owner = self.Owner
	local character = owner.Character
	if not character and not ignoreChecks then
		return
	end

	local skill = self:GetSkill(name)
	local skillData = skill.Data
	local identifier = self.Name .. "_" .. name

	local tempData = self.TempData
	local activeSkills = tempData.ActiveSkills
	local activeSkill = activeSkills[identifier]
	if not Validator.Interrupt(ignoreChecks, activeSkill, skillData) then
		return
	end

	if not tempData.IsNpc then
		remoteEvent:Fire(owner, "Interrupted", self.Name, name)
	end

	local communicator = self.Communicator
	local event
	if communicator then
		event = activeSkill.Event
	end

	local interruptFunction = skill.Functions.Interrupt
	if interruptFunction then
		task.spawn(function(...)
			local trove = activeSkill.Trove
			local success, err = pcall(interruptFunction, {
				Player = owner,
				Character = character,
				TempData = tempData,
				SkillData = skillData,
				Pack = self,
				Trove = trove,
				Event = event,
			}, ...)

			if not success then
				warn("Interrupt of " .. identifier .. " for " .. owner.Name .. " threw an error: " .. err)
				trove:Clean()
			end
		end)
	else
		activeSkill.Trove:Clean()
	end

	activeSkills[identifier] = nil
	unblockOtherSkills(activeSkills, tempData)

	if skillData.Cooldown.Type == "End" then
		self.CooldownStore:Start(name)
	end

	if event then
		communicator:DestroyEvent(identifier)
	end

	return true
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
remoteEvent:On(function(player: Player, action: string, packName: string, skillName: string, additionalData: any)
	local tempData = TempData.Get(player)
	local pack = getSkillPack(player, tempData, packName)

	if action == "Start" then
		pack:StartSkill(skillName, additionalData)
	elseif action == "End" then
		pack:EndSkill(skillName, additionalData)
	end
end)

--// MODULE FUNCTIONS
return {
	MakeSkillPack = function(name: string, owner: Player | {}, tempData: {}): SkillPack
		local storedPack = Store[name]
		if not storedPack then
			warn("Skill pack " .. name .. " not found")
			return
		end

		local communicator
		if not tempData.IsNpc then
			communicator = tempData.Communicator
			if not communicator then
				communicator = Communicator.new(owner)
				tempData.Communicator = communicator
			end
		end

		local cooldownStore = CooldownStore.new()
		local skills = {}
		for skillName, properties in storedPack do
			local data = properties.Data
			skills[skillName] = {
				Data = Utility.DeepTableClone(data),
				Functions = properties.Functions,
			}
			cooldownStore:Add(skillName, data.Cooldown.Duration)
		end

		return setmetatable({
			Name = name,
			Owner = owner,
			TempData = tempData,
			Skills = skills,
			Communicator = communicator,
			CooldownStore = cooldownStore,
		}, SkillPack)
	end,
}
