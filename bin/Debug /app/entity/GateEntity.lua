local UpgradeBuilding = import(".UpgradeBuilding")
local GateEntity = class("GateEntity", UpgradeBuilding)
local config_wall = GameDatas.BuildingFunction.wall
local abs = math.abs
local max = math.max
function GateEntity:ctor(building_info)
    GateEntity.super.ctor(self, building_info)
end
function GateEntity:UniqueKey()
    return string.format("%s", self:GetType())
end
--
function GateEntity:GetWallConfig()
    return config_wall[self:GetLevel()]
end
function GateEntity:GetConfig()
    return config_wall
end
function GateEntity:GetWallNextLevelConfig()
    return config_wall[self:GetNextLevel()]
end
return GateEntity





