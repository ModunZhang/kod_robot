local config_function = GameDatas.BuildingFunction.materialDepot
local config_levelup = GameDatas.BuildingLevelUp.materialDepot
local UpgradeBuilding = import(".UpgradeBuilding")
local MaterialDepotUpgradeBuilding = class("MaterialDepotUpgradeBuilding", UpgradeBuilding)

function MaterialDepotUpgradeBuilding:ctor(building_info)
    MaterialDepotUpgradeBuilding.super.ctor(self, building_info)
end
function MaterialDepotUpgradeBuilding:GetNextLevelMaxMaterial()
    local level = self:GetNextLevel()
    return level == 0 and 0 or config_function[level].maxMaterial
end
function MaterialDepotUpgradeBuilding:GetMaxMaterial()
    local level = self:GetLevel()
    return level == 0 and 0 or config_function[level].maxMaterial
end
function MaterialDepotUpgradeBuilding:GetMaxSoldierMaterial()
    local level = self:GetLevel()
    return level == 0 and 0 or config_function[level].maxSoldierMaterial
end
function MaterialDepotUpgradeBuilding:GetMaxDragonMaterial()
    local level = self:GetLevel()
    return level == 0 and 0 or config_function[level].maxDragonMaterial
end
function MaterialDepotUpgradeBuilding:GetMaxDragonEquipment()
    local level = self:GetLevel()
    return level == 0 and 0 or config_function[level].maxDragonEquipment
end
return MaterialDepotUpgradeBuilding


