--// SERVICES
local ServerStorage = game:GetService("ServerStorage")

--// MODULES
local ServerModules = ServerStorage.Modules
local WalkSpeedController = require(ServerModules.WalkSpeedController)
local JumpPowerController = require(ServerModules.JumpPowerController)

--// CONFIGE
local VISUALIZATION = true

--VARIABLES
local StunController = {}

--// MODULE FUNCTIONS
function StunController.Apply(character: Model, tempData: {}, duration: number?)
	local existingStun = tempData.Stun
	if existingStun and duration then
		if existingStun.Duration - (tick() - existingStun.StartTime) >= duration then
			return
		end
	end

	local startTime = tick()
	tempData.Stun = {
		Duration = duration,
		StartTime = if duration then startTime else nil
	}
	tempData.CantUseSkills = true

	WalkSpeedController.Change(character, tempData, 0, 5, duration)
	JumpPowerController.Change(character, tempData, 0, 5, duration)

	if VISUALIZATION then
		local indicator = character.HumanoidRootPart.StunIndicator
		indicator.Enabled = true
	end

	if not duration then return end
	task.delay(duration, function()
		local currentStun = tempData.Stun
		if currentStun and currentStun.StartTime == startTime then
			StunController.Cancel(character, tempData)
		end
	end)
end

function StunController.Cancel(character: Model, tempData: {})
	if not tempData.Stun then return end

	tempData.Stun = nil
	tempData.CantUseSkills = nil
	
	WalkSpeedController.Cancel(character, tempData)
	JumpPowerController.Cancel(character, tempData)

	if VISUALIZATION then
		local indicator = character.HumanoidRootPart.StunIndicator
		indicator.Enabled = false
	end
end

--// VISUALIZATION
if VISUALIZATION then
	local livingFolder = workspace.Living

	local stunIndicator = ServerStorage.Assets.Gui.StunIndicator

	local function addVisualization(character: Model)
		local indicator = stunIndicator:Clone()
		indicator.Parent = character.HumanoidRootPart
	end

	livingFolder.Players.ChildAdded:Connect(addVisualization)
	livingFolder.Npc.ChildAdded:Connect(function(folder: Folder)
		folder.ChildAdded:Connect(addVisualization)
	end)
end

return StunController