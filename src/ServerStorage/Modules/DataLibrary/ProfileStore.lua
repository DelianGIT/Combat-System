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
	CreateProfile:(self:ProfileStore, player:Player, data:ProfileTemplate) -> Profile,
	DeleteProfile:(self:ProfileStore, player:Player) -> (),
	GetProfile:(self:ProfileStore, player:Player) -> Profile
}

--// CLASSES
local ProfileStore:ProfileStore = {}
ProfileStore.__index = ProfileStore

--// PROFILESTORE FUNCTIONS
function ProfileStore:CreateProfile(player:Player, data:ProfileTemplate?):Profile
	local profile
	if data then
		profile = Utilities.Reconcile(data, self._profileTemplate)
	else
		profile = Utilities.DeepTableClone(self._profileTemplate)
		profile.Metadata.CreatedTime = tick()
	end

	self._profiles[player] = profile
	print("Created data profile for "..player.Name)

	return profile
end

function ProfileStore:DeleteProfile(player:Player):()
	if not self._profiles[player] then
		warn(player.Name.."'s profile already doesn't exist")
	else
		self._profiles[player] = nil
		print("Deleted "..player.Name.."'s data profile")
	end
end

function ProfileStore:GetProfile(player:Player):Profile
	local profile = self._profiles[player]
	if not profile then
		warn(player.Name.."'s profile not found")
	else
		return profile
	end
end

--// MODULE FUNCTIONS
return {
	new = function(profileTemplate:ProfileTemplate):ProfileStore
		local profileStore = setmetatable({
			_profiles = {},
			_profileTemplate = {
				Data = profileTemplate,
				Metadata = {
					CreatedTime = 0,
					UpdatedTime = 0
				}
			}
		}, ProfileStore)

		print("Created profile store")
		return profileStore
	end
}