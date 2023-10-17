--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// TYPES
export type Event = {
	Name: string,
	Player: Player,
	Connections: { [string]: () -> () },

	Fire: (action: string, any) -> (),
	Connect: (action: string, functionToConnect: (any) -> ()) -> (),
	Disconnect: () -> (),
	Once: (action: string, functionToConnect: (any) -> ()) -> (),
	Wait: (action: string) -> ()
}
export type Communicator = {
	Player: Player,
	Events: { [string]: Event },

	CreateEvent: (self: Communicator, name: string) -> (),
	DestroyEvent: (self: Communicator, name: string) -> (),
	Destroy: (self: Communicator) -> ()
}

--// CLASSES
local Event: Event = {}
Event.__index = Event

local Communicator: Communicator = {}
Communicator.__index = Communicator

--// VARIABLES
local remoteEvents = ReplicatedStorage.Events
local remoteEvent = require(remoteEvents.SkillCommunication):Server()

local communicators = {}

--// EVENT FUNCTIONS
function Event:Fire(action: string, ...: any)
	remoteEvent:Fire(self.Player, self.Name, action, ...)
end

function Event:Connect(action: string, functionToConnect: (any) -> ())
	self.Connections[action] = functionToConnect
end

function Event:Disconnect(action: string)
	self.Connections[action] = nil
end

function Event:Once(action: string, functionToConnect: (any) -> ())
	self.Connections[action] = function(...)
		self:Disconnect(action)
		functionToConnect(...)
	end
end

function Event:Wait(action: string)
	local thread = coroutine.running()

	self.Connections[action] = function()
		coroutine.resume(thread)
	end

	coroutine.yield()
end

--// COMMUNICATOR FUNCTIONS
function Communicator:CreateEvent(name: string): Event
	local event = setmetatable({
		Name = name,
		Player = self.Player,
		Connections = {}
	}, Event)

	self.Events[name] = event

	return event
end

function Communicator:DestroyEvent(name: string)
	self.Events[name] = nil
end

function Communicator:Destroy()
	communicators[self.Player] = nil
end

--// EVENTS
remoteEvent:On(function(player: Player, eventName: string, action: string, ...: any)
	local communicator = communicators[player]
	if not communicator then
		error("Not found communicator for " .. player.Name)
	end

	local event = communicator.Events[eventName]
	if not event then
		error(player.Name .. "'s event not found for action " .. action)
	end

	local connection = event.Connections[action]
	if not connection then
		error("Action " .. action .. " not found in event " .. eventName .. " in " .. player.Name .. "'s communicator")
	end

	connection(...)
end)

--// MODULE FUNCTION
return {
	new = function(player: Player): Communicator
		local communicator = setmetatable({
			Player = player,
			Events = {}
		}, Communicator)

		communicators[player] = communicator

		return communicator
	end
}