local config_function = GameDatas.BuildingFunction.keep
local config_levelup = GameDatas.BuildingLevelUp.keep
local UpgradeBuilding = import(".UpgradeBuilding")
local KeepUpgradeBuilding = class("KeepUpgradeBuilding", UpgradeBuilding)

function KeepUpgradeBuilding:ctor(building_info)
    KeepUpgradeBuilding.super.ctor(self, building_info)
end
function KeepUpgradeBuilding:GetFreeUnlockPoint(city)
    local unlock_tile_count = 0
    city:IteratorTilesByFunc(function(x, y, tile)
        local building = city:GetBuildingByLocationId(tile.location_id)
        if building then
            unlock_tile_count = unlock_tile_count + ((tile:IsUnlocked() or building:IsUpgrading()) and 1 or 0)
        end
    end)
    return self:GetUnlockPoint() - unlock_tile_count
end
function KeepUpgradeBuilding:GetUnlockPoint()
    return config_function[self:GetEfficiencyLevel()].unlock
end

function KeepUpgradeBuilding:GetBeHelpedCount()
    return config_function[self:GetEfficiencyLevel()].beHelpedCount
end

function KeepUpgradeBuilding:GetNextLevelUnlockPoint()
    local level = self:GetNextLevel()
    return config_function[level].unlock
end

function KeepUpgradeBuilding:GetNextLevelBeHelpedCount()
    local level = self:GetNextLevel()
    return config_function[level].beHelpedCount
end

return KeepUpgradeBuilding



