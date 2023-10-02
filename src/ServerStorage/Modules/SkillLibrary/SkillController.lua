--// VARIABLES
local SkillController = {}

--// MODULE FUNCTIONS
function SkillController.CanStart(skillName: string, tempData: {}, cooldownStore: {})
	if cooldownStore:IsOnCooldown(skillName) then
		return
	end

	if tempData.ActiveSkill then
		return
	end

	if not tempData.CanUseSkills then
		return
	end
	
	return true
end

function SkillController.CanEnd(packName: string, skillName: string, activeSkill: {}, skillFunctions: {})
	if not activeSkill then
		return
	end

	if activeSkill.RequestedForEnd or activeSkill.State == "End" then
		return
	end

	if activeSkill.PackName ~= packName or activeSkill.SkillName ~= skillName then
		return
	end

	if not skillFunctions.End then
		return
	end
	
	return true
end

function SkillController.CanInterrupt(ignoreChecks: boolean, packName: string, skillName: string, activeSkill: {}, skillData: {})
	if ignoreChecks then
		return true
	end

	if not skillData.CanBeInterrupted then
		return
	end
	
	if not activeSkill then
		return
	end

	if activeSkill.PackName ~= packName or activeSkill.SkillName ~= skillName then
		return
	end
	
	return true
end

return SkillController