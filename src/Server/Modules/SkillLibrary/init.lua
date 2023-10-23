--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// MODULES
local Controller = require(script.Controller)

--// VARIABLES
local remoteEvents = ReplicatedStorage.Events
local remoteEvent = require(remoteEvents.SkillLibrary):Server()

local SkillLibrary = {}

--// MODULE FUNCTIONS
function SkillLibrary.GiveSkillPack(name: string, owner: Player | {}, tempData: {}, dontFireEvent: boolean?)
	local existingPacks = tempData.SkillPacks
	if existingPacks[name] then
		warn("Player " .. owner.Name .. " already has skill pack " .. name)
		return
	end

	local pack = Controller.MakeSkillPack(name, owner, tempData)
	if not pack then return end

	if not tempData.IsNpc and not dontFireEvent then
		remoteEvent:Fire(owner, "Add", name)
	end

	existingPacks[name] = pack

	return pack
end

function SkillLibrary.RemoveSkillPack(name: string, player: Player, tempData: {})
	local existingPacks = tempData.SkillPacks
	local pack = existingPacks[name]
	if not pack then
		warn("Player " .. player.Name .. " doesn't have skill pack " .. name)
	end

	local activeSkills = tempData.ActiveSkills
	for identifier, _ in activeSkills do
		local splittedString = string.split(identifier, "_")
		if splittedString[1] == name then
			pack:InterruptSkill(splittedString[2], true)
		end
	end

	if not tempData.IsNpc then
		remoteEvent:Fire(player, "Remove", name)
	end

	existingPacks[name] = nil
end

return SkillLibrary