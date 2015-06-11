local Orient = import("..entity.Orient")
local Building = import(".Building")
local WallUpgradeBuilding = class("WallUpgradeBuilding", Building)
local config_wall = GameDatas.BuildingFunction.wall
local abs = math.abs
local max = math.max
function WallUpgradeBuilding:ctor(wall_info)
    WallUpgradeBuilding.super.ctor(self,wall_info)
    self.len = wall_info.len
    self.w, self.h = self:GetSize()
    self.location_id = wall_info.location_id
    self.real_entity = self:BelongCity():GetGate()
end
function WallUpgradeBuilding:GetRealEntity()
    return self.real_entity
end
function WallUpgradeBuilding:AddUpgradeListener(listener)
    if self:IsGate() then
        self.real_entity:AddUpgradeListener(listener)
    end
end
function WallUpgradeBuilding:RemoveUpgradeListener(listener)
    if self:IsGate() then
        self.real_entity:RemoveUpgradeListener(listener)
    end
end

----
function WallUpgradeBuilding:GetSize()
    if self.orient == Orient.X then
        return 1, self.len
    elseif self.orient == Orient.NEG_X then
        return 1, self.len
    elseif self.orient == Orient.Y then
        return self.len, 1
    elseif self.orient == Orient.NEG_Y then
        return self.len, 1
    end
    assert(false)
end
function WallUpgradeBuilding:IsGate()
    return self.is_gate
end
function WallUpgradeBuilding:SetGate()
    self.is_gate = true
    return self
end
function WallUpgradeBuilding:GetMidLogicPosition()
    local start_x, start_y = self:GetStartPos()
    local end_x, end_y = self:GetEndPos()
    return (start_x + end_x) / 2, (start_y + end_y) / 2
end
function WallUpgradeBuilding:GetStartPos()
    local wall = self
    if wall.orient == Orient.NEG_Y then
        return wall.x - wall.len + 1, wall.y
    elseif wall.orient == Orient.X then
        return wall.x, wall.y - wall.len + 1
    elseif wall.orient == Orient.Y then
        return wall.x, wall.y
    elseif wall.orient == Orient.NEG_X then
        return wall.x, wall.y
    end
    assert(false)
end
function WallUpgradeBuilding:GetEndPos()
    local wall = self
    if wall.orient == Orient.NEG_Y then
        return wall.x, wall.y
    elseif wall.orient == Orient.X then
        return wall.x, wall.y
    elseif wall.orient == Orient.Y then
        return wall.x - wall.len + 1, wall.y
    elseif wall.orient == Orient.NEG_X then
        return wall.x, wall.y - wall.len + 1
    end
    assert(false)
end
function WallUpgradeBuilding:IsCrossOver(other_wall)
    local other_start_x, other_start_y = other_wall:GetStartPos()
    local self_start_x, self_start_y = self:GetStartPos()
    local self_end_x, self_end_y = self:GetEndPos()
    return (self_start_x == other_start_x and self_start_y == other_start_y) or
        (self_end_x == other_start_x and self_end_y == other_start_y)
end
function WallUpgradeBuilding:IsDupWithOtherWall(other_wall)
    if other_wall == self then return false end
    local wall = self
    if wall:IsParalleleX() and other_wall:IsParalleleX() then
        return wall.y == other_wall.y and abs(wall.x - other_wall.x) <= 5
    elseif wall:IsParalleleY() and other_wall:IsParalleleY() then
        return wall.x == other_wall.x and abs(wall.y - other_wall.y) <= 5
    end
    return self:IsCrossOver(other_wall)
end
function WallUpgradeBuilding:IsEndJoinStartWithOtherWall(other_wall)
    local wall = self
    local end_x, end_y = wall:GetEndPos()
    local start_x, start_y = other_wall:GetStartPos()
    local is_same_tile = wall.location_id == other_wall.location_id
    if wall:IsParalleleY() and other_wall:IsParalleleY() then
        return end_y == start_y and abs(end_x - start_x) == (is_same_tile and 1 or 3)
    elseif wall:IsParalleleX() and other_wall:IsParalleleX() then
        return end_x == start_x and abs(end_y - start_y) == (is_same_tile and 1 or 3)
    else
        return abs(end_x - start_x) + abs(end_y - start_y) == (is_same_tile and 4 or 2)
    end
end
function WallUpgradeBuilding:IsParalleleY()
    return self.orient == Orient.NEG_Y or self.orient == Orient.Y
end
function WallUpgradeBuilding:IsParalleleX()
    return self.orient == Orient.NEG_X or self.orient == Orient.X
end
function WallUpgradeBuilding:IntersectWithOtherWall(other_wall)
    local wall1 = self
    local wall2 = other_wall
    if wall1.orient == wall2.orient then
        local end_x, end_y = wall1:GetEndPos()
        local start_x, start_y = wall2:GetStartPos()
        if abs(end_x - start_x) + abs(end_y - start_y) == 1 then
            return
        end
        if self:IsGate() then
            return { x = end_x - 1, y = end_y, orient = wall1.orient }
        end
        return { x = (wall1.x + wall2.x) * 0.5, y = (wall1.y + wall2.y) * 0.5, orient = wall1.orient }
    elseif wall1.orient == Orient.X and wall2.orient == Orient.Y then
        return {x = wall1.x, y = wall2.y, orient = Orient.DOWN}
    elseif wall1.orient == Orient.Y and wall2.orient == Orient.NEG_X then
        return {x = wall2.x, y = wall1.y, orient = Orient.LEFT}
    elseif wall1.orient == Orient.NEG_X and wall2.orient == Orient.NEG_Y then
        return {x = wall1.x, y = wall2.y, orient = Orient.UP}
    elseif wall1.orient == Orient.NEG_Y and wall2.orient == Orient.X then
        return {x = wall2.x, y = wall1.y, orient = Orient.RIGHT}
    elseif wall1.orient == Orient.Y and wall2.orient == Orient.X then
        return {x = wall2.x, y = wall1.y, orient = Orient.NONE}
    elseif wall1.orient == Orient.X and wall2.orient == Orient.NEG_Y then
        return {x = wall1.x, y = wall2.y, orient = Orient.NONE, sub_orient = Orient.RIGHT}
    elseif wall1.orient == Orient.NEG_X and wall2.orient == Orient.Y then
        return {x = wall1.x, y = wall2.y, orient = Orient.NONE, sub_orient = Orient.LEFT}
    end
    assert(false)
end


return WallUpgradeBuilding











