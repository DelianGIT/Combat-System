local ReplicatedStorage = game:GetService("ReplicatedStorage")
--// MODULES
local WalkSpeedManager = require(script.Parent.WalkSpeedManager)
local JumpPowerManager = require(script.Parent.JumpPowerManager)

--// TYPES
export type Config = {
	Priority: number,
	Duration: number,
	WalkSpeed: number,
	JumpPower: number
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
		Priority = priority
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

	if VISUALIZATION then
		character.StunVisualization.Color = Color3.new(1, 0, 0)
	end

	if duration then
		task.delay(duration, function()
			local newStun = tempData.Stun
			if newStun and newStun.StartTime == startTime then
				StunManager.Cancel(character, tempData)
			end
		end)
	end
end

function StunManager.Cancel(character: Model, tempData: {})
	if not tempData.Stun then
		return
	end

	tempData.Stun = nil

	WalkSpeedManager.Cancel(character, tempData)
	JumpPowerManager.Cancel(character, tempData)

	if VISUALIZATION then
		character.StunVisualization.Color = Color3.new(0, 1, 0)
	end
end

if VISUALIZATION then
	local visualizationPart = ReplicatedStorage.Other.StunVisualization
	local livingFolder = workspace.Living
	local offset = Vector3.new(0, 4.5, 0)

	local function addVisualization(character: Model)
		local humanoidRootPart = character.HumanoidRootPart

		local weld = Instance.new("WeldConstraint")
		weld.Part0 = humanoidRootPart

		local visualization = visualizationPart:Clone()
		visualization.Position = humanoidRootPart.Position + offset
		weld.Part1 = visualization

		weld.Parent = visualization
		visualization.Parent = character
	end

	livingFolder.Players.ChildAdded:Connect(addVisualization)
	livingFolder.Npc.ChildAdded:Connect(function(folder: Folder)
		folder.ChildAdded:Connect(addVisualization)
	end)
end

return StunManager
