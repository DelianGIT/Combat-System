--// SERVICES
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// MODULES
local Modules = ReplicatedStorage.Modules
local SharedModules = Modules.Shared
local CooldownStore = require(SharedModules.CooldownStore)

local ServerModules = ServerStorage.Modules
local Utilities = require(ServerModules.Utilities)
local TempData = require(ServerModules.TempData)

local SkillStore = require(script.SkillStore)
local Communicator = require(script.Communicator)

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

	StartSkill: (self: SkillPack, name: string) -> (),
	EndSkill: (self: SkillPack, name: string) -> (),
	InterruptSkill: (self: SkillPack, name: string) -> (),
}

--// CLASSES
local SkillPack: SkillPack = {}
SkillPack.__index = SkillPack

--// VARIABLES
local remoteEvent = Red.Server("SkillControl")

--// FUNCTIONS
local function getSkill(name: string, pack: SkillPack): Skill
	local skill = pack.Skills[name]
	if not skill then
		error("Skill " .. name .. " not found in skill pack " .. pack.Name .. " for player " .. pack.Owner.Name)
	else
		return skill
	end
end

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

	if activeSkill.PackName ~= packName or activeSkill.SkillName ~= skillName then
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

local function getSkillPack(player: Player, tempData: { [string]: any }, name: string)
	local pack = tempData.SkillPacks[name]
	if not pack then
		error("Player " .. player.Name .. " doesnt have skill pack " .. name)
	else
		return pack
	end
end

--// SKILL PACK FUNCTIONS
local function makeSkillPack(name: string, forPlayer: boolean)
	local pack = SkillStore[name]
	if not pack then
		error("Skill pack " .. name .. " not found")
	end

	local cooldownStore
	local skills = {}

	if forPlayer then
		cooldownStore = CooldownStore.new()

		for skillName, skill in pack do
			skills[skillName] = {
				Data = Utilities.DeepTableClone(skill.Data),
				Functions = skill.Functions,
			}
			cooldownStore:Add(skillName, skill.Data.Cooldown)
		end
	else
		for skillName, skill in pack do
			skills[skillName] = {
				Data = Utilities.DeepTableClone(skill.Data),
				Functions = skill.Functions,
			}
		end
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
	local hasEnd = if functions.End then true else false

	local owner = self.Owner
	local tempData = self.TempData
	local isPlayer = typeof(owner) == "Instance"
	local character = owner.Character
	if not character then return end

	local trove = Trove.new()
	local cooldownStore, communicator
	if isPlayer then
		cooldownStore = self.CooldownStore

		if not isSkillCanBeStarted(tempData, name, cooldownStore) then
			remoteEvent:Fire(owner, "StartDidntConfirm")
			return
		else
			remoteEvent:Fire(owner, "StartConfirmed")
		end

		communicator = Communicator.new(owner)
	end

	local startTime = tick()
	local activeSkill = {
		SkillName = name,
		PackName = self.Name,
		Skill = skill,
		State = "Start",
		StartTime = startTime,
		Trove = trove
	}
	tempData.ActiveSkill = activeSkill

	local duration = data.Duration
	if duration and hasEnd then
		task.delay(duration, function()
			local currentActiveSkill = tempData.ActiveSkill
			if currentActiveSkill and startTime == currentActiveSkill.StartTime then
				self:EndSkill(name)
			end
		end)
	end

	local success, err = pcall(functions.Start, owner, character, tempData, data, trove, communicator)

	if not success then
		warn("Start of skill " .. name .. " of pack " .. self.Name .. " for player " .. owner.Name .. " threw an error: " .. err)
		tempData.ActiveSkill = nil
		trove:Clean()

		if isPlayer then
			cooldownStore:Start(name)
			communicator:DisconnectAll()
			remoteEvent:Fire(owner, "Ended")
		end
	elseif hasEnd then
		activeSkill.State = "ReadyToEnd"
	else
		tempData.ActiveSkill = nil

		if isPlayer then
			cooldownStore:Start(name)
			communicator:DisconnectAll()
			remoteEvent:Fire(owner, "Ended")
		end
	end
end

function SkillPack:EndSkill(name: string)
	local skill = getSkill(name, self)
	local data = skill.Data
	local functions = skill.Functions

	local owner = self.Owner
	local tempData = self.TempData
	local isPlayer = typeof(owner) == "Instance"
	local character = owner.Character
	if not character then return end
	
	local activeSkill = tempData.ActiveSkill
	if activeSkill.RequestedForEnd then return end

	local trove = activeSkill.Trove
	local communicator
	if isPlayer then
		communicator = self.Communicator
	
		if not isSkillCanBeEnded(tempData, self.Name, name, functions) then
			remoteEvent:Fire(owner, "EndDidntConfirm")
			return
		else
			remoteEvent:Fire(owner, "EndConfirmed")
		end
	end
	activeSkill.RequestedForEnd = true

	if activeSkill.State ~= "ReadyToEnd" then
		repeat task.wait() until activeSkill.State == "ReadyToEnd"
	end
	activeSkill.State = "End"

	local success, err = pcall(functions.End, owner, character, tempData, data, trove, communicator)
	if not success then
		warn("End of skill " .. name .. " of pack " .. self.Name .. " for player " .. owner.Name .. " threw an error: " .. err)
		trove:Clean()
	end

	if isPlayer then
		self.CooldownStore:Start(name)
		communicator:DisconnectAll()
		remoteEvent:Fire(owner, "Ended")
	end
	tempData.ActiveSkill = nil
end

function SkillPack:InterruptSkill(name: string)
	local skill = getSkill(name, self)
	local data = skill.Data
	local functions = skill.Functions

	local owner = self.Owner
	local tempData = self.TempData
	local activeSkill = tempData.ActiveSkill
	local isPlayer = typeof(owner) == "Instance"
	local character = owner.Character
	if not character then return end

	local trove = activeSkill.Trove
	local communicator
	if isPlayer then
		communicator = self.Communicator

		if not isSkillCanBeInterrupted(tempData, self.Name, name, data) then
			return
		end
	end

	local interruptFunction = functions.Interrupt
	if interruptFunction then
		if isPlayer then
			remoteEvent:Fire(owner, "Interrupt")
		end

		local success, err = pcall(interruptFunction, owner, character, tempData, data, trove, communicator)
		if not success then
			warn("Interrupt of skill " .. name .. " of pack " .. self.Name .. " for player " .. owner.Name .. " threw an error: " .. err)
			trove:Clean()
		end
	else
		trove:Clean()
	end

	if isPlayer then
		self.CooldownStore:Start(name)
		communicator:DisconnectAll()
	end
	tempData.ActiveSkill = nil
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
				data.NotDisplay
			}
		end

		return keybindsInfo
	end,

	GiveSkillPack = function(player: Player | {}, tempData: { [string]: any }, name: string): SkillPack
		local skillPacks = tempData.SkillPacks
		local isPlayer = typeof(player) == "Instance"

		if skillPacks[name] then
			warn("Player " .. player.Name .. " already has skill pack " .. name)
		end

		local pack = makeSkillPack(name, isPlayer)
		pack.Owner = player
		pack.TempData = tempData
		if isPlayer then
			pack.Communicator = Communicator.new(player)
		end

		skillPacks[name] = pack

		return pack
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
	end
}