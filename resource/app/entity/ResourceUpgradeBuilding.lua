local config_house_function = GameDatas.HouseFunction
local config_house_levelup = GameDatas.HouseLevelUp
local MaterialManager = import("..entity.MaterialManager")
local UpgradeBuilding = import(".UpgradeBuilding")
local ResourceUpgradeBuilding = class("ResourceUpgradeBuilding", UpgradeBuilding)

function ResourceUpgradeBuilding:ctor(building_info)
    ResourceUpgradeBuilding.super.ctor(self, building_info)
    self.config_building_function = config_house_function
    self.config_building_levelup = config_house_levelup
end
function ResourceUpgradeBuilding:GetNextLevelUpgradeTimeByLevel(level)
    local config = config_house_levelup[self:GetType()]
    if config then
        local is_max_level = #config == level
        return is_max_level and 0 or config[level + 1].buildTime
    end
    return 1
end
function ResourceUpgradeBuilding:GetNextLevel()
    local config = config_house_levelup[self:GetType()]
    return #config == self.level and self.level or self.level + 1
end
function ResourceUpgradeBuilding:GetCitizen()
    local config = config_house_levelup[self:GetType()]
    local current_config = self:IsUpgrading() and config[self:GetNextLevel()] or config[self:GetLevel()]
    if current_config then
        return current_config.citizen
    end
    return 0
end
function ResourceUpgradeBuilding:GetNextLevelLevelCitizen()
    local config = config_house_levelup[self:GetType()]
    return config[self:GetNextLevel()].citizen
end
function ResourceUpgradeBuilding:GetProductionPerHour()
    local config = config_house_function[self:GetType()]
    if self:GetLevel() > 0 then
        return config[self:GetEfficiencyLevel()].production
    end
    return 0
end
function ResourceUpgradeBuilding:GetNextLevelProductionPerHour()
    local config = config_house_function[self:GetType()]
    local current_config = config[self:GetNextLevel()]
    return current_config.production
end
function ResourceUpgradeBuilding:GetUpdateResourceType()
    return nil
end

function ResourceUpgradeBuilding:IsAbleToUpgrade(isUpgradeNow)
    -- 升级是否使空闲城民小于0
    local resource_manager = City:GetResourceManager()
    local free_citizen_limit = resource_manager:GetPopulationResource():GetValueLimit()
    local current_citizen = self:GetCitizen()
    local next_level_citizen = self:GetNextLevelLevelCitizen()
    if (next_level_citizen-current_citizen)>free_citizen_limit then
        return UpgradeBuilding.NOT_ABLE_TO_UPGRADE.FREE_CITIZEN_ERROR
    end
    return ResourceUpgradeBuilding.super.IsAbleToUpgrade(self,isUpgradeNow)
end
return ResourceUpgradeBuilding


