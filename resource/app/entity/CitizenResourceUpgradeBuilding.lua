local config_dwelling = GameDatas.HouseFunction.dwelling
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
function CitizenResourceUpgradeBuilding:GetNextLevelCitizen()
    return config_dwelling[self:GetNextLevel()].citizen
end
function CitizenResourceUpgradeBuilding:GetResType()
    return "citizen"
end

return CitizenResourceUpgradeBuilding

