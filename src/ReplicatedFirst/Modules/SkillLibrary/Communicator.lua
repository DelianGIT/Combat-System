--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// PACKAGES
local Packages = ReplicatedStorage.Packages
local Red = require(Packages.Red)

--// TYPES
type FunctionToConnect = (any) -> ()
export type Communicator = {
	Owner: Player,
	Connections: {[string]: FunctionToConnect},

	Fire:(self: Communicator, action: string, any) -> (),
	Connect:(self: Communicator, functionToConnect: FunctionToConnect) -> (),
	Once:(self: Communicator, functionToConnect: FunctionToConnect) -> (),
	Disconnect:(self: Communicator, action: string) -> (),
	DisconnectAll:(self: Communicator) -> (),
	Destroy:(self: Communicator) -> ()
}

--// CLASSES
local Communicator: Communicator = {}
Communicator.__index = Communicator

--// VARIABLES
local remoteEvent = Red.Client("SkillCommunication")

local communicators = {}

--// COMMUNICATOR FUNCTIONS
function Communicator:Fire(action: string, ...: any)
	remoteEvent:Fire("", action, ...)
end

function Communicator:Connect(action: string, functionToConnect: FunctionToConnect)
	self._connections[action] = functionToConnect
end

function Communicator:Once(action: string, functionToConnect: FunctionToConnect)
	self:Connect(action, function(...: any)
		self:Disconnect(action)
		functionToConnect(...)
	end)
end

function Communicator:Disconnect(action: string)
	self._connections[action] = nil
end

function Communicator:Destroy()
	communicators[self.Name] = nil
end

--// EVENTS
remoteEvent:On("", function(name: string, action: string, ...: any)
	local communicator = communicators[name]
	if not communicator then
		error("Communicator " .. name .. " not found")
	end

	local connection = communicator._connections[action]
	if connection then
		connection(...)
	else
		warn("Connection " .. action .. " not found")
	end
end)

return {
	new = function(name: string): Communicator
		local communicator = setmetatable({
			Name = name,
			_connections = {}
		}, Communicator)

		communicators[name] = communicator

		return communicator
	end,
}
