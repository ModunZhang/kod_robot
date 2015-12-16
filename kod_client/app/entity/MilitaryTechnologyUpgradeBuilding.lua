--
-- Author: Kenny Dai
-- Date: 2015-05-12 19:58:12
--
local UpgradeBuilding = import(".UpgradeBuilding")
local MilitaryTechnologyUpgradeBuilding = class("MilitaryTechnologyUpgradeBuilding", UpgradeBuilding)

function MilitaryTechnologyUpgradeBuilding:GetEfficiency()
    local config_function = self.config_building_function[self:GetType()]
    return config_function[self:GetEfficiencyLevel()].efficiency
end
function MilitaryTechnologyUpgradeBuilding:GetNextLevelEfficiency()
    local config_function = self.config_building_function[self:GetType()]
    return config_function[self:GetNextLevel()].efficiency
end

return MilitaryTechnologyUpgradeBuilding


