local Sprite = import(".Sprite")
local TileSprite = class("TileSprite", Sprite)
local random = math.random


local surface = {
    grassLand = {
        "unlock_tile_surface_1_grassLand.png",
        "unlock_tile_surface_2_grassLand.png",
        "unlock_tile_surface_3_grassLand.png",
        "unlock_tile_surface_4_grassLand.png",
        "unlock_tile_surface_5_grassLand.png",
        "unlock_tile_surface_6_grassLand.png",
    },
    desert = {
        "unlock_tile_surface_1_desert.png",
        "unlock_tile_surface_2_desert.png",
        "unlock_tile_surface_3_desert.png",
        "unlock_tile_surface_4_desert.png",
    },
    iceField = {
        "unlock_tile_surface_1_iceField.png",
        "unlock_tile_surface_2_iceField.png",
        "unlock_tile_surface_3_iceField.png",
        "unlock_tile_surface_4_iceField.png",
        "unlock_tile_surface_5_iceField.png",
        "unlock_tile_surface_6_iceField.png",
        "unlock_tile_surface_7_iceField.png",
    },
}

function TileSprite:ctor(city_layer, entity, x, y)
    self.roads = {}
    TileSprite.super.ctor(self, city_layer, entity, x, y)
end
function TileSprite:ReloadSpriteCauseTerrainChanged()
    self.sprite:removeFromParent()
    self.sprite = self:CreateSprite():addTo(self, SPRITE)
end
function TileSprite:CreateSprite()
    for k,v in pairs(self.roads) do
        v:removeFromParent()
    end
    self.roads = {}
    
    local sprite = TileSprite.super.CreateSprite(self)
    local tile = self:GetEntity()
    local x, y = tile.x, tile.y
    if x == 2 then
        local dx, dy = 510/2, 310/2
        sprite:setTexture(self:GetUnlockTilePng())
        display.newSprite(self:GetRoadPng()):addTo(sprite):pos(dx, dy)
        if y == 5 and x == 2 then
            for i = 1, 2 do
                table.insert(self.roads, 
                    display.newSprite(string.format("unlock_road_%s.png",
                    self:GetMapLayer():Terrain())):addTo(self):pos(-dx * i, -dy * i))
            end
        end
    else
        local sx,ex,sy,ey = 200,230,150,200
        local maps = surface[self:GetMapLayer():Terrain()]
        for i = 1,2 do
            display.newSprite(maps[math.random(#maps)]):addTo(sprite)
                :pos(sx + math.random(ex - sx), sy + math.random(ey - sy))
        end
    end
    if self:GetEntity():NeedWalls() then
        sprite:hide()
    end
    return sprite
end
function TileSprite:GetSpriteFile()
    return self:GetUnlockTilePng()
end
function TileSprite:GetUnlockTilePng()
    return string.format("unlock_tile_1_%s.png", self:GetMapLayer():Terrain())
end
function TileSprite:GetRoadPng()
    return string.format("unlock_road_%s.png", self:GetMapLayer():Terrain())
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





















