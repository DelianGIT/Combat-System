--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// MODULES
local SkillPack = require(script.SkillPack)

--// PACKAGES
local Packages = ReplicatedStorage.Packages
local Red = require(Packages.Red)

--// VARIABLES
local remoteEvent = Red.Server("SkillLibrary")

local SkillLibrary = {}

--// MODULE FUNCTIONS
function SkillLibrary.GiveSkillPack(name: string, player: Player, tempData: {}, dontFireEvent: boolean)
	local existingPacks = tempData.SkillPacks
	if existingPacks[name] then
		warn("Player " .. player.Name .. " already has skill pack " .. name)
		return
	end

	local pack = SkillPack.new(name, player, tempData)
	if not pack then return end

	if not tempData.IsNpc and not dontFireEvent then
		remoteEvent:Fire(player, "Add", name)
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
		remoteEvent:Fire(player, "Remove", name)
	end

	existingPacks[name] = nil
end

return SkillLibrary