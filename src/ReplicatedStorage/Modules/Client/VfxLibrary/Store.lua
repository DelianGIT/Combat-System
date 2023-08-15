--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// VARIABLES
local vfx = {}

--// CONFIG
local VFX_FOLDER = ReplicatedStorage.Vfx

--// REQUIRING VFX MODULES
for _, packFolder in VFX_FOLDER:GetChildren() do
	local pack = {}

	for _, vfxModule in pack do
		local success, result = pcall(require, vfxModule)
		if success then
			pack[vfxModule.Name] = result
		else
			warn("Vfx module " .. vfxModule.Name .. " of pack " .. packFolder .. " threw an error: " .. result)
		end
	end

	vfx[packFolder.Name] = pack
end
print("Required all vfx modules")

return vfx
