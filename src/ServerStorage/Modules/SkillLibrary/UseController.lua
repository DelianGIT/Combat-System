--// VARIABLES
local SkillController = {}

--// MODULE FUNCTIONS
function SkillController.CanStart(skillName: string, identifier: string, tempData: {}, cooldownStore: {})
	if cooldownStore:IsOnCooldown(skillName) then
		return
	end

	if tempData.BlockOtherSkills or tempData.ActiveSkills[identifier] then
		return
	end

	if not tempData.CanUseSkills then
		return
	end
	
	return true
end

function SkillController.CanEnd(activeSkill: {}, skillFunctions: {})
	if not activeSkill then
		return
	end

	if activeSkill.RequestedForEnd or activeSkill.State == "End" then
		return
	end

	if not skillFunctions.End then
		return
	end
	
	return true
end

function SkillController.CanInterrupt(ignoreChecks: boolean, activeSkill: {}, skillData: {})
	if ignoreChecks then
		return true
	end

	if not skillData.CanBeInterrupted then
		return
	end
	
	if not activeSkill then
		return
	end

	return true
end

return SkillController