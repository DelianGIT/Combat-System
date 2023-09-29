--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// PACKAGES
local Packages = ReplicatedStorage.Packages
local Red = require(Packages.Red)

--// CLASSES
local Communicator = {}
Communicator.__index = Communicator

--// VARIABLES
local remoteEvent = Red.Server("SkillCommunication")

local communicators = {}

--// COMMUNICATOR FUNCTIONS
function Communicator:Fire(action: string, ...: any)
	remoteEvent:Fire(self.Owner, "", action, ...)
end

function Communicator:Connect(action: string, functionToConnect: (any) -> nil)
	self.Connections[action] = functionToConnect
end

function Communicator:Once(action: string, functionToConnect: (any) -> nil)
	self:Connect(action, function(...: any)
		self:Disconnect(action)
		functionToConnect(...)
	end)
end

function Communicator:Disconnect(action: string)
	self.Connections[action] = nil
end

function Communicator:DisconnectAll()
	self.Connections = {}
end

--// EVENTS
remoteEvent:On("", function(player: Player, action: string, ...: any)
	local communicator = communicators[player]
	if not communicator then
		error("Not found " .. player.Name .. "'s skill communicator")
	end

	local connection = communicator.Connections[action]
	if connection then
		connection(...)
	else
		warn("Connection " .. action .. " not found in " .. player.Name .. "'s communicator")
	end
end)

return {
	new = function(player: Player)
		local communicator = setmetatable({
			Owner = player,
			Connections = {},
		}, Communicator)
		
		communicators[player] = communicator

		return communicator
	end,
}
