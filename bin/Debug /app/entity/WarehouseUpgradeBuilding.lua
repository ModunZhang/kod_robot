local config_function = GameDatas.BuildingFunction.warehouse
local config_levelup = GameDatas.BuildingLevelUp.warehouse
local Observer = import(".Observer")
local UpgradeBuilding = import(".UpgradeBuilding")
local WarehouseUpgradeBuilding = class("WarehouseUpgradeBuilding", UpgradeBuilding)

function WarehouseUpgradeBuilding:ctor(building_info, city)
    WarehouseUpgradeBuilding.super.ctor(self, building_info)
end
function WarehouseUpgradeBuilding:GetResourceValueLimit()
	local level = self:GetEfficiencyLevel()
	return config_function[level].maxWood, config_function[level].maxFood, config_function[level].maxIron, config_function[level].maxStone	
end

function WarehouseUpgradeBuilding:GetResourceNextLevelValueLimit()
	local level = self:GetNextLevel()
	return config_function[level].maxWood, config_function[level].maxFood, config_function[level].maxIron, config_function[level].maxStone	
end

return WarehouseUpgradeBuilding

