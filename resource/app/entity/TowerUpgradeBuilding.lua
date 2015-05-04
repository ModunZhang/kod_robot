local Orient = import("..entity.Orient")
local UpgradeBuilding = import(".UpgradeBuilding")
local TowerUpgradeBuilding = class("TowerUpgradeBuilding", UpgradeBuilding)
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
end
function TowerUpgradeBuilding:AddUpgradeListener(listener)
    return self:BelongCity():GetTower():AddUpgradeListener(listener)
end
function TowerUpgradeBuilding:RemoveUpgradeListener(listener)
    self:BelongCity():GetTower():RemoveUpgradeListener(listener)
end
-- function TowerUpgradeBuilding:IsEfficiency()
--     local ex, ey = self:BelongCity():GetGate():GetEndPos()
--     return self:IsVisible() 
--     -- and not (self.w == 1 and self.h == 1 and abs(self.x - ex) + abs(self.y - ey) == 1)
-- end
function TowerUpgradeBuilding:IsVisible()
    return (self:GetOrient() ~= Orient.NEG_X and
        self:GetOrient() ~= Orient.NEG_Y and
        self:GetOrient() ~= Orient.UP) or
        (self.x > 0 and self.y > 0)
end
function TowerUpgradeBuilding:GetSubOrient()
    return self.sub_orient
end
-- function TowerUpgradeBuilding:UniqueKey()
--     return string.format("%s_%d", self:GetType(), self:TowerId())
-- end
-- function TowerUpgradeBuilding:CopyValueFrom(building)
--     TowerUpgradeBuilding.super.CopyValueFrom(self, building)
--     self.tower_id = building.tower_id
--     self.w = building.w
--     self.h = building.h
-- end
-- function TowerUpgradeBuilding:TowerId()
--     return self.tower_id
-- end
-- function TowerUpgradeBuilding:SetTowerId(tower_id)
--     self.tower_id = tower_id
--     return self
-- end
-- function TowerUpgradeBuilding:IsUnlocked()
--     return self.tower_id
-- end
function TowerUpgradeBuilding:GetGlobalRegion()
    local start_x, end_x, start_y, end_y = TowerUpgradeBuilding.super.GetGlobalRegion(self)
    if self.orient ~= Orient.NONE then
        return start_x, end_x, start_y, end_y
    else
        return start_x - 1, end_x + 1, start_y - 1, end_y + 1
    end
end
-- local function get_tower_event_by_location(tower_events, tower_id)
--     for _, event in pairs(tower_events) do
--         if event.location == tower_id then
--             return event
--         end
--     end
-- end
-- function TowerUpgradeBuilding:OnUserDataChanged(user_data, current_time)
--     if self.tower_id and user_data.towerEvents then
--         local level = self:GetLevel()
--         local tower_events = user_data.towerEvents
--         local event = get_tower_event_by_location(tower_events, self.tower_id)
--         local finishTime = event == nil and 0 or event.finishTime / 1000
--         local tower_info = user_data.towers["location_"..self.tower_id]
--         self:OnEvent(event)
--         self:OnHandle(tower_info.level, finishTime)
--     end
-- end
-- 获取对各兵种攻击力
-- function TowerUpgradeBuilding:GetAtk()
--     local config = self.config_building_function[self:GetType()]
--     local level = self.level
--     local c = config[level]
--     return c.infantry,c.archer,c.cavalry,c.siege
-- end

return TowerUpgradeBuilding


