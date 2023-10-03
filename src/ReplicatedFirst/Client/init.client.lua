--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")

--// MODULES
ReplicatedStorage:WaitForChild("Modules")

local ClientModules = ReplicatedFirst:WaitForChild("Modules")
local SkillLibrary = require(ClientModules:WaitForChild("SkillLibrary"))
require(ClientModules:WaitForChild("VfxLibrary"))

--// PACKAGES
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Red = require(Packages:WaitForChild("Red"))

--// VARIABLES
local loadingStages = {
	"Client",
	"SkillPacks",
}

local remoteEvent = Red.Client("LoadingControl")

--// FUNCTIONS
local function completeLoadingStage(stageName: string)
	table.remove(loadingStages, table.find(loadingStages, stageName))

	if #loadingStages == 0 then
		print("Data loaded")
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
remoteEvent:On("SkillPacks", function(packs: { [number]: string })
	for _, packName in packs do
		SkillLibrary.AddSkillPack(packName)
	end

	completeLoadingStage("SkillPacks")
	print("Skill packs loaded")
end)

remoteEvent:Fire("ReadyForData")
