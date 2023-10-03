--// MODULES
local SkillPack = require(script.SkillPack)

--// VARIABLES
local SkillLibrary = {}

--// MODULE FUNCTIONS
function SkillLibrary.GiveSkillPack(name: string, player: Player | {}, tempData: {})
	local existingPacks = tempData.SkillPacks
	if existingPacks[name] then
		warn("Player " .. player.Name .. " already has skill pack " .. name)
		return
	end
	
	local pack = SkillPack.new(name, player, tempData)
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
			pack:InterruptSkill(skillName)
		end
	end
	
	existingPacks[name] = nil
end

return SkillLibrary