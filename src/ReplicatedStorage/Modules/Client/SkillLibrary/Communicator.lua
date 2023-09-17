--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// PACKAGES
local Packages = ReplicatedStorage.Packages
local Red = require(Packages.Red)

--// VARIABLES
local remoteEvent = Red.Client("SkillCommunication")

local connections = {}
local Communicator = {}

--// MODULE FUNCTIONS
function Communicator.Fire(action: string, ...: any)
	remoteEvent:Fire("", action, ...)
end

function Communicator.Connect(action: string, functionToConnect: (any) -> ())
	connections[action] = functionToConnect
end

function Communicator.Once(action: string, functionToConnect: (any) -> nil)
	Communicator.Connect(action, function(...: any)
		Communicator.Disconnect(action)
		functionToConnect(...)
	end)
end

function Communicator.Disconnect(action: string)
	connections[action] = nil
end

function Communicator.DisconnectAll()
	connections = {}
end

--// EVENTS
remoteEvent:On("", function(action: string, ...: any)
	local connection = connections[action]
	if connection then
		connection(...)
	else
		warn("Connection " .. action .. " not found")
	end
end)

return Communicator
