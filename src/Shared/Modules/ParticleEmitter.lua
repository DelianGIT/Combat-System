--// VARIABLES
local ParticleEmitter = {}

--// MODULE FUNCTIONS
function ParticleEmitter.Emit(parent: BasePart, attachment: Attachment)
	attachment = attachment:Clone()
	attachment.Parent = parent

	for _, particleEmitter in attachment:GetChildren() do
		if not particleEmitter:IsA("ParticleEmitter") then
			continue
		end

		local delayDuration = particleEmitter:GetAttribute("EmitDelay")
		local count = particleEmitter:GetAttribute("EmitCount")
		
		if delayDuration then
			task.delay(delayDuration, function()
				particleEmitter:Emit(count)
			end)
		else
			particleEmitter:Emit(count)
		end
	end
end

return ParticleEmitter