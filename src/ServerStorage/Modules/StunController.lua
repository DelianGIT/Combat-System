--// SERVICES
local ServerStorage = game:GetService("ServerStorage")

--// MODULES
local ServerModules = ServerStorage.Modules
local WalkSpeedController = require(ServerModules.WalkSpeedController)
local JumpPowerController = require(ServerModules.JumpPowerController)

--// CONFIG
local VISUALIZATION = true

--VARIABLES
local StunController = {}

--// MODULE FUNCTIONS
function StunController.Apply(character: Model, tempData: {}, duration: number?)
	local existingStun = tempData.Stun
	if existingStun and existingStun[1] - (tick() - existingStun[2]) >= duration then
		return
	end

	local startTime = tick()
	tempData.Stun = {duration, startTime}
	tempData.CanUseSkills = false

	WalkSpeedController.Change(character, tempData, 0, 5, duration)
	JumpPowerController.Change(character, tempData, 0, 5, duration)

	if VISUALIZATION then
		character.StunVisualization.OutlineColor = Color3.new(1, 0, 0)
	end

	if not duration then return end
	task.delay(duration, function()
		local currentStun = tempData.Stun
		if currentStun and currentStun[2] == startTime then
			StunController.Cancel(character, tempData)
		end
	end)
end

function StunController.Cancel(character: Model, tempData: {})
	if tempData.Stun then
		tempData.Stun = false
		tempData.CanUseSkills = true
		
		WalkSpeedController.Cancel(character, tempData)
		JumpPowerController.Cancel(character, tempData)

		if VISUALIZATION then
			character.StunVisualization.OutlineColor = Color3.new(0, 1, 0)
		end
	end
end

--// VISUALIZATION
if VISUALIZATION then
	local livingFolder = workspace.Living

	local highlight = Instance.new("Highlight")
	highlight.Name = "StunVisualization"
	highlight.FillTransparency = 1
	highlight.OutlineColor = Color3.new(0, 1, 0)
	highlight.OutlineTransparency = 0
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded

	local function addVisualization(character: Model)
		highlight:Clone().Parent = character
	end

	livingFolder.Players.ChildAdded:Connect(addVisualization)
	livingFolder.Npc.ChildAdded:Connect(addVisualization)
end

return StunController