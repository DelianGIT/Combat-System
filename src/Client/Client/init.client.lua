--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")

--// MODULES
local ClientModules = ReplicatedFirst:WaitForChild("Modules")
local SkillLibrary = require(ClientModules.SkillLibrary)

--// VARIABLES
local remoteEvents = ReplicatedStorage:WaitForChild("Events")
local remoteEvent = require(remoteEvents.LoadingControl):Client()

local loadingStages = 1

local eventFunctions = {}

-- WATING FOR LOADED GAME
repeat
	task.wait()
until game:IsLoaded()
print("Game loaded")

--// REQUIRING MODULES
for _, module in script:GetChildren() do
	task.spawn(require, module)
end
print("Client started")

--// FUNCTIONS
local function completeLoadingStage()
	loadingStages -= 1

	if loadingStages == 0 then
		remoteEvent:Fire("LoadCharacter")
		print("Client loaded")
	end
end

--// EVENT FUNCTIONS
function eventFunctions.SkillPacks(packs: { [number]: string })
	for _, packName in packs do
		SkillLibrary.AddSkillPack(packName)
	end

	completeLoadingStage()
	print("Skill packs loaded")
end

--// EVENTS
remoteEvent:On(function(stageName: string, ...: any)
	eventFunctions[stageName](...)
end)

remoteEvent:Fire("ReadyForData")
