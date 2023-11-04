--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

--// TYPES
type Config = {
	Velocity: Vector3,

	Randomized: boolean,

	Amount: number,
	Frequency: number,
	Lifetime: number,
	Amplitude: number,
	Range: number,
	Height: number,
	Time: number
}
type WindService = {
	Velocity: Vector3,
	
	Randomized: boolean,

	Amount: number,
	Frequency: number,
	Lifetime: number,
	Amplitude: number,
	Range: number,
	Height: number,
	Time: number,
	Current: number,

	Start: (self: WindService) -> (),
	Stop: (self: WindService) -> (),
	CreateWind: (self: WindService) -> ()
}

--// CLASSES
local WindService: WindService = {}
WindService.__index = WindService

--// CONFIG
local TRANSPARENCY = 0.5
local FADE_DURATION = 2

--// VARIABLES
local camera = workspace.CurrentCamera

local windPart = ReplicatedStorage.Other.Wind

local randomGenerator = Random.new()

local oneSequence = NumberSequenceKeypoint.new(1, 1)
local zeroSequence = NumberSequenceKeypoint.new(0, 1)

local fadeStep = 1 / (60 * FADE_DURATION)

--// FUNCTIONS
local function calculateSineWave(amplitude: number, x: number, frequency: number, phase: number)
	return amplitude * math.sin((x / frequency) + phase)
end

local function fadeInWind(wind: Part)
	local trail = wind.Trail

	local currentValue = 1
	local connection
	connection = RunService.Heartbeat:Connect(function(deltaTime: number)
		currentValue -= fadeStep * (deltaTime * 60)
		if currentValue <= TRANSPARENCY then
			connection:Disconnect()

			trail.Transparency = NumberSequence.new{
				zeroSequence,
				NumberSequenceKeypoint.new(0.35, TRANSPARENCY),
				NumberSequenceKeypoint.new(0.65, TRANSPARENCY),
				oneSequence,
			}
		end

		trail.Transparency = NumberSequence.new{
			zeroSequence,
			NumberSequenceKeypoint.new(0.35, currentValue),
			NumberSequenceKeypoint.new(0.65, currentValue),
			oneSequence,
		}
	end)
end

local function fadeOutWind(wind: Part)
	local trail = wind.Trail
	local thread = coroutine.running()

	local currentValue = TRANSPARENCY
	local connection
	connection = RunService.Heartbeat:Connect(function(deltaTime: number)
		currentValue += fadeStep * (deltaTime * 60)
		if currentValue >= 1 then
			connection:Disconnect()
			coroutine.resume(thread)
		end

		trail.Transparency = NumberSequence.new{
			zeroSequence,
			NumberSequenceKeypoint.new(0.25, currentValue),
			NumberSequenceKeypoint.new(0.75, currentValue),
			oneSequence,
		}
	end)

	coroutine.yield()
end

local function getRandomPosition(range, height)
	local cameraPosition = camera.CFrame.Position

	return Vector3.new(
		cameraPosition.X + randomGenerator:NextInteger(-range, range),
		cameraPosition.Y + randomGenerator:NextInteger(1, height),
		cameraPosition.Z + randomGenerator:NextInteger(-range, range)
	)
end

-- METHODS
function WindService:Start()
	if self.Time then
		local startTime = tick()
		local amount = self.Amount

		self.Connection = RunService.Heartbeat:Connect(function()
			if tick() - startTime < self.Time then
				return
			end

			for _ = 1, amount do
				self:CreateWind()
			end

			startTime += self.Time
		end)
	else
		self.Connection = RunService.Heartbeat:Connect(function()
			if self.Current < self.Amount then
				self:CreateWind()
			end
		end)
	end
end

function WindService:Stop()
	local connection = self.Connection
	if connection then
		connection:Disconnect()
		self.Connection = nil
	end
end

function WindService:CreateWind()
	local wind = windPart:Clone()
	wind.Position = getRandomPosition(self.Range, self.Height)
	wind.Parent = camera
	self.Current += 1
	local lookVector = wind.CFrame.LookVector
	fadeInWind(wind)

	if self.Randomized then
		local velocity = self.Velocity
		local towards = Vector3.new(
			randomGenerator:NextNumber(-velocity.X, velocity.X),
			randomGenerator:NextNumber(-velocity.Y, velocity.Y),
			randomGenerator:NextNumber(-velocity.Z, -velocity.Z)
		)

		local lifetime = self.Lifetime
		local latency = randomGenerator:NextNumber(lifetime, lifetime + randomGenerator:NextNumber(0.5, 1.5))

		local amplitude = self.Amplitude
		local frequency = self.Frequency
		local connection = RunService.Heartbeat:Connect(function(deltaTime: number)
			local formula = calculateSineWave(amplitude, tick(), frequency, 0)
			wind.Position += (lookVector * formula + towards) * (deltaTime * 60)
		end)

		task.delay(latency, function()
			fadeOutWind(wind)
			connection:Disconnect()
			wind:Destroy()
			self.Current -= 1
		end)
	else
		local amplitude = self.Amplitude
		local frequency = self.Frequency
		local velocity = self.Velocity
		local connection = RunService.Heartbeat:Connect(function(deltaTime: number)
			local formula = calculateSineWave(amplitude, tick(), frequency, 0)
			wind.Position += (lookVector * formula + velocity) * (deltaTime * 60)
		end)

		task.delay(self.Lifetime, function()
			fadeOutWind(wind)
			connection:Disconnect()
			wind:Destroy()
			self.Current -= 1
		end)
	end
end

--// MODULE FUNCTIONS
return {
	new = function(config: Config): WindService
		return setmetatable({
			Velocity = config.Velocity or Vector3.new(0.45, 0, 0),
			Amount = config.Amount or 10,
			Frequency = config.Frequency or 0.5,
			Lifetime = config.Lifetime or 2,
			Amplitude = config.Amplitude or 0.35,
			Range = config.Range or 50,
			Height = config.Height or 25,
			Time = config.Time,
			Randomized = config.Randomized,
			Current = 0,
		}, WindService)
	end
}