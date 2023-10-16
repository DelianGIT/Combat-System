--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

--// MODULES
local SharedModules = ReplicatedStorage.Modules
local Utilities = require(SharedModules.Utilities)

--// TYPES
type Key = Enum.UserInputType | Enum.KeyCode
type State = "Begin" | "End" | "Hold" | "DoubleClick"
type Keybind = {
	Name: string,
	State: State,
	Function: () -> (),
	Disabled: boolean?,

	HoldDuration: number?,
	StartHoldTime: number?,
	ClickFrame: number?,
	LastClickTime: number?,

	Enable: (self: Keybind) -> (),
	Disable: (self: Keybind) -> (),
}

--// CLASSES
local Keybind: Keybind = {}
Keybind.__index = Keybind

--// VARIABLES
local keybinds = {}

--// FUNCTIONS
local function createFolders(key: Key, state: State)
	local stateFolder = keybinds[state]
	local keyFolder

	if stateFolder then
		keyFolder = stateFolder[key]
		if not keyFolder then
			keyFolder = {}
			stateFolder[key] = keyFolder
		end
	else
		keyFolder = {}
		stateFolder = {[key] = keyFolder}
		keybinds[state] = stateFolder
	end

	return keyFolder, stateFolder
end

local function getFolders(key: Key, state: State)
	local stateFolder = keybinds[state]
	if not stateFolder then
		return
	end
	
	local keyFolder = stateFolder[key]
	if keyFolder then
		return keyFolder, stateFolder
	end
end

local function getKey(input: InputObject)
	local inputType = input.UserInputType
	if inputType == Enum.UserInputType.Keyboard then
		return input.KeyCode
	else
		return inputType
	end
end

--// INPUT PROCESSERS
local function processBegin(key: Key)
	local keyFolder = getFolders(key, "Begin")
	if not keyFolder then
		return
	end

	for _, keybind in keyFolder do
		if key == keybind.Key then
			task.spawn(keybind.Function)
		end
	end
end

local function processEnd(key: Key)
	local keyFolder = getFolders(key, "End")
	if not keyFolder then
		return
	end

	for _, keybind in keyFolder do
		if key == keybind.Key then
			task.spawn(keybind.Function)
		end
	end
end

local function processBeginHold(key: Key)
	local keyFolder = getFolders(key, "Hold")
	if not keyFolder then
		return
	end

	for _, keybind in keyFolder do
		if key == keybind.Key then
			local startTime = tick()
			keybind.StartHoldTime = startTime

			task.delay(keybind.HoldDuration, function()
				if startTime == keybind.StartHoldTime then
					keybind.StartHoldTime = 0
					keybind.Function()
				end
			end)
		end
	end
end

local function processEndHold(key: Key)
	local keyFolder = getFolders(key, "Hold")
	if not keyFolder then
		return
	end

	for _, keybind in keyFolder do
		if key == keybind.Key then
			keybind.StartHoldTime = 0
		end
	end
end

local function processDoubleClick(key: Key)
	local keyFolder = getFolders(key, "DoubleClick")
	if not keyFolder then
		return
	end

	for _, keybind in keyFolder do
		if key == keybind.Key then
			if tick() - keybind.LastClickTime <= keybind.ClickFrame then
				keybind.LastClickTime = 0
				task.spawn(keybind.Function)
			else
				keybind.LastClickTime = tick()
			end
		end
	end
end

--// KEYBIND FUNCTIONS
local function createKeybind(name: string, key: Key, state: State, functionToBind: () -> ()): Keybind
	local keybind = setmetatable({
		Name = name,
		Key = key,
		State = state,
		Function = functionToBind,
	}, Keybind)

	local keyFolder = createFolders(key, state)
	keyFolder[name] = keybind

	return keybind
end

function Keybind:Enable()
	if self.Disabled then
		local keyFolder = createFolders(self.Key, self.State)
		keyFolder[self.Name] = self
		self.Disabled = nil
	end
end

function Keybind:Disable()
	if not self.Disabled then
		local keyFolder = createFolders(self.Key, self.State)
		keyFolder[self.Name] = nil
		self.Disabled = true
	end
end

function Keybind:Destroy()
	local key, state = self.Key, self.State

	local keyFolder, stateFolder = getFolders(key, state)
	if not keyFolder then
		return
	end

	keyFolder[self.Name] = nil

	if Utilities.IsTableEmpty(keyFolder) then
		stateFolder[key] = nil

		if Utilities.IsTableEmpty(stateFolder) then
			keybinds[state] = nil
		end
	end
end

--// EVENTS
UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessedEvent: boolean)
	if not gameProcessedEvent then
		local key = getKey(input)
		processBegin(key)
		processBeginHold(key)
		processDoubleClick(key)
	end
end)

UserInputService.InputEnded:Connect(function(input: InputObject, gameProcessedEvent: boolean)
	if not gameProcessedEvent then
		local key = getKey(input)
		processEnd(key)
		processEndHold(key)
	end
end)

return {
	Begin = function(name: string, key: Key, functionToBind: () -> nil): Keybind
		return createKeybind(name, key, "Begin", functionToBind)
	end,

	End = function(name: string, key: Key, functionToBind: () -> nil): Keybind
		return createKeybind(name, key, "End", functionToBind)
	end,

	Hold = function(name: string, key: Key, holdDuration: number, functionToBind: () -> ()): Keybind
		local keybind = createKeybind(name, key, "Hold", functionToBind)
		keybind.HoldDuration = holdDuration
		keybind.StartHoldTime = 0
		return keybind
	end,

	DoubleClick = function(name: string, key: Key, clickFrame: number, functionToBind: () -> ()): Keybind
		local keybind = createKeybind(name, key, "DoubleClick", functionToBind)
		keybind.ClickFrame = clickFrame
		keybind.LastClickTime = 0
		return keybind
	end
}
