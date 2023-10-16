--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local Players = game:GetService("Players")

--// MODULES
local ClientModules = ReplicatedFirst.Modules
local Keybind = require(ClientModules.Keybind)

local SharedModules = ReplicatedStorage.Modules
local CooldownStore = require(SharedModules.CooldownStore)

local Store = require(script.Store)
local Controller = require(script.Controller)
local GuiList = require(script.GuiList)

--// PACKAGES
local Packages = ReplicatedStorage.Packages
local Red = require(Packages.Red)

--// VARIABLES
local player = Players.LocalPlayer

local skillPacksItems = ReplicatedStorage.Items.SkillPacks

local remoteEvent = Red.Client("SkillLibrary")

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
	local inputKey = skillData.InputKey

	local externalArg = skillData.HoldDuration or skillData.ClickFrame
	local beginKeybind
	if externalArg then
		beginKeybind = Keybind[skillData.InputState](skillName, inputKey, externalArg, function()
			Controller.Start(packName, skillName)
			guiList:Pressed(skillName)
		end)
	else
		beginKeybind = Keybind[skillData.InputState](skillName, inputKey, function()
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

	for skillName, properties in storedPack do
		local skillData = properties.Data
		guiList:AddSkill(skillName, skillData.InputKey)
		keybinds[skillName] = makeKeybinds(name, skillName, skillData, guiList)
		cooldownStore:Add(skillName, skillData.Cooldown)
	end

	if player.Character then
		giveSkillPackItem(name, guiList)
	end

	skillPacks[name] = {
		Keybinds = keybinds,
		CooldownStore = cooldownStore,
		GuiList = guiList,
		Skills = storedPack,
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
remoteEvent:On("Add", SkillLibrary.AddSkillPack)
remoteEvent:On("Remove", SkillLibrary.RemoveSkillPack)

player.CharacterAdded:Connect(function()
	local backpack = player.Backpack

	for packName, properties in skillPacks do
		giveSkillPackItem(backpack, packName, properties.GuiList)
	end
end)

return SkillLibrary