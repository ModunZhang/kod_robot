--
-- Author: Kenny Dai
-- Date: 2015-05-11 14:38:14
--
local UpgradeBuilding = import(".UpgradeBuilding")
local AcademyUpgradeBuilding = class("AcademyUpgradeBuilding", UpgradeBuilding)
function AcademyUpgradeBuilding:GetAcademyConfig()
    return self.config_building_function[self:GetType()][self:GetLevel()]
end
function AcademyUpgradeBuilding:GetAcademyNextLevelConfig()
    return self.config_building_function[self:GetType()][self:GetNextLevel()]
end
return AcademyUpgradeBuilding