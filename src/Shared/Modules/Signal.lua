--// TYPES
type Connection = {
	PreviousConnection: Connection,
	NextConnection: Connection,
	Disconnected: false?,
	Function: (any) -> (),

	Disconnect: (self: Connection) -> (),
}

type Signal = {
	LastConnection: Connection?,

	Fire: (self: Signal, any) -> (),
	DisconnectAll: (self: Signal) -> (),
	Connect: (self: Signal, functionToConnect: (any) -> ()) -> Connection,
	Once: (self: Signal, functionToConnect: (any) -> ()) -> Connection,
	Wait: (self: Signal, functionToConnect: (any) -> ()) -> (),
}

--// CLASSES
local Connection: Connection = {}
Connection.__index = Connection

local Signal: Signal = {}
Signal.__index = Signal

--// CONNECTION FUNCTIONS
local function createConnection(functionToConnect: (any) -> ()): Connection
	return setmetatable({
		Function = functionToConnect,
	}, Connection)
end

function Connection:Disconnect()
	if self.Disconnected then
		return
	end
	self.Disconnected = true

	local previousConnection = self.PreviousConnection
	local nextConnection = self.NextConnection

	if nextConnection then
		nextConnection.PreviousConnection = previousConnection
	end
	if previousConnection then
		previousConnection.NextConnection = nextConnection
	end
end

--// SIGNAL FUNCTIONS
function Signal:Fire(...: any)
	local connection = self.LastConnection
	while connection do
		task.spawn(connection.Function, ...)
		connection = connection.PreviousConnection
	end
end

function Signal:DisconnectAll()
	self.LastConnection = false
end

function Signal:Connect(functionToConnect: (any) -> ()): Connection
	local connection = createConnection(functionToConnect)

	local lastConnection = self.LastConnection
	if lastConnection then
		lastConnection.NextConnection = connection
		connection.PreviousConnection = lastConnection
	end
	self.LastConnection = connection

	return connection
end

function Signal:Wait()
	local thread = coroutine.running()

	self:Connect(function()
		coroutine.resume(thread)
	end)

	coroutine.yield()
end

function Signal:Once(functionToConnect: (any) -> ()): Connection
	local connection
	connection = self:Connect(function(...)
		connection:Disconnect()
		functionToConnect(...)
	end)
end

return {
	new = function(): Signal
		return setmetatable({
			LastConnection = false,
		}, Signal)
	end,
}
