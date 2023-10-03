--// VARIABLES
local Utilities = {}

--// MODULE FUNCTIONS
function Utilities.Emit(effect: BasePart | Attachment)
	for _, particleEmitter in ipairs(effect:GetDescendants()) do
		if not particleEmitter:IsA("ParticleEmitter") then
			continue
		end

		local emitDelay = particleEmitter:GetAttribute("EmitDelay")
		local emitCount = particleEmitter:GetAttribute("EmitCount")

		if emitDelay then
			task.delay(emitDelay, function()
				particleEmitter:Emit(emitCount)
			end)
		else
			particleEmitter:Emit(emitCount)
		end
	end
end

function Utilities.DelayDestruction(delayDuration: number, instance: Instance)
	task.delay(delayDuration, function()
		instance:Destroy()
	end)
end

return Utilities
