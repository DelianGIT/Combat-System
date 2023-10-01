--// VARIABLES
local alignPosition = Instance.new("AlignPosition")
local alignOrientation = Instance.new("AlignOrientation")
local linearVelocity = Instance.new("LinearVelocity")
local attachment = Instance.new("Attachment")

local BodyMover = {}

--// MODULE FUNCTIONS
function BodyMover.AlignPosition(character: Model)
	local humanoidRootPart = character.HumanoidRootPart
	if humanoidRootPart.AlignPosition then
		return
	end

	local newAlignPosition = alignPosition:Clone()
	newAlignPosition.Mode = Enum.PositionAlignmentMode.OneAttachment
	newAlignPosition.Attachment0 = humanoidRootPart.Attachment
	newAlignPosition.Parent = humanoidRootPart

	return newAlignPosition
end

function BodyMover.AlignOrientation(character: Model)
	local humanoidRootPart = character.HumanoidRootPart
	if humanoidRootPart.AlignOrientation then
		return
	end

	local newAlignOrientation = alignOrientation:Clone()
	newAlignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
	newAlignOrientation.Attachment0 = humanoidRootPart.Attachment
	newAlignOrientation.Parent = humanoidRootPart

	return newAlignOrientation
end

function BodyMover.LinearVelocity(character: Model)
	local humanoidRootPart = character.HumanoidRootPart
	if humanoidRootPart.LinearVelocity then
		return
	end

	local newLinearVelocity = linearVelocity:Clone()
	newLinearVelocity.Attachment0 = humanoidRootPart.Attachment
	newLinearVelocity.Parent = humanoidRootPart

	return newLinearVelocity
end

function BodyMover.CreateAttachment(character: Model)
	local newAttachment = attachment:Clone()
	newAttachment.Parent = character.HumanoidRootPart
end

return BodyMover
