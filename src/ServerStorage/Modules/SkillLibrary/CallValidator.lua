--// VARIABLES
local CallValidator = {}

--// MODULE FUNCTIONS
function CallValidator.Start(tempData: {}, cooldownStore: {}, skillName: string, identifier: string)
	if cooldownStore:IsOnCooldown(skillName) then
		return
	end
	
	if tempData.BlockOtherSkills or tempData.ActiveSkills[identifier] then
		return
	end

	if tempData.CantUseSkills then
		return
	end
	
	return true
end

function CallValidator.End(activeSkill: {}, skillFunctions: {})
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

function CallValidator.Interrupt(ignoreChecks: boolean, activeSkill: {}, skillData: {})
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

return CallValidator