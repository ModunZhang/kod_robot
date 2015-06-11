local config_dwelling = GameDatas.HouseFunction.dwelling
local ResourceManager = import(".ResourceManager")
local ResourceUpgradeBuilding = import(".ResourceUpgradeBuilding")
local CitizenResourceUpgradeBuilding = class("CitizenResourceUpgradeBuilding", ResourceUpgradeBuilding)

function CitizenResourceUpgradeBuilding:ctor(building_info)
    CitizenResourceUpgradeBuilding.super.ctor(self, building_info)
end
function CitizenResourceUpgradeBuilding:GetProductionLimit()
	if self:GetLevel() > 0 then
    	return config_dwelling[self:GetEfficiencyLevel()].citizen
    end
    return 0
end
function CitizenResourceUpgradeBuilding:GetUpdateResourceType()
    return ResourceManager.RESOURCE_TYPE.CITIZEN
end
function CitizenResourceUpgradeBuilding:GetNextLevelCitizen()
    return config_dwelling[self:GetNextLevel()].citizen
end

return CitizenResourceUpgradeBuilding

