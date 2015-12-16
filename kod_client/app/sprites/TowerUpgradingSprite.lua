local Orient = import("..entity.Orient")
local UpgradingSprite = import(".UpgradingSprite")
local TowerUpgradingSprite = class("TowerUpgradingSprite", UpgradingSprite)
local HEAD_SPRITE = 2


local offset_map = {
    [1] = {
        [Orient.X] = {15, 75},
        [Orient.Y] = {-16, 74},
        [Orient.NEG_X] = {83, 83},
        [Orient.NEG_Y] = {-82, 83},
        [Orient.DOWN] = {0, 71},
        [Orient.RIGHT] = {-10, 66},
        [Orient.LEFT] = {17, 64},
        [Orient.UP] = {0, -7},
        [Orient.NONE] = {0, 71},
        right_end = {-9, 36},
        left_end = {-74, 91}
    },
    [2] = {
        [Orient.X] = {16, 75},
        [Orient.Y] = {-14, 74},
        [Orient.NEG_X] = {83, 83},
        [Orient.NEG_Y] = {-82, 83},
        [Orient.DOWN] = {0, 71},
        [Orient.RIGHT] = {-10, 63},
        [Orient.LEFT] = {18, 62},
        [Orient.UP] = {0, -7},
        [Orient.NONE] = {0, 71},
        right_end = {-17, 31},
        left_end = {-54, 80}
    },
    [3] = {
        [Orient.X] = {14, 75},
        [Orient.Y] = {-10, 73},
        [Orient.NEG_X] = {83, 83},
        [Orient.NEG_Y] = {-82, 83},
        [Orient.DOWN] = {0, 73},
        [Orient.RIGHT] = {-16, 62},
        [Orient.LEFT] = {19, 62},
        [Orient.UP] = {0, -7},
        [Orient.NONE] = {-2, 63},
        right_end = {-3, 25},
        left_end = {-57, 70}
    },
}
---- 功能
function TowerUpgradingSprite:ctor(city_layer, entity, level)
    self.level = level
    TowerUpgradingSprite.super.ctor(self, city_layer, entity)
end
function TowerUpgradingSprite:GetSpriteFile()
    local entity = self:GetEntity()
    if entity:GetOrient() == Orient.X then
        return string.format("tower_x_%d.png", self.level)
    elseif entity:GetOrient() == Orient.Y then
        return string.format("tower_y_%d.png", self.level)
    elseif entity:GetOrient() == Orient.NEG_X then
        assert(false)
    elseif entity:GetOrient() == Orient.NEG_Y then
        assert(false)
    elseif entity:GetOrient() == Orient.RIGHT then
        local x, y = entity:GetLogicPosition()
        if y < 0 then
            return string.format("tower_right_x_%d.png", self.level)
        end
        return string.format("tower_right_%d.png", self.level)
    elseif entity:GetOrient() == Orient.DOWN then
        return string.format("tower_down_%d.png", self.level)
    elseif entity:GetOrient() == Orient.LEFT then
        local x, y = entity:GetLogicPosition()
        if x < 0 then
            return string.format("tower_left_y_%d.png", self.level)
        end
        return string.format("tower_left_%d.png", self.level)
    elseif entity:GetOrient() == Orient.UP then
        return string.format("tower_up_%d.png", self.level)
    elseif entity:GetOrient() == Orient.NONE then
        return string.format("tower_none_%d.png", self.level)
    end
    assert(false)
end
function TowerUpgradingSprite:GetSpriteOffset()
    local entity = self:GetEntity()
    local offset = offset_map[self.level]
    local x,y = entity:GetLogicPosition()
    if entity:GetOrient() == Orient.RIGHT and y < 0 then
        return unpack(offset.right_end)
    elseif entity:GetOrient() == Orient.LEFT and x < 0 then
        return unpack(offset.left_end)
    end 
    return unpack(offset[entity:GetOrient()])
end
function TowerUpgradingSprite:GetFlipX()
    local entity = self:GetEntity()
    if entity:GetOrient() == Orient.X then
        return false
    elseif entity:GetOrient() == Orient.Y then
        return false
    elseif entity:GetOrient() == Orient.NEG_X then
        return false
    elseif entity:GetOrient() == Orient.NEG_Y then
        return false
    elseif entity:GetOrient() == Orient.RIGHT then
        return false
    elseif entity:GetOrient() == Orient.DOWN then
        return false
    elseif entity:GetOrient() == Orient.LEFT then
        return false
    elseif entity:GetOrient() == Orient.UP then
        return false
    elseif entity:GetOrient() == Orient.NONE then
        if entity:GetSubOrient() == Orient.LEFT then
            return true
        elseif entity:GetSubOrient() == Orient.RIGHT then
            return false
        end
        return false
    end
    assert(false)
end
function TowerUpgradingSprite:GetLogicZorder()
    local entity = self:GetEntity()
    local x, y
    if entity:GetOrient() == Orient.X then
        x, y = self:GetMidLogicPosition()
    elseif entity:GetOrient() == Orient.Y then
        x, y = self:GetMidLogicPosition()
    elseif entity:GetOrient() == Orient.NEG_X then
        x, y = self:GetMidLogicPosition()
    elseif entity:GetOrient() == Orient.NEG_Y then
        x, y = self:GetMidLogicPosition()
    elseif entity:GetOrient() == Orient.RIGHT then
        x, y = self:GetLogicPosition()
    elseif entity:GetOrient() == Orient.DOWN then
        x, y = self:GetLogicPosition()
    elseif entity:GetOrient() == Orient.LEFT then
        x, y = self:GetLogicPosition()
    elseif entity:GetOrient() == Orient.UP then
        x, y = self:GetLogicPosition()
    elseif entity:GetOrient() == Orient.NONE then
        x, y = self:GetMidLogicPosition()
    end
    return self:GetMapLayer():GetZOrderBy(self, x, y)
end
function TowerUpgradingSprite:GetSpriteTopPosition()
    local x,y = TowerUpgradingSprite.super.GetSpriteTopPosition(self)
    return x - 5, y - 30
end
return TowerUpgradingSprite























