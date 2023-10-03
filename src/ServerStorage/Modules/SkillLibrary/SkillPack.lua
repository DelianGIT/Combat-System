--// SERVICES
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// MODULES
local SharedModules = ReplicatedStorage.Modules
local CooldownStore = require(SharedModules.CooldownStore)

local ServerModules = ServerStorage.Modules
local Utilities = require(ServerModules.Utilities)
local TempData = require(ServerModules.TempData)

local Communicator = require(script.Parent.Communicator)
local UseController = require(script.Parent.UseController)
local SkillPacksStore = require(script.Parent.SkillPacksStore)

--// PACKAGES
local Packages = ReplicatedStorage.Packages
local Red = require(Packages.Red)
local Trove = require(Packages.Trove)

--// TYPES
type SkillFunction = (
	owner: Player | {},
	character: Model,
	tempData: {},
	skillData: {},
	trove: {},
	communicator: Communicator.Communicator
) -> ()
type Skill = {
	Data: {},
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

	StartSkill: (self: SkillPack, name: string) -> (),
	EndSkill: (self: SkillPack, name: string) -> (),
	InterruptSkill: (self: SkillPack, name: string, ignoreChecks: boolean) -> (),
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

local function getSkill(name: string, pack: SkillPack)
	local skill = pack.Skills[name]
	if not skill then
		error("Skill " .. name .. " not found in skill pack " .. pack.Name .. " for player " .. pack.Owner.Name)
	else
		return skill
	end
end

local function makeActiveSkill(packName: string, trove: {}, communicator: Communicator.Communicator?, notBlockOtherSkills: boolean)
	local startTime = tick()
	local activeSkill = {
		PackName = packName,
		State = "Start",
		StartTime = startTime,
		Trove = trove,
		Communicator = communicator,
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
function SkillPack:StartSkill(name: string, additionalData: any)
	local owner = self.Owner
	local character = owner.Character
	if not character then
		return
	end
	
	local skill = getSkill(name, self)

	local skillData = skill.Data
	local isPlayer = typeof(owner) == "Instance"
	local tempData = self.TempData
	local cooldownStore = self.CooldownStore
	local identifier = self.Name .. "_" .. name
	if not UseController.CanStart(name, identifier, tempData, cooldownStore) then
		if isPlayer then
			remoteEvent:Fire(owner, "StartDidntConfirm", self.Name, name)
		end
		return
	elseif isPlayer then
		remoteEvent:Fire(owner, "StartConfirmed", self.Name, name)
	end

	local communicator
	if isPlayer then
		communicator = Communicator.new(identifier, owner)
	end

	local notBlockOtherSkills = skillData.NotBlockOtherSkills
	if not notBlockOtherSkills then
		tempData.BlockOtherSkills = true
	end

	local trove = Trove.new()
	local startTime, activeSkill = makeActiveSkill(self.Name, trove, communicator, notBlockOtherSkills)
	local activeSkills = tempData.ActiveSkills
	activeSkills[identifier] = activeSkill

	local duration = skillData.Duration
	local skillFunctions = skill.Functions
	local hasEnd = skillFunctions.End
	if duration and hasEnd then
		delaySkillEnd(activeSkills, name, identifier, duration, self, startTime)
	end

	local success, err = pcall(skillFunctions.Start, owner, character, tempData, skillData, trove, communicator, additionalData)
	if not success then
		warn("Start of " .. identifier " for " .. owner.Name .. " threw an error: " .. err)
		self:InterruptSkill(name, true)
	elseif hasEnd then
		activeSkill.State = "ReadyToEnd"
	else
		activeSkills[identifier] = nil
		unblockOtherSkills(activeSkills, tempData)

		cooldownStore:Start(name)

		if isPlayer then
			communicator:Destroy()
			remoteEvent:Fire(owner, "Ended", self.Name, name)
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
	local activeSkills = tempData.ActiveSkills
	local identifier = self.Name .. "_" .. name
	local activeSkill = activeSkills[identifier]

	local skillFunctions = skill.Functions
	local isPlayer = typeof(owner) == "Instance"
	if not UseController.CanEnd(activeSkill, skillFunctions) then
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

	local communicator = if isPlayer then activeSkill.Communicator else nil
	local success, err = pcall(skillFunctions.End, owner, character, tempData, skill.Data, activeSkill.Trove, communicator)
	if not success then
		warn("End of " .. identifier .. " for " .. owner.Name .. " threw an error: " .. err)
		self:InterruptSkill(name, true)
	else
		activeSkills[identifier] = nil
		unblockOtherSkills(activeSkills, tempData)

		self.CooldownStore:Start(name)

		if isPlayer then
			communicator:Destroy()
			remoteEvent:Fire(owner, "Ended", self.Name, name)
		end
	end
end

function SkillPack:InterruptSkill(name: string, ignoreChecks: boolean)
	local skill = getSkill(name, self)

	local tempData = self.TempData
	local activeSkills = tempData.ActiveSkills
	local identifier = self.Name .. "_" .. name
	local activeSkill = activeSkills[identifier]

	local owner = self.Owner
	local skillData = skill.Data
	local isPlayer = typeof(owner) == "Instance"
	if not UseController.CanInterrupt(ignoreChecks, activeSkill, skillData) then
		return
	elseif isPlayer then
		remoteEvent:Fire(owner, "Interrupt", self.Name, name)
	end

	local interruptFunction = skill.Functions.Interrupt
	local trove = activeSkill.Trove
	local communicator = if isPlayer then self.Communicator else nil
	if interruptFunction then
		local character = owner.Character
		local success, err = pcall(interruptFunction, owner, character, tempData, skillData, trove, communicator)

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
		communicator:Destroy()
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
	new = function(name: string, owner: Player | {}, tempData: {})
		local storedPack = SkillPacksStore[name]
		if not storedPack then
			error("Skill pack " .. name .. " not found")
		end
	
		local cooldownStore = CooldownStore.new()

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
			CooldownStore = cooldownStore
		}, SkillPack)
	end
}