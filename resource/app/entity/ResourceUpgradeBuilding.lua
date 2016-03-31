local config_house_function = GameDatas.HouseFunction
local config_house_levelup = GameDatas.HouseLevelUp
local UpgradeBuilding = import(".UpgradeBuilding")
local ResourceUpgradeBuilding = class("ResourceUpgradeBuilding", UpgradeBuilding)

function ResourceUpgradeBuilding:ctor(building_info)
    ResourceUpgradeBuilding.super.ctor(self, building_info)
    self.config_building_function = config_house_function
    self.config_building_levelup = config_house_levelup
end
function ResourceUpgradeBuilding:GetNextLevel()
    local config = config_house_levelup[self:GetType()]
    return #config == self.level and self.level or self.level + 1
end


function ResourceUpgradeBuilding:IsAbleToUpgrade(isUpgradeNow)
    local house = {type = self:GetType(), level = self:GetLevel()}
    local citizen = UtilsForBuilding:GetLevelUpConfigBy(self:BelongCity():GetUser(), house).citizen
    local next_citizen = UtilsForBuilding:GetLevelUpConfigBy(self:BelongCity():GetUser(), house, 1).citizen
    local free_citizen_limit = self:BelongCity():GetUser():GetResProduction("citizen").limit
    if (next_citizen-citizen)>free_citizen_limit then
        return UpgradeBuilding.NOT_ABLE_TO_UPGRADE.FREE_CITIZEN_ERROR
    end
    return ResourceUpgradeBuilding.super.IsAbleToUpgrade(self,isUpgradeNow)
end
return ResourceUpgradeBuilding


