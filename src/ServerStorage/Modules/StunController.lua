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
		local indicator = character.HumanoidRootPart.StunIndicator
		indicator.Enabled = true
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
			local indicator = character.HumanoidRootPart.StunIndicator
			indicator.Enabled = false
		end
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
	livingFolder.Npc.ChildAdded:Connect(addVisualization)
end

return StunController