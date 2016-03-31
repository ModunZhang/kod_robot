local Orient = import("..entity.Orient")
local UpgradingSprite = import(".UpgradingSprite")
local WallUpgradingSprite = class("WallUpgradingSprite", UpgradingSprite)

local offset_map = {
    [1] = {
        [Orient.X] = {15, 49},
        [Orient.Y] = {-16, 49},
        [Orient.NEG_X] = {15, 49},
        [Orient.NEG_Y] = {-16, 49},
        gate = {-62, 74}
    },
    [2] = {
        [Orient.X] = {15, 49},
        [Orient.Y] = {-16, 49},
        [Orient.NEG_X] = {15, 49},
        [Orient.NEG_Y] = {-16, 49},
        gate = {-63, 73}
    },
    [3] = {
        [Orient.X] = {12, 48},
        [Orient.Y] = {-10, 49},
        [Orient.NEG_X] = {15, 49},
        [Orient.NEG_Y] = {-16, 49},
        gate = {-36, 66}
    },
}
----
function WallUpgradingSprite:ctor(city_layer, entity, level)
    self.level = level
    WallUpgradingSprite.super.ctor(self, city_layer, entity)

    if entity:IsGate() then
        UIKit:CreateSoldierIdle45Ani("sentinel_3", 3):addTo(self):scale(0.7):pos(-170 + 10, 0 + 10)
        UIKit:CreateSoldierIdle45Ani("sentinel_3", 3):addTo(self):scale(0.7):pos(-80 + 10, -50 + 10)
    end
end
function WallUpgradingSprite:GetSpriteFile()
    local entity = self:GetEntity()
    if entity:GetOrient() == Orient.X then
        return string.format("wall_x_%d.png", self.level)
    elseif entity:GetOrient() == Orient.Y then
        return entity:IsGate() and string.format("gate_%d.png", self.level) or string.format("wall_y_%d.png", self.level)
    elseif entity:GetOrient() == Orient.NEG_X then
        return string.format("wall_x_%d.png", self.level)
    elseif entity:GetOrient() == Orient.NEG_Y then
        return string.format("wall_y_%d.png", self.level)
    end
    assert(false)
end
function WallUpgradingSprite:GetSpriteOffset()
    local entity = self:GetEntity()
    local offset = offset_map[self.level]
    if entity:IsGate() then
        return unpack(offset.gate)
    else
        return unpack(offset[entity:GetOrient()])
    end
end
function WallUpgradingSprite:GetFlipX()
    local entity = self:GetEntity()
    if entity:GetOrient() == Orient.X then
        return false
    elseif entity:GetOrient() == Orient.Y then
        -- return entity:IsGate()
        return false
    elseif entity:GetOrient() == Orient.NEG_X then
        return false
    elseif entity:GetOrient() == Orient.NEG_Y then
        return false
    end
    assert(false)
end
function WallUpgradingSprite:GetSpriteTopPosition()
    local x,y = WallUpgradingSprite.super.GetSpriteTopPosition(self)
    return x, y - 30
end
return WallUpgradingSprite





















