local UpgradeBuilding = import(".UpgradeBuilding")
local TowerEntity = class("TowerEntity", UpgradeBuilding)
local abs = math.abs
function TowerEntity:ctor(building_info)
    TowerEntity.super.ctor(self, building_info)
end
function TowerEntity:UniqueKey()
    return string.format("%s", self:GetType())
end
-- 获取对各兵种攻击力
function TowerEntity:GetAtk()
    local config = self.config_building_function[self:GetType()]
    local level = self.level
    local c = config[level]
    return c.infantry,c.archer,c.cavalry,c.siege,c.defencePower
end
function TowerEntity:GetTowerConfig()
    return self.config_building_function[self:GetType()][self:GetLevel()]
end
function TowerEntity:GetTowerNextLevelConfig()
    return self.config_building_function[self:GetType()][self:GetNextLevel()]
end
return TowerEntity





