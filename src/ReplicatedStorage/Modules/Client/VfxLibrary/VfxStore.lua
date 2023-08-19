--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// VARIABLES
local vfxPacks = {}

--// CONFIG
local VFX_FOLDER = ReplicatedStorage.Vfx

--// REQUIRING VFX MODULES
for _, folder in VFX_FOLDER:GetChildren() do
	local pack = {}

	for _, module in pack do
		local success, result = pcall(require, module)
		if success then
			pack[module.Name] = result
		else
			warn("Vfx module " .. module.Name .. " of pack " .. folder.Name .. " threw an error: " .. result)
		end
	end

	vfxPacks[folder.Name] = pack
end

return vfxPacks
