--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local Players = game:GetService("Players")

--// MODULES
local ClientModules = ReplicatedFirst.Modules
local Keybind = require(ClientModules.Keybind)

local SharedModules = ReplicatedStorage.Modules
local CooldownStore = require(SharedModules.CooldownStore)
local Utility = require(SharedModules.Utility)

local Controller = require(script.Controller)
local Store = require(script.Store)
local GuiList = require(script.GuiList)

--// VARIABLES
local player = Players.LocalPlayer

local skillPacksItems = ReplicatedStorage.Items.SkillPacks

local remoteEvents = ReplicatedStorage.Events
local remoteEvent = require(remoteEvents.SkillLibrary):Client()

local skillPacks = Controller.SkillPacks
local activeSkills = Controller.ActiveSkills
local SkillLibrary = {}

--// FUNCTIONS
local function toggleKeybinds(packName: string, enabled: boolean)
	local pack = skillPacks[packName]

	if enabled then
		for _, keybinds in pack.Keybinds do
			keybinds[1]:Enable()
			keybinds[2]:Enable()
		end
	else
		for _, keybinds in pack.Keybinds do
			keybinds[1]:Disable()
			keybinds[2]:Disable()
		end
	end
end

local function giveSkillPackItem(backpack: Backpack, packName: string, guiList: {})
	local item = skillPacksItems[packName]:Clone()

	item.Equipped:Connect(function()
		toggleKeybinds(packName, true)
		guiList:Open()
	end)

	item.Unequipped:Connect(function()
		toggleKeybinds(packName, false)
		guiList:Close()

		for identifier, properties in activeSkills do
			local splittedString = string.split(identifier, "_")
			if splittedString[1] == packName and properties.State == "ReadyToEnd" then
				Controller.RequestEnd(packName, splittedString[2])
			end
		end
	end)

	item.Parent = backpack
end

local function makeKeybinds(packName: string, skillName: string, skillData: {}, guiList: {})
	local keybindInfo = skillData.Keybind
	local inputKey = keybindInfo.Key
	local externalArg = keybindInfo.HoldDuration or keybindInfo.ClickFrame

	guiList:AddSkill(skillName, inputKey)

	local beginKeybind
	if externalArg then
		beginKeybind = Keybind[keybindInfo.State](skillName, inputKey, externalArg, function()
			Controller.RequestStart(packName, skillName)
			guiList:Pressed(skillName)
		end)
	else
		beginKeybind = Keybind[keybindInfo.State](skillName, inputKey, function()
			Controller.RequestStart(packName, skillName)
			guiList:Pressed(skillName)
		end)
	end
	beginKeybind:Disable()

	local endKeybind
	if skillData.HasEnd then
		endKeybind = Keybind.End(skillName, inputKey, function()
			Controller.RequestEnd(packName, skillName)
			guiList:Unpressed(skillName)
		end)
	else
		endKeybind = Keybind.End(skillName, inputKey, function()
			guiList:Unpressed(skillName)
		end)
	end
	endKeybind:Disable()

	return { beginKeybind, endKeybind }
end

--// MODULE FUNCTIONS
function SkillLibrary.AddSkillPack(name: string)
	if skillPacks[name] then
		error("Player already has skill pack " .. name)
	end

	local cooldownStore = CooldownStore.new()
	local guiList = GuiList.new(name)

	local storedPack = Store[name]
	local keybinds = {}
	local skills = {}
	for skillName, properties in storedPack do
		local data = Utility.DeepTableClone(properties.Data)
		local skill = {
			Data = data,
			Functions = properties.Functions,
		}
		skills[skillName] = skill

		keybinds[skillName] = makeKeybinds(name, skillName, data, guiList)
		cooldownStore:Add(skillName, data.Cooldown.Duration)
	end

	skillPacks[name] = {
		CooldownStore = cooldownStore,
		GuiList = guiList,
		Keybinds = keybinds,
		Skills = skills,
	}
end

function SkillLibrary.RemoveSkillPack(name: string)
	local pack = skillPacks[name]
	if pack then
		error("Player doesn't have skill pack " .. name)
	end

	for identifier, _ in activeSkills do
		local splittedString = string.split(identifier, "_")
		Controller.Interrupt(splittedString[1], splittedString[2])
	end

	for _, keybinds in pack.Keybinds do
		keybinds[1]:Destroy()
		keybinds[2]:Destroy()
	end

	pack.GuiList:Destroy()

	skillPacks[name] = nil
end

--// EVENTS
remoteEvent:On(function(action: string, packName: string)
	SkillLibrary[action .. "SkillPack"](packName)
end)

player.CharacterAdded:Connect(function()
	local backpack = player.Backpack

	for packName, properties in skillPacks do
		giveSkillPackItem(backpack, packName, properties.GuiList)
	end
end)

return SkillLibrary
