--// VARIABLES
local attachment = Instance.new("Attachment")
local bodyVelocity = Instance.new("BodyVelocity")
local alignPosition = Instance.new("AlignPosition")
local alignOrientation = Instance.new("AlignOrientation")

local BodyMover = {}

--// MODULE FUNCTIONS
function BodyMover.CreateAttachment(character: Model)
	local newAttachment = attachment:Clone()
	newAttachment.Parent = character.HumanoidRootPart
end

function BodyMover.BodyVelocity(character: Model)
	local humanoidRootPart = character.HumanoidRootPart
	if humanoidRootPart:FindFirstChild("BodyVelocity") then
		return
	end

	local newBodyVelocity = bodyVelocity:Clone()
	newBodyVelocity.Parent = humanoidRootPart

	return newBodyVelocity
end

function BodyMover.AlignPosition(character: Model)
	local humanoidRootPart = character.HumanoidRootPart
	if humanoidRootPart:FindFirstChild("AlignPosition") then
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
	if humanoidRootPart:FindFirstChild("AlignOrientation") then
		return
	end

	local newAlignOrientation = alignOrientation:Clone()
	newAlignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
	newAlignOrientation.Attachment0 = humanoidRootPart.Attachment
	newAlignOrientation.Parent = humanoidRootPart

	return newAlignOrientation
end

return BodyMover