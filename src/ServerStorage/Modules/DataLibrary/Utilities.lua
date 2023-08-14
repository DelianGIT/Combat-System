--// SERVICES
local DataStoreService = game:GetService("DataStoreService")

--// VARIABLES
local Utilities = {}

--// MODULE FUNCTIONS
function Utilities.DeepTableClone(tableToClone:{any})
	local result = {}
	
	for key, value in pairs(tableToClone) do
		if type(value) == "table" then
			result[key] = Utilities.DeepTableClone(value)
		else
			result[key] = value
		end
	end

	return result
end

function Utilities.Reconcile(data:{[string]:any}, template:{[string]:any})
	local result = {}

	for key, templateValue in pairs(template) do
		if type(key) ~= "string" then continue end

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

function Utilities.WaitForRequestBudget(requestType:Enum.DataStoreRequestType)
	local budget = DataStoreService:GetRequestBudgetForRequestType(requestType)

	while budget < 1 do
		budget = DataStoreService:GetRequestBudgetForRequestType(requestType)
		task.wait(5)
	end
end

function Utilities.GetAsync(dataStore:GlobalDataStore | OrderedDataStore, key:string)
	local success, result
	local attempts = 0
	
	repeat
		Utilities.WaitForRequestBudget(Enum.DataStoreRequestType.GetAsync)
		
		success, result = pcall(dataStore.GetAsync, dataStore, key)
		attempts += 1

		if not success then warn(result) end
	until success or attempts >= 5
	
	return success, result
end

function Utilities.SetAsync(dataStore:DataStore, key:string, value:any)
	local success, err
	local attempts = 0
	
	repeat
		Utilities.WaitForRequestBudget(Enum.DataStoreRequestType.SetIncrementAsync)
		
		success, err = pcall(dataStore.SetAsync, dataStore, key, value)
		attempts += 1

		if not success then warn(err) break end
	until success or attempts >= 5
	
	return success, err
end

return Utilities