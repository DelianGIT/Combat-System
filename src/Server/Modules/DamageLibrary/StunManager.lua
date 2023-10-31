--// MODULES
local WalkSpeedManager = require(script.Parent.WalkSpeedManager)
local JumpPowerManager = require(script.Parent.JumpPowerManager)

--// TYPES
export type Config = {
	Priority: number,
	Duration: number,
	WalkSpeed: number,
	JumpPower: number,
}

--// CONFIG
local VISUALIZATION = true

--// VARIABLES
local StunManager = {}

--// MODULE FUNCTIONS
function StunManager.MakeConfig(): Config
	return {}
end

function StunManager.Apply(character: Model, tempData: {}, config: Config)
	local existingStun = tempData.Stun
	local priority = config.Priority
	if existingStun and existingStun.Priority > priority then
		return
	end

	local startTime = tick()
	tempData.Stun = {
		StartTime = startTime,
		Priority = priority,
	}

	local duration = config.Duration
	WalkSpeedManager.Change(character, tempData, {
		Value = config.WalkSpeed,
		Priority = priority,
		Duration = duration,
	})
	JumpPowerManager.Change(character, tempData, {
		Value = config.JumpPower,
		Priority = priority,
		Duration = duration,
	})

	if duration then
		task.delay(duration, function()
			local currentStun = tempData.Stun
			if currentStun and currentStun.StartTime == startTime then
				StunManager.Cancel(character, tempData)
			end
		end)
	end

	if VISUALIZATION then
		local visualization = character:FindFirstChild("StunVisualization")
		if visualization then
			visualization.Color = Color3.new(1, 0, 0)
		end
	end
end

function StunManager.Cancel(character: Model, tempData: {})
	if not tempData.Stun then
		return
	end

	WalkSpeedManager.Cancel(character, tempData)
	JumpPowerManager.Cancel(character, tempData)

	tempData.Stun = nil

	if VISUALIZATION then
		local visualization = character:FindFirstChild("StunVisualization")
		if visualization then
			visualization.Color = Color3.new(0, 1, 0)
		end
	end
end

--// VISUALIZATION
if VISUALIZATION then
	--// SERVICES
	local ServerStorage = game:GetService("ServerStorage")

	--// VARIABLES
	local visualizationPart = ServerStorage.Assets.Other.StunVisualization
	local livingFolder = workspace.Living
	local offset = Vector3.new(0, 4.5, 0)

	--// FUNCTIONS
	local function addVisualization(character: Model)
		local humanoidRootPart = character.HumanoidRootPart

		local visualization = visualizationPart:Clone()
		visualization.Position = humanoidRootPart.Position + offset

		local weld = Instance.new("WeldConstraint")
		weld.Part0 = humanoidRootPart
		weld.Part1 = visualization
		weld.Parent = visualization

		visualization.Parent = character
	end

	--// EVENTS
	livingFolder.Players.ChildAdded:Connect(addVisualization)
	livingFolder.Npc.ChildAdded:Connect(function(folder: Folder)
		folder.ChildAdded:Connect(addVisualization)
	end)
end

return StunManager
