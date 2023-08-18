--// SERVICES
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// MODULES
local ServerModules = ServerStorage.Modules
local TempData = require(ServerModules.TempData)
local Utilities = require(ServerModules.Utilities)

local SkillPacks = require(script.SkillPacks)

--// PACKAGES
local Packages = ReplicatedStorage.Packages
local Trove = require(Packages.Trove)

--// TYPES
type SkillData = {
	Cooldown:number,
	InputKey: Enum.UserInputType | Enum.KeyCode,
	InputState:"Begin" | "End" | "DoubleClick" | "Hold",
	Duration:number?,
	Trove:any,
	Communicator:any
}
type SkillFunction = (self:SkillData, player:Player, tempData:{[string]:any}) -> ()
type SkillsFunctions = {
	Begin:SkillFunction,
	End:SkillFunction,
	Interrupt:SkillFunction
}

--// CLASSES
local Skill = {}
Skill.__index = Skill

local SkillPack = {}
SkillPack.__index = SkillPack

--// VARIABLES
local SkillLibrary = {}

--// PACK FUNCTIONS
function Skill:Start(player:Player, tempData:{[string]:any})
	local startFunction = self.Functions.Start

	local success, err = pcall(startFunction, self, player, tempData)
end

function Skill:End()
	
end

function Skill:Interrupt()
	
end

--// MODULE FUNCTIONS
function SkillLibrary.GiveSkillPack(tempData:Player, packName:string)
	if tempData.skillPacks[packName] then
		warn("Player already has skill pack "..packName)
	end

	local pack = SkillPacks[packName]
	if not pack then
		error("Skill pack "..packName.." not found")
	end

	local packToGive = {}
	for skillName, skill in pack do
		packToGive[skillName] = setmetatable({
			Data = Utilities.DeepTableClone(skill.Data),
			Functions = skill.Functions
		}, Skill)
	end

	tempData.skillPacks[packName] = packToGive
end

return SkillLibrary