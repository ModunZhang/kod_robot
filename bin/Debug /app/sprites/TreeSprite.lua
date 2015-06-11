local Enum = import("..utils.Enum")
local Sprite = import(".Sprite")
local TreeSprite = class("TreeSprite", Sprite)
function TreeSprite:ctor(city_layer, entity, x, y)
    TreeSprite.super.ctor(self, city_layer, entity, x, y)
end
function TreeSprite:ReloadSpriteCauseTerrainChanged()
    self.sprite:removeFromParent()
    self.sprite = self:CreateSprite():addTo(self, SPRITE)
end
function TreeSprite:CreateSprite()
    local tile = self:GetEntity()
    local x, y, city = tile.x, tile.y, tile.city
    local xb = city:GetTileByIndex(x - 1, y)
    local yb = city:GetTileByIndex(x, y - 1)
    local xbyn = city:GetTileByIndex(x - 1, y + 1)
    local xnyb = city:GetTileByIndex(x + 1, y - 1)
    local xyb = city:GetTileByIndex(x - 1, y - 1)
    local xn = city:GetTileByIndex(x + 1, y)
    local yn = city:GetTileByIndex(x, y + 1)
    local terrain = self:GetMapLayer():Terrain()
    local ppsprite
    local sprite
    local index = math.random(2)
    repeat
        if (xb and xb:NeedWalls()) or 
            (yb and yb:NeedWalls()) or 
            (xbyn and xbyn:NeedWalls()) or
            (xyb and xyb:NeedWalls()) then
            break
        end
        sprite = display.newSprite(string.format("trees_up_%d_%s.png", index, terrain))
        ppsprite = sprite
    until true
    repeat
        if (yb and yb:NeedWalls()) or 
            (xn and xn:NeedWalls()) or 
            (yn and yn:NeedWalls()) or 
            (xnyb and xnyb:NeedWalls()) then
            break
        end
        if sprite then
            sprite = display.newSprite(string.format("trees_right_%d_%s.png", index, terrain)):addTo(sprite):align(display.LEFT_BOTTOM)
        else
            sprite = display.newSprite(string.format("trees_right_%d_%s.png", index, terrain))
            ppsprite = sprite
        end
    until true
    repeat
        if (xb and xb:NeedWalls()) or 
            (xn and xn:NeedWalls()) or 
            (yn and yn:NeedWalls()) or 
            (xbyn and xbyn:NeedWalls()) then
            break
        end
        if sprite then
            sprite = display.newSprite(string.format("trees_left_%d_%s.png", index, terrain)):addTo(sprite):align(display.LEFT_BOTTOM)
        else
            sprite = display.newSprite(string.format("trees_left_%d_%s.png", index, terrain))
            ppsprite = sprite
        end
    until true
    repeat
        if (xn and xn:NeedWalls()) or 
            (yn and yn:NeedWalls()) then
            break
        end
        if sprite then
            sprite = display.newSprite(string.format("trees_down_%d_%s.png", index, terrain)):addTo(sprite):align(display.LEFT_BOTTOM)
        else
            sprite = display.newSprite(string.format("trees_down_%d_%s.png", index, terrain))
            ppsprite = sprite
        end
    until true
    if not ppsprite then
        ppsprite = display.newSprite("vip_1.png"):hide()
    end
    return ppsprite
end
function TreeSprite:GetSpriteOffset()
    return 0, 0
end
function TreeSprite:GetLogicZorder()
    local x, y = self:GetLogicPosition()
    return self:GetMapLayer():GetZOrderBy(self, x, y + 3)
end

return TreeSprite




















