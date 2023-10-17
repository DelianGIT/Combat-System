--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local Players = game:GetService("Players")

--// MODULES
local ClientModules = ReplicatedFirst.Modules
local Keybind = require(ClientModules.Keybind)

local SharedModules = ReplicatedStorage.Modules
local CooldownStore = require(SharedModules.CooldownStore)
local Utilities = require(SharedModules.Utilities)

local Store = require(script.Store)
local Controller = require(script.Controller)
local GuiList = require(script.GuiList)

--// VARIABLES
local player = Players.LocalPlayer

local skillPacksItems = ReplicatedStorage.Items.SkillPacks

local remoteEvents = ReplicatedStorage.Events
local remoteEvent = require(remoteEvents.SkillLibrary):Client()

local skillPacks = Controller.SkillPacks
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
		
		for identifier, properties in Controller.ActiveSkills do
			local packName2, skillName = table.unpack(string.split(identifier, "_"))
			if packName2 == packName and properties.State == "WaitingForEnd" then
				Controller.End(packName, skillName)
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
			Controller.Start(packName, skillName)
			guiList:Pressed(skillName)
		end)
	else
		beginKeybind = Keybind[keybindInfo.State](skillName, inputKey, function()
			Controller.Start(packName, skillName)
			guiList:Pressed(skillName)
		end)
	end
	beginKeybind:Disable()

	local endKeybind
	if skillData.HasEnd then
		endKeybind = Keybind.End(skillName, inputKey, function()
			Controller.End(packName, skillName)
			guiList:Unpressed(skillName)
		end)
	else
		endKeybind = Keybind.End(skillName, inputKey, function()
			guiList:Unpressed(skillName)
		end)
	end
	endKeybind:Disable()

	return {beginKeybind, endKeybind}
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
		local skillData = Utilities.DeepTableClone(properties.Data)
		local skill = {
			Data = skillData,
			Functions = properties.Functions
		}
		skills[skillName] = skill

		cooldownStore:Add(skillName, skillData.Cooldown.Duration)
		keybinds[skillName] = makeKeybinds(name, skillName, skillData, guiList)
	end

	if player.Character then
		giveSkillPackItem(name, guiList)
	end

	skillPacks[name] = {
		Keybinds = keybinds,
		CooldownStore = cooldownStore,
		GuiList = guiList,
		Skills = skills,
	}
end

function SkillLibrary.RemoveSkillPack(name: string)
	local pack = skillPacks[name]
	if pack then
		error("Player doesn't have skill pack " .. name)
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
	SkillLibrary[action](packName)
end)

player.CharacterAdded:Connect(function()
	local backpack = player.Backpack

	for packName, properties in skillPacks do
		giveSkillPackItem(backpack, packName, properties.GuiList)
	end
end)

return SkillLibrary