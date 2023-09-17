--// SERVICES
local DataStoreService = game:GetService("DataStoreService")
local ServerStorage = game:GetService("ServerStorage")

--// MODULES
local ServerModules = ServerStorage.Modules
local UtilitiesModule = require(ServerModules.Utilities)

--// VARIABLES
local Utilities = {}

--// MODULE FUNCTIONS
Utilities.DeepTableClone = UtilitiesModule.DeepTableClone

function Utilities.Reconcile(data: { [string | number]: any }, template: { [string | number]: any })
	local result = {}

	for key, templateValue in template do
		local keyType = type(key)
		if keyType ~= "string" and keyType ~= "number" then
			continue
		end

		local dataValue = data[key]
		local valueType = type(templateValue)

		if valueType ~= type(dataValue) then
			if valueType == "table" then
				result[key] = Utilities.DeepTableClone(templateValue)
			else
				result[key] = templateValue
			end
		else
			if valueType == "table" then
				result[key] = Utilities.Reconcile(dataValue, templateValue)
			else
				result[key] = dataValue
			end
		end
	end

	return result
end

function Utilities.WaitForRequestBudget(requestType: Enum.DataStoreRequestType)
	local budget = DataStoreService:GetRequestBudgetForRequestType(requestType)

	while budget < 1 do
		task.wait(5)
		budget = DataStoreService:GetRequestBudgetForRequestType(requestType)
	end
end

function Utilities.GetAsync(dataStore: GlobalDataStore | OrderedDataStore, key: string)
	local success, result
	local attempts = 0

	repeat
		Utilities.WaitForRequestBudget(Enum.DataStoreRequestType.GetAsync)

		success, result = pcall(dataStore.GetAsync, dataStore, key)
		attempts += 1

		if not success then
			warn(result)
		end
	until success or attempts >= 5

	return success, result
end

function Utilities.SetAsync(dataStore: DataStore, key: string, value: any)
	local success, err
	local attempts = 0

	repeat
		Utilities.WaitForRequestBudget(Enum.DataStoreRequestType.SetIncrementAsync)

		success, err = pcall(dataStore.SetAsync, dataStore, key, value)
		attempts += 1

		if not success then
			warn(err)
			break
		end
	until success or attempts >= 5

	return success, err
end

return Utilities
