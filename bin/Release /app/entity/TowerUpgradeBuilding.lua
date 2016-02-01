local Orient = import("..entity.Orient")
local Building = import(".Building")
local TowerUpgradeBuilding = class("TowerUpgradeBuilding", Building)
local abs = math.abs
function TowerUpgradeBuilding:ctor(building_info)
    TowerUpgradeBuilding.super.ctor(self, building_info)
    self.sub_orient = building_info.sub_orient
    if self.orient == Orient.X then
        self.w = 1
        self.h = 2
    elseif self.orient == Orient.Y then
        self.w = 2
        self.h = 1
    elseif self.orient == Orient.NEG_X then
        self.w = 1
        self.h = 2
    elseif self.orient == Orient.NEG_Y then
        self.w = 2
        self.h = 1
    elseif self.orient == Orient.RIGHT then
        self.w = 2
        self.h = -2
    elseif self.orient == Orient.DOWN then
        self.w = 2
        self.h = 2
    elseif self.orient == Orient.LEFT then
        self.w = -2
        self.h = 2
    elseif self.orient == Orient.UP then
        self.w = -2
        self.h = -2
    elseif self.orient == Orient.NONE then
        self.w = 1
        self.h = 1
    end
    self.real_entity = self:BelongCity():GetTower()
end
function TowerUpgradeBuilding:GetRealEntity()
    return self.real_entity
end
function TowerUpgradeBuilding:AddUpgradeListener(listener)
    return self.real_entity:AddUpgradeListener(listener)
end
function TowerUpgradeBuilding:RemoveUpgradeListener(listener)
    self.real_entity:RemoveUpgradeListener(listener)
end
function TowerUpgradeBuilding:IsVisible()
    return (self:GetOrient() ~= Orient.NEG_X and
        self:GetOrient() ~= Orient.NEG_Y and
        self:GetOrient() ~= Orient.UP) or
        (self.x > 0 and self.y > 0)
end
function TowerUpgradeBuilding:GetSubOrient()
    return self.sub_orient
end
function TowerUpgradeBuilding:GetGlobalRegion()
    local start_x, end_x, start_y, end_y = TowerUpgradeBuilding.super.GetGlobalRegion(self)
    if self.orient ~= Orient.NONE then
        return start_x, end_x, start_y, end_y
    else
        return start_x - 1, end_x + 1, start_y - 1, end_y + 1
    end
end


return TowerUpgradeBuilding


