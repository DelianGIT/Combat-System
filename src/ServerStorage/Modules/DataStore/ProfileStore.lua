--// SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// MODULES
local SharedModules = ReplicatedStorage.Modules
local Utilities = require(SharedModules.Utilities)

--// TYPES
export type Template = { [string]: any }
export type Profile = {
	Data: Template,
	Metadata: {
		CreatedTime: number,
		UpdatedTime: number,
	},
}
export type ProfileStore = {
	Profiles: {[Player]: Template},
	Template: Template,

	CreateProfile: (self: ProfileStore, player: Player, data: Template) -> Profile,
	DeleteProfile: (self: ProfileStore, player: Player) -> (),
	GetProfile: (self: ProfileStore, player: Player) -> Profile,
}

--// CLASSES
local ProfileStore: ProfileStore = {}
ProfileStore.__index = ProfileStore

--// FUNCTIONS
local function reconcile(data: Template, template: Template)
	local result = {}

	for key, value in template do
		local keyType = type(key)
		local valueType = type(value)

		if keyType ~= "string" and keyType ~= "number" then
			continue
		end
		
		local dataValue = data[key]
		if valueType ~= type(dataValue) then
			if valueType == "table" then
				result[key] = Utilities.DeepTableClone(value)
			else
				result[key] = value
			end
		else
			if valueType == "table" then
				result[key] = reconcile(dataValue, value)
			else
				result[key] = dataValue
			end
		end
	end

	return result
end

--// PROFILESTORE FUNCTIONS
function ProfileStore:CreateProfile(player: Player, data: Template?): Profile
	local profile
	if data then
		profile = reconcile(data, self.Template)
	else
		profile = Utilities.DeepTableClone(self.Template)
		profile.Metadata.CreatedTime = tick()
	end

	self.Profiles[player] = profile
	
	return profile
end

function ProfileStore:DeleteProfile(player: Player): ()
	self.Profiles[player] = nil
end

function ProfileStore:GetProfile(player: Player): Profile
	return self.Profiles[player]
end

--// MODULE FUNCTIONS
return {
	new = function(profileTemplate: Template): ProfileStore
		return setmetatable({
			Profiles = {},
			Template = {
				Data = profileTemplate,
				Metadata = {
					CreatedTime = 0,
					UpdatedTime = 0,
				},
			},
		}, ProfileStore)
	end,
}
