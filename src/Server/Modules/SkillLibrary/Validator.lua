--// VARIABLES
local CallValidator = {}

--// MODULE FUNCTIONS
function CallValidator.Start(skillName: string, identifier: string, tempData: {}, skillData: {}, cooldownStore: {})
	if cooldownStore:IsOnCooldown(skillName) then
		return
	end

	if tempData.BlockOtherSkills or tempData.ActiveSkills[identifier] then
		return
	end

	if tempData.CantUseSkills or tempData.Stun then
		return
	end
	
	local requirements = skillData.Requirements
	if requirements then
		for key, value in requirements do
			if type(key) == "number" then
				local tempDataValue = tempData[key]
				if not tempDataValue or tempDataValue < value then
					return
				end
			else
				if tempData[key] ~= value then
					return
				end
			end
		end
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

	if not skillData.Interruptable then
		return
	end
	
	if not activeSkill then
		return
	end

	return true
end

return CallValidator