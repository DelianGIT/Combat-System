--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// TYPES
type Event = {
	Connections: {[string]: (any) -> ()},

	Fire:(self: Event, action: string, any) -> (),
	Connect:(self: Event, functionToConnect: (any) -> ()) -> (),
	Once:(self: Event, functionToConnect: (any) -> ()) -> (),
	Disconnect:(self: Event, action: string) -> (),
	Destroy:(self: Event) -> ()
}

--// CLASSES
local Event: Event = {}
Event.__index = Event

--// VARIABLES
local remoteEvents = ReplicatedStorage.Events
local remoteEvent = require(remoteEvents.SkillCommunication):Client()

local events = {}

--// EVENT FUNCTIONS
function Event:Fire(action: string, ...: any)
	remoteEvent:Fire(self.Name, action, ...)
end

function Event:Connect(action: string, functionToConnect: (any) -> ())
	self.Connections[action] = functionToConnect
end

function Event:Disconnect(action: string)
	self.Connections[action] = nil
end

function Event:Once(action: string, functionToConnect: (any) -> ())
	self:Connect(action, function(...)
		self:Disconnect(action)
		functionToConnect(...)
	end)
end

function Event:Wait(action: string)
	local thread = coroutine.running()

	self.Connections[action] = function()
		coroutine.resume(thread)
	end

	coroutine.yield()
end

function Event:Destroy()
	events[self.Name] = nil
end

--// EVENTS
remoteEvent:On(function(name: string, action: string, ...: any)
	local event = events[name]
	if not event then
		error("Event " .. name .. " not found")
	end

	local connection = event.Connections[action]
	if connection then
		connection(...)
	else
		warn("Action " .. action .. " not found")
	end
end)

--// MODULE FUNCTION
return {
	new = function(name: string): Event
		local event = setmetatable({
			Name = name,
			Connections = {}
		}, Event)

		events[name] = event

		return event
	end
}