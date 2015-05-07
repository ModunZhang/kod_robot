local Sprite = import(".Sprite")
local SingleTreeSprite = class("SingleTreeSprite", Sprite)

function SingleTreeSprite:ctor(city_layer, x, y)
    self.png_index = math.random(2)
    self.x, self.y = x, y
    local ax, ay = city_layer:GetLogicMap():ConvertToMapPosition(x, y)
    SingleTreeSprite.super.ctor(self, city_layer, nil, ax, ay)
    self:GetSprite():align(display.BOTTOM_CENTER)
    -- self:CreateBase()
end
function SingleTreeSprite:ReloadSpriteCauseTerrainChanged()
	self.sprite:removeFromParent()
    self.sprite = self:CreateSprite():addTo(self, SPRITE):align(display.BOTTOM_CENTER)
end
function SingleTreeSprite:GetSpriteFile()
    return string.format("single_tree_%d_%s.png", self.png_index, self:GetMapLayer():Terrain()), 0.8
end
function SingleTreeSprite:GetSpriteOffset()
    return 10, -15
end
function SingleTreeSprite:GetMidLogicPosition()
    return self.x, self.y
end
function SingleTreeSprite:CreateBase()
    self:GenerateBaseTiles(1, 1)
end

return SingleTreeSprite


















