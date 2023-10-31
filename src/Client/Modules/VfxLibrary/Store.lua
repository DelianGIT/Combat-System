--// SERVICES
local ReplicatedFirst = game:GetService("ReplicatedFirst")

--// CONFIG
local VFX_FOLDER = ReplicatedFirst.Vfx

--// VARIABLES
local store = {}

--// REQUIRING VFX MODULES
for _, folder in VFX_FOLDER:GetChildren() do
	local pack = {}

	for _, module in folder:GetChildren() do
		local success, result = pcall(require, module)
		if success then
			pack[module.Name] = result
		else
			warn("Vfx module " .. folder.Name .. "_" .. module.Name .. " threw an error: " .. result)
		end
	end

	store[folder.Name] = pack
end

return store
