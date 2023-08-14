--// SERVICES
local UserInputService = game:GetService("UserInputService")

--// TYPES
type InputState = "Begin" | "End" | "Hold" | "DoubleClick"
type Key = Enum.UserInputType | Enum.KeyCode

type Keybind = {
	Name:string,
	InputState:InputState,
	Function:() -> nil,

	HoldDuration:number?,
	StartHoldTime:number?,
	ClickFrame:number?,
	Destroyed:boolean?,

	Enable:(self:Keybind) -> nil,
	Disable:(self:Keybind) -> nil,
	Destroy:(self:Keybind) -> nil
}

--// CLASSES
local Keybind:Keybind = {}
Keybind.__index = function(self:Keybind, key:any)
	if rawget(self, "Destroyed") then
		error("Bind is destroyed")
	end

	return Keybind[key]
end

--// VARIABLES
local beginKeybinds = {}
local endKeybinds = {}
local holdKeybinds = {}
local doubleClickKeybinds = {}

--// FUNCTIONS
local function checkArguments(name:string, key:Key, functionToBind:() -> nil)
	if type(name) ~= "string" then
		error("Name must be a string")
	end

	local keyType = key.EnumType
	if keyType ~= Enum.UserInputType and keyType ~= Enum.KeyCode then
		error("Invalid key")
	end
	
	if type(functionToBind) ~= "function" then
		error("Pass function to bind")
	end
end

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
	for _, keybind:Keybind in pairs(beginKeybinds) do
		if key == keybind.Key then
			task.spawn(keybind.Function)
		end
	end
end

local function processEnd(key:Key)
	for _, keybind:Keybind in pairs(endKeybinds) do
		if key == keybind.Key then
			task.spawn(keybind.Function)
		end
	end
end

local function processBeginHold(key:Key)
	for _, keybind:Keybind in pairs(holdKeybinds) do
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
	for _, keybind:Keybind in pairs(holdKeybinds) do
		if key == keybind.Key then
			if keybind.StartHoldTime > 0 and tick() - keybind.StartHoldTime >= keybind.HoldDuration then
				keybind.StartHoldTime = 0
				task.spawn(keybind.Function)
			end
		end
	end
end

local function processDoubleClick(key:Key)
	for _, keybind:Keybind in pairs(doubleClickKeybinds) do
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
local function createKeybind(name:string, key:Key, inputState:InputState, functionToBind:() -> nil):Keybind
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
	if gameProcessedEvent then return end

	local key = getKey(input)
	processBegin(key)
	processBeginHold(key)
	processDoubleClick(key)
end)

UserInputService.InputEnded:Connect(function(input:InputObject, gameProcessedEvent:boolean)
	if gameProcessedEvent then return end

	local key = getKey(input)
	processEnd(key)
	processEndHold(key)
end)

--// MODULE FUNCTIONS
return {
	Begin = function(name:string, key:Key, functionToBind:() -> nil):Keybind
		checkArguments(name, key, functionToBind)
		createKeybind(name, key, "Begin", functionToBind)
	end,

	End = function(name:string, key:Key, functionToBind:() -> nil):Keybind
		checkArguments(name, key, functionToBind)
		createKeybind(name, key, "End", functionToBind)
	end,

	Hold = function(name:string, key:Key, holdDuration:number, functionToBind:() -> nil):Keybind
		checkArguments(name, key, functionToBind)
		if type(holdDuration) ~= "number" then
			error("Hold duration must be a number")
		end

		local keybind = createKeybind(name, key, "Hold", functionToBind)
		keybind.HoldDuration = holdDuration
		keybind.StartHoldTime = 0
	end,

	DoubleClick = function(name:string, key:Key, clickFrame:number, functionToBind:() -> nil):Keybind
		checkArguments(name, key, functionToBind)
		if type(clickFrame) ~= "number" then
			error("Click frame must be a number")
		end

		local keybind = createKeybind(name, key, "DoubleClick", functionToBind)
		keybind.ClickFrame = clickFrame
		keybind.LastClickTime = 0
	end
}