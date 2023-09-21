--// SERVICES
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")

--// MODULES
local ServerModules = ServerStorage.Modules
local BodyMover = require(ServerModules.BodyMover)

--// VARIABLES
local charactersFolder = workspace.Living.Characters

--// MODULE FUNCTIONS
return {
	Make = function(player: Player)
		local existingCharacter = player.Character
		if existingCharacter then
			existingCharacter:Destroy()
		end

		player.CharacterAdded:Once(function(newCharacter: Model)
			RunService.Heartbeat:Once(function()
				newCharacter.Archivable = true
				newCharacter.Parent = charactersFolder
				newCharacter.Archivable = false
			end)

			BodyMover.CreateAttachment(newCharacter)
		end)

		player:LoadCharacter()
	end
}