--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// MODULES
local SkillPack = require(script.SkillPack)

--// VARIABLES
local SkillLibrary = {}

--// MODULE FUNCTIONS
local remoteEvents = ReplicatedStorage.Events
local remoteEvent = require(remoteEvents.SkillLibrary):Server()

function SkillLibrary.GiveSkillPack(name: string, owner: Player | {}, tempData: {}, dontFireEvent: boolean?)
	local existingPacks = tempData.SkillPacks
	if existingPacks[name] then
		warn("Player " .. owner.Name .. " already has skill pack " .. name)
		return
	end

	local pack = SkillPack.new(name, owner, tempData)
	if not pack then return end

	if not tempData.IsNpc and not dontFireEvent then
		remoteEvent:Fire(owner, "AddSkillPack", name)
	end

	existingPacks[name] = pack

	return pack
end

function SkillLibrary.TakeSkillPack(name: string, player: Player, tempData: {})
	local existingPacks = tempData.SkillPacks

	local pack = existingPacks[name]
	if not pack then
		warn("Player " .. player.Name .. " doesn't have skill pack " .. name)
	end

	local activeSkills = tempData.ActiveSkills
	for identifier, properties in activeSkills do
		local skillName = string.split(identifier, "_")[2]
		if properties.PackName == name then
			pack:InterruptSkill(skillName, true)
		end
	end

	if not tempData.IsNpc then
		remoteEvent:Fire(player, "RemoveSkillPack", name)
	end

	existingPacks[name] = nil
end

return SkillLibrary