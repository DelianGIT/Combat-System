--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// PACKAGES
local Packages = ReplicatedStorage.Packages
local Red = require(Packages.Red)

--// TYPES
type FunctionToConnect = (any) -> ()
export type Communicator = {
	Name: string,
	Owner: Player,

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
local remoteEvent = Red.Server("SkillCommunication")

local communicators = {}

--// FUNCTIONS
local function isTableEmpty(table: {})
	for _, _ in table do
		return false
	end
	return true
end

--// COMMUNICATOR FUNCTIONS
function Communicator:Fire(action: string, ...: any)
	remoteEvent:Fire(self.Owner, "", self.Name, action, ...)
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
	local playerCommunicators = communicators[self.Owner]
	playerCommunicators[self.Name] = nil

	if isTableEmpty(playerCommunicators) then
		communicators[self.Owner] = nil
	end
end

--// EVENTS
remoteEvent:On("", function(player: Player, name: string, action: string, ...: any)
	local playerCommunicators = communicators[player]
	local communicator = playerCommunicators[name]
	if not communicator then
		error("Not found " .. player.Name .. "'s communicator " .. name)
	end

	local connection = communicator._connections[action]
	if connection then
		connection(...)
	else
		warn("Connection " .. action .. " not found in " .. player.Name .. "'s communicator " .. name)
	end
end)

return {
	new = function(name: string, player: Player): Communicator
		local communicator = setmetatable({
			Name = name,
			Owner = player,
			_connections = {},
		}, Communicator)

		local playerCommunicators = communicators[player] or {}
		communicators[player] = playerCommunicators
		playerCommunicators[name] = communicator

		return communicator
	end,
}
