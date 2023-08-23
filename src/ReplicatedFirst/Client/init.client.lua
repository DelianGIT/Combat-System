--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// MODULES
local Modules = ReplicatedStorage:WaitForChild("Modules")
local ClientModules = Modules:WaitForChild("Client")
local SkillLibrary = require(ClientModules:WaitForChild("SkillLibrary"))

--// PACKAGES
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Red = require(Packages:WaitForChild("Red"))

--// VARIABLES
local loadingStages = {
	"Client",
	"SkillPacks"
}

local remoteEvent = Red.Client("LoadingControl")

--// FUNCTIONS
local function completeLoadingStage(stageName:string)
	table.remove(loadingStages, table.find(loadingStages, stageName))
	
	if #loadingStages == 0 then
		remoteEvent:Fire("LoadCharacter")
	end
end

-- WATING FOR LOADED GAME
repeat
	task.wait()
until game.Loaded
print("Game loaded")

--// REQUIRING MODULES
for _, module in script:GetChildren() do
	task.spawn(require, module)
end
completeLoadingStage("Client")
print("Client started")

--// EVENTS
remoteEvent:On("SkillPacks", function(keybindsInfo)
	for packName, info in keybindsInfo do
		SkillLibrary.AddSkillPack(packName, info)
	end

	completeLoadingStage("SkillPacks")
end)

remoteEvent:Fire("ReadyForData")