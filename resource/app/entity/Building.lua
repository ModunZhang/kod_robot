local Enum = import("..utils.Enum")
local Orient = import(".Orient")
local Building = class("Building")
local orient_desc = {
    [Orient.X] = "Orient.X",
    [Orient.NEG_X] = "Orient.NEG_X",
    [Orient.Y] = "Orient.Y",
    [Orient.NEG_Y] = "Orient.NEG_Y",
    [Orient.RIGHT] = "Orient.RIGHT",
    [Orient.DOWN] = "Orient.DOWN",
    [Orient.LEFT] = "Orient.LEFT",
    [Orient.UP] = "Orient.UP",
    [Orient.NONE] = "Orient.NONE",
}
local sort_map = Enum(
    "keep",
    "watchTower",
    "warehouse",
    "dragonEyrie",
    "barracks",
    "hospital",
    "academy",
    "materialDepot",
    "blackSmith",
    "foundry",
    "stoneMason",
    "lumbermill",
    "mill",
    "tradeGuild",
    "townHall",
    "toolShop",
    "trainingGround",
    "hunterHall",
    "stable",
    "workshop",
    "dwelling",
    "woodcutter",
    "farmer",
    "quarrier",
    "miner",
    "wall",
    "tower"
)
local pairs = pairs


function Building:ctor(building_info)
    assert(building_info)
    self.x = building_info.x and building_info.x or 0
    self.y = building_info.y and building_info.y or 0
    self.w = building_info.w and building_info.w or 1
    self.h = building_info.h and building_info.h or 1
    self.building_type = building_info.building_type and building_info.building_type or "none"
    self.orient = building_info.orient and building_info.orient or Orient.X
    self.can_change_head = self.w ~= self.h
    self.city = building_info.city
end
function Building:BelongCity()
    return self.city
end
function Building:OnTimer(current_time)
end
function Building:GetSize()
    return self.w, self.h
end
function Building:GetType()
    return self.building_type
end
local house_type = {
    ["dwelling"] = true,
    ["woodcutter"] = true,
    ["farmer"] = true,
    ["quarrier"] = true,
    ["miner"] = true,
}
function Building:IsHouse()
    return house_type[self.building_type]
end
function Building:GetOrient()
    return self.orient
end
function Building:GetLogicPosition()
    return self.x, self.y
end
function Building:GetMidLogicPosition()
    local start_x, end_x, start_y, end_y = self:GetGlobalRegion()
    return (start_x + end_x) / 2, (start_y + end_y) / 2
end
function Building:Descriptor()
    return orient_desc[self.orient]
end

----
function Building:IsNearByBuildingWithLength(building, len)
    local abs = math.abs
    local start_x, end_x, start_y, end_y = building:GetGlobalRegion()
    local mid_x, mid_y = self:GetMidLogicPosition()
    local w, h = self:GetSize()
    local half_w, half_h = w/2, h/2
    for _,v in pairs({
        {start_x, start_y},
        {start_x, end_y},
        {end_x, start_y},
        {end_x, end_y}
    }) do
        local x = v[1]
        local y = v[2]
        if abs(x - mid_x) < half_w + len and abs(y - mid_y) < half_h + len then
            return true
        end
    end
    return false
end
function Building:IsImportantThanBuilding(building)
    return sort_map[self:GetType()] < sort_map[building:GetType()]
end
function Building:IsAheadOfBuilding(building)
    local ox, oy = building:GetLogicPosition()
    if self.y == oy then
        return self.x < ox
    else
        return self.y < oy
    end
end
function Building:IsSamePositionWith(building)
    local x, y = building:GetLogicPosition()
    return self.x == x and self.y == y
end
function Building:CombineWithOtherBuilding(building)
    assert(self.x == building.x or self.y == building.y)
    assert(self.orient == building.orient)
    assert(self.w == building.w and self.h == building.h)
    local max_x = math.max(self.x, building.x)
    local max_y = math.max(self.y, building.y)
    local new_w = self.y == building.y and self.w + building.w or self.w
    local new_h = self.y == building.y and self.h or self.h + building.h
    return Building.new{
        building_type = self:GetType(),
        x = max_x,
        y = max_y,
        w = new_w,
        h = new_h,
        city = self:BelongCity(),
    }
end
function Building:IsIntersectWithOtherBuilding(building)
    local other_x, other_y = building:GetLogicPosition()
    local is_too_near = math.abs(self.x - other_x) < 10 and math.abs(self.y - other_y) < 10
    if is_too_near then
        repeat
            if self:IsContainPoint(building:GetTopLeftPoint()) then
                return true
            end
            if self:IsContainPoint(building:GetTopRightPoint()) then
                return true
            end
            if self:IsContainPoint(building:GetBottomLeftPoint()) then
                return true
            end
            if self:IsContainPoint(building:GetBottomRightPoint()) then
                return true
            end
        until true
    end
    return false
end
---
function Building:GetTopLeftPoint()
    local start_x, end_x, start_y, end_y = self:GetGlobalRegion()
    return start_x, start_y
end
function Building:GetTopRightPoint()
    local start_x, end_x, start_y, end_y = self:GetGlobalRegion()
    return end_x, start_y
end
function Building:GetBottomLeftPoint()
    local start_x, end_x, start_y, end_y = self:GetGlobalRegion()
    return start_x, end_y
end
function Building:GetBottomRightPoint()
    local start_x, end_x, start_y, end_y = self:GetGlobalRegion()
    return end_x, end_y
end
function Building:IsContainPoint(x, y)
    local start_x, end_x, start_y, end_y = self:GetGlobalRegion()
    return x >= start_x and x <= end_x and y >= start_y and y <= end_y
end
function Building:GetGlobalRegion()
    local x, y, w, h = self.x, self.y, self.w, self.h
    local start_x, end_x, start_y, end_y

    local is_orient_x = w > 0
    local is_orient_neg_x = not is_orient_x
    local is_orient_y = h > 0
    local is_orient_neg_y = not is_orient_y

    if is_orient_x then
        start_x, end_x = x - w + 1, x
    elseif is_orient_neg_x then
        start_x, end_x = x, x + math.abs(w) - 1
    end

    if is_orient_y then
        start_y, end_y = y - h + 1, y
    elseif is_orient_neg_y then
        start_y, end_y = y, y + math.abs(h) - 1
    end
    return start_x, end_x, start_y, end_y
end
return Building







