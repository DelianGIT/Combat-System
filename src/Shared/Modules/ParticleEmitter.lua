--// VARIABLES
local ParticleEmitter = {}

--// MODULE FUNCTIONS
function ParticleEmitter.EmitParticle(emitter: ParticleEmitter)
	local delayDuration = emitter:GetAttribute("EmitDelay")
	local count = emitter:GetAttribute("EmitCount")

	if delayDuration then
		task.delay(delayDuration, function()
			emitter:Emit(count)
		end)
	else
		emitter:Emit(count)
	end
end

function ParticleEmitter.Emit(parent: BasePart, attachment: Attachment, notClone: boolean)
	if not notClone then
		attachment = attachment:Clone()
		attachment.Parent = parent
	end

	for _, particleEmitter in attachment:GetChildren() do
		if particleEmitter:IsA("ParticleEmitter") then
			ParticleEmitter.EmitParticle(particleEmitter)
		end
	end
end

function ParticleEmitter.EmitAndDestroy(parent: BasePart, attachment: Attachment, notClone: boolean)
	if not notClone then
		attachment = attachment:Clone()
		attachment.Parent = parent
	end

	local biggestLifetime = 0
	local biggestDelay = 0
	for _, particleEmitter in attachment:GetChildren() do
		if not particleEmitter:IsA("ParticleEmitter") then
			continue
		end

		local lifetime = particleEmitter.Lifetime.Max
		if lifetime > biggestLifetime then
			biggestLifetime = lifetime
		end

		local delayDuration = particleEmitter:GetAttribute("EmitDelay")
		local count = particleEmitter:GetAttribute("EmitCount")

		if delayDuration then
			if delayDuration > biggestDelay then
				biggestDelay = delayDuration
			end

			task.delay(delayDuration, function()
				particleEmitter:Emit(count)
			end)
		else
			particleEmitter:Emit(count)
		end
	end

	task.delay(biggestLifetime + biggestDelay, function()
		attachment:Destroy()
	end)
end

return ParticleEmitter
