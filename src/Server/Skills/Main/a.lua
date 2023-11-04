--// FUNCTIONS
local function punch()
	
end

local function lastPunch()
	
end

local function airPunch()
	
end

local function airLastPunch()
	
end

--// SKILL FUNCTIONS
return {
	Start = function(args: {}, isSpaceDown: boolean)
		local skillData = args.SkillData
		local damageFunc
		if os.clock() - skillData.PunchTime > COMBO_FRAME then
			punchFunc = punch
			skillData.Combo = 2
		elseif skillData.Combo == 5 then
			punchFunc = lastPunch
			skillData.Combo = 1
		else
			punchFunc = punch
			skillData.Combo += 1
		end
		skillData.PunchTime = os.clock()
	end
}