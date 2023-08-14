--// MODULES
local Utilities = require(script.Parent.Utilities)

--// TYPES
export type ProfileTemplate = {[string]:any}

export type Profile = {
	Data:ProfileTemplate,
	Metadata:{
		CreatedTime:number,
		UpdatedTime:number
	}
}

export type ProfileStore = {
	Profiles:{Profile},
	ProfileTemplate:ProfileTemplate
}

--// CLASSES
local ProfileStore:ProfileStore = {}
ProfileStore.__index = ProfileStore

--// PROFILESTORE FUNCTIONS
function ProfileStore:CreateProfile(player:Player, data:ProfileTemplate?):Profile
	local profile
	if data then
		profile = Utilities.Reconcile(data, self.ProfileTemplate)
	else
		profile = Utilities.DeepTableClone(self.ProfileTemplate)
		profile.Metadata.CreatedTime = tick()
	end

	self.Profiles[player.UserId] = profile
	return profile
end

function ProfileStore:DeleteProfile(player:Player):nil
	if not self.Profiles[player.UserId] then
		warn(player.Name.."'s profile already doesn't exist")
	else
		self.Profiles[player.UserId] = nil
	end
end

function ProfileStore:GetProfile(player:Player):Profile
	local profile = self.Profiles[player.UserId]
	if not profile then
		warn(player.Name.."'s profile not found")
	else
		return self.Profiles[player.UserId]
	end
end

--// MODULE FUNCTIONS
return {
	new = function(profileTemplate:ProfileTemplate):ProfileStore
		profileTemplate = {
			Data = Utilities.DeepTableClone(profileTemplate),
			Metadata = {
				CreatedTime = 0,
				UpdatedTime = 0
			}
		}

		local profileStore = setmetatable({
			Profiles = {},
			ProfileTemplate = profileTemplate
		}, ProfileStore)

		return profileStore
	end
}