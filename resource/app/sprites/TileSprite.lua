local Sprite = import(".Sprite")
local TileSprite = class("TileSprite", Sprite)
local random = math.random


local surface = {
    "unlock_tile_surface_1_grassLand.png",
    "unlock_tile_surface_2_grassLand.png",
    "unlock_tile_surface_3_grassLand.png",
    "unlock_tile_surface_4_grassLand.png",
    "unlock_tile_surface_5_grassLand.png",
    "unlock_tile_surface_6_grassLand.png",
}

function TileSprite:ctor(city_layer, entity, x, y)
    TileSprite.super.ctor(self, city_layer, entity, x, y)
    if entity:NeedWalls() then
        self:GetSprite():hide()
    end
    local sx, sy = 200, 100
    for i = 1,2 do
        display.newSprite(surface[math.random(#surface)]):addTo(self:GetSprite())
        :pos(sx + math.random(510 - sx), sy + math.random(310 - sy))
    end
end
function TileSprite:ReloadSpriteCauseTerrainChanged()
    self.sprite:removeFromParent()
    self.sprite = self:CreateSprite():addTo(self, SPRITE)
end
function TileSprite:CreateSprite()
    local sprite = TileSprite.super.CreateSprite(self)
    local tile = self:GetEntity()
    local x, y, city = tile.x, tile.y, tile.city
    if y == 5 and x == 2 then
        local dx, dy = 510/2, 310/2
        for i = 1, 2 do
            display.newSprite(string.format("unlock_road_%s.png", 
            self:GetMapLayer():Terrain())):addTo(self):pos(-dx * i, -dy * i)
        end
    end
    return sprite
end
function TileSprite:GetSpriteFile()
    local tile = self:GetEntity()
    local x, y, city = tile.x, tile.y, tile.city
    if x == 2 then
        return string.format("unlock_road_%s.png", self:GetMapLayer():Terrain())
    end
    return string.format("unlock_tile_1_%s.png", self:GetMapLayer():Terrain())
end
-- function TileSprite:GetSpriteOffset()
--     local tile = self:GetEntity()
--     local x, y, city = tile.x, tile.y, tile.city
--     -- 路的地块
--     if x == 2 then
--         return 0, 0
--     end
--     return -120, -30
-- end
function TileSprite:GetLogicZorder()
    return - 1
end
return TileSprite



















