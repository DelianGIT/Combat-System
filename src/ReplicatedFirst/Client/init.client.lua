--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")

--// MODULES
local ClientModules = ReplicatedFirst:WaitForChild("Modules")
local SkillLibrary = require(ClientModules:WaitForChild("SkillLibrary"))

--// VARIABLES
local remoteEvents = ReplicatedStorage:WaitForChild("Events")
local remoteEvent = require(remoteEvents:WaitForChild("LoadingControl")):Client()

local eventFunctions = {}
local stageCount = 2

--// FUNCTIONS
local function completeLoadingStage(stageName: string)
	eventFunctions[stageName] = nil
	stageCount -= 1

	if stageCount == 0 then
		print("Client loaded")
		remoteEvent:Fire("LoadCharacter")
	end
end

-- WATING FOR LOADED GAME
repeat task.wait() until game:IsLoaded()
print("Game loaded")

--// REQUIRING MODULES
for _, module in script:GetChildren() do
	task.spawn(require, module)
end
completeLoadingStage("Client")
print("Client started")

--// EVENT FUNCTIONS
function eventFunctions.SkillPacks(packs: { [number]: string })
	for _, packName in packs do
		SkillLibrary.AddSkillPack(packName)
	end

	completeLoadingStage("SkillPacks")
	print("Skill packs loaded")
end

--// EVENTS
remoteEvent:On(function(stageName: string, ...: any)
	eventFunctions[stageName](...)
end)

remoteEvent:Fire("ReadyForData")