--// SERVICES
local ServerStorage = game:GetService("ServerStorage")

--// FUNCTIONS
local function spawned(_, character: Model)
	local humanoid = character.Humanoid
	humanoid.MaxHealth = math.huge
	humanoid.Health = math.huge
end

return {
	SpawnedFunction = spawned,
	Character = ServerStorage.Assets.Npc.Dummy,
}
