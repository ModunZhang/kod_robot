local Sprite = import(".Sprite")
local RoadSprite = class("RoadSprite", Sprite)
function RoadSprite:ctor(city_layer, entity, x, y)
    RoadSprite.super.ctor(self, city_layer, entity, x, y)
end
function RoadSprite:ReloadSpriteCauseTerrainChanged()
    self.sprite:removeFromParent()
    self.sprite = self:CreateSprite():addTo(self, SPRITE):pos(self:GetSpriteOffset())
end
function RoadSprite:GetSpriteFile()
    return string.format("road_%s.png", self:GetMapLayer():Terrain())
end
function RoadSprite:GetSpriteOffset()
    return -400, -300
end
function RoadSprite:GetLogicZorder()
    local x, y = self:GetMidLogicPosition()
    return self:GetMapLayer():GetZOrderBy(self, x, y) - 10000
end


return RoadSprite
















