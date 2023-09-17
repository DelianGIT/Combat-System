--// TYPES
type Connection = {
	Disconnect: (self: Connection) -> nil,
}

type Signal = {
	Fire: (self: Signal, any) -> nil,
	DisconnectAll: (self: Signal) -> nil,
	Connect: (self: Signal, functionToConnect: (any) -> nil) -> Connection,
	Once: (self: Signal, functionToConnect: (any) -> nil) -> Connection,
	Wait: (self: Signal, functionToConnect: (any) -> nil) -> nil,
}

--// CLASSES
local Connection: Connection = {}
Connection.__index = Connection

local Signal: Signal = {}
Signal.__index = Signal

--// FUNCTIONS
local function checkFunctionArgument(functionArgument: (any) -> nil)
	if type(functionArgument) ~= "function" then
		error("Pass function to connect")
	end
end

--// CONNECTION FUNCTIONS
local function createConnection(functionToConnect: (any) -> nil): Connection
	return setmetatable({
		_connectedFunction = functionToConnect,
		_previousConnection = false,
		_nextConnection = false,
	}, Connection)
end

function Connection:Disconnect(): nil
	if self._disconnected then
		warn("Connection is already disconnected")
		return
	end
	self._disconnected = true

	local previousConnection = self._previousConnection
	local nextConnection = self._nextConnection

	if nextConnection then
		nextConnection._previousConnection = previousConnection
	end
	if previousConnection then
		previousConnection._nextConnection = nextConnection
	end
end

--// SIGNAL FUNCTIONS
function Signal:Fire(...: any): nil
	local connection = self._lastConnection
	if not connection then
		repeat
			task.wait()
		until self._lastConnection
		connection = self._lastConnection
	end

	while connection do
		connection = connection._previousConnection
		task.spawn(connection._connectedFunction, ...)
	end
end

function Signal:DisconnectAll(): nil
	if not self._lastConnection then
		warn("Connections are already disconnected")
	else
		self._lastConnection = false
	end
end

function Signal:Connect(functionToConnect: (any) -> nil): Connection
	checkFunctionArgument(functionToConnect)

	local connection = createConnection(functionToConnect)

	local lastConnection = self._lastConnection
	if lastConnection then
		lastConnection._nextConnection = connection
		connection._previousConnection = lastConnection
	end
	self._lastConnection = connection

	return connection
end

function Signal:Wait(): nil
	local thread = coroutine.running()

	self:Connect(function()
		coroutine.resume(thread)
	end)

	return coroutine.yield()
end

function Signal:Once(functionToConnect: (any) -> nil): Connection
	checkFunctionArgument(functionToConnect)

	local connection
	connection = self:Connect(function()
		connection:Disconnect()
		functionToConnect()
	end)
end

--// MODULE FUNCTIONS
return {
	new = function(): Signal
		return setmetatable({
			_lastConnection = false,
		}, Signal)
	end,
}
