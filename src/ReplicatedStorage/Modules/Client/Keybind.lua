--// SERVICES
local UserInputService = game:GetService("UserInputService")

--// TYPES
type InputState = "Begin" | "End" | "Hold" | "DoubleClick"
type Key = Enum.UserInputType | Enum.KeyCode

type Keybind = {
	Name:string,
	InputState:InputState,
	Function:() -> (),

	HoldDuration:number?,
	StartHoldTime:number?,
	ClickFrame:number?,
	Destroyed:boolean?,

	Enable:(self:Keybind) -> (),
	Disable:(self:Keybind) -> (),
	Destroy:(self:Keybind) -> ()
}

--// CLASSES
local Keybind:Keybind = {}
Keybind.__index = function(self:Keybind, key:any)
	if not rawget(self, "Destroyed") then
		return Keybind[key]
	else
		error("Bind is destroyed")
	end
end

--// VARIABLES
local beginKeybinds = {}
local endKeybinds = {}
local holdKeybinds = {}
local doubleClickKeybinds = {}

--// FUNCTIONS
local function getKeybindsFolder(inputState:InputState)
	if inputState == "Begin" then
		return beginKeybinds
	elseif inputState == "End" then
		return endKeybinds
	elseif inputState == "Hold" then
		return holdKeybinds
	elseif inputState == "DoubleClick" then
		return doubleClickKeybinds
	end
end

local function getKey(input:InputObject)
	if input.UserInputType == Enum.UserInputType.Keyboard then
		return input.KeyCode
	else
		return input.UserInputType
	end
end

local function processBegin(key:Key)
	for _, keybind:Keybind in beginKeybinds do
		if key == keybind.Key then
			task.spawn(keybind.Function)
		end
	end
end

local function processEnd(key:Key)
	for _, keybind:Keybind in endKeybinds do
		if key == keybind.Key then
			task.spawn(keybind.Function)
		end
	end
end

local function processBeginHold(key:Key)
	for _, keybind:Keybind in holdKeybinds do
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

local function processEndHold(key:Key)
	for _, keybind:Keybind in holdKeybinds do
		if key == keybind.Key then
			if keybind.StartHoldTime > 0 and tick() - keybind.StartHoldTime >= keybind.HoldDuration then
				keybind.StartHoldTime = 0
				task.spawn(keybind.Function)
			end
		end
	end
end

local function processDoubleClick(key:Key)
	for _, keybind:Keybind in doubleClickKeybinds do
		if key == keybind.Key then
			if keybind.LastClickTime == 0 then
				keybind.LastClickTime = tick()
			elseif tick() - keybind.LastClickTime <= keybind.ClickFrame then
				keybind.LastClickTime = 0
				task.spawn(keybind.Function)
			end
		end
	end
end

--// KEYBIND FUNCTIONS
local function createKeybind(name:string, key:Key, inputState:InputState, functionToBind:() -> ()):Keybind
	local keybind = setmetatable({
		Name = name,
		Key = key,
		InputState = inputState,
		Function = functionToBind
	}, Keybind)

	local keybindsFolder = getKeybindsFolder(inputState)
	keybindsFolder[name] = keybind

	return keybind
end

function Keybind:Enable()
	local keybindsFolder = getKeybindsFolder(self.InputState)
	keybindsFolder[self.Name] = self
end

function Keybind:Disable()
	local keybindsFolder = getKeybindsFolder(self.InputState)
	keybindsFolder[self.Name] = nil
end

function Keybind:Destroy()
	self:Disable()
	self.Destroyed = true
end

--// EVENTS
UserInputService.InputBegan:Connect(function(input:InputObject, gameProcessedEvent:boolean)
	if not gameProcessedEvent then
		local key = getKey(input)
		processBegin(key)
		processBeginHold(key)
		processDoubleClick(key)
	end
end)

UserInputService.InputEnded:Connect(function(input:InputObject, gameProcessedEvent:boolean)
	if gameProcessedEvent then
		local key = getKey(input)
		processEnd(key)
		processEndHold(key)
	end
end)

--// MODULE FUNCTIONS
return {
	Begin = function(name:string, key:Key, functionToBind:() -> nil):Keybind
		createKeybind(name, key, "Begin", functionToBind)
	end,

	End = function(name:string, key:Key, functionToBind:() -> nil):Keybind
		createKeybind(name, key, "End", functionToBind)
	end,

	Hold = function(name:string, key:Key, holdDuration:number, functionToBind:() -> ()):Keybind
		local keybind = createKeybind(name, key, "Hold", functionToBind)
		keybind.HoldDuration = holdDuration
		keybind.StartHoldTime = 0
	end,

	DoubleClick = function(name:string, key:Key, clickFrame:number, functionToBind:() -> ()):Keybind
		local keybind = createKeybind(name, key, "DoubleClick", functionToBind)
		keybind.ClickFrame = clickFrame
		keybind.LastClickTime = 0
	end
}