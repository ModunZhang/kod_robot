local Sprite = import(".Sprite")
local UILib = import("..ui.UILib")
local AllianceDecoratorSprite = class("AllianceDecoratorSprite", Sprite)
local DECORATOR_IMAGE = UILib.decorator_image
local decorator_map = {
    grassLand = {
        decorate_lake_1 =  1,
        decorate_lake_2 =  1,
        decorate_mountain_1 =  1,
        decorate_mountain_2 =  1,
        decorate_tree_1 =  1,
        decorate_tree_2 =  1,
        decorate_tree_3 =  1,
        decorate_tree_4 =  1,
    },
    desert = {
        decorate_lake_1 =  1,
        decorate_lake_2 =  1,
        decorate_mountain_1 =  1,
        decorate_mountain_2 =  1,
        decorate_tree_1 =  1,
        decorate_tree_2 =  1,
        decorate_tree_3 =  1,
        decorate_tree_4 =  1,
    },
    iceField = {
        decorate_lake_1 =  1,
        decorate_lake_2 =  1,
        decorate_mountain_1 =  1,
        decorate_mountain_2 =  1,
        decorate_tree_1 =  1,
        decorate_tree_2 =  1,
        decorate_tree_3 =  1,
        decorate_tree_4 =  1,
    },
}

function AllianceDecoratorSprite:ctor(city_layer, entity)
    local x, y = city_layer:GetLogicMap():ConvertToMapPosition(entity:GetLogicPosition())
    AllianceDecoratorSprite.super.ctor(self, city_layer, entity, x, y)
    -- self:CreateBase()
end
function AllianceDecoratorSprite:GetSpriteFile()
    local terrain = self:GetMapLayer():Terrain()
    local deco_name = self:GetEntity():GetName()
    return DECORATOR_IMAGE[terrain][deco_name], decorator_map[terrain][deco_name]
end
function AllianceDecoratorSprite:GetSpriteOffset()
    local w, h = self:GetSize()
    return self:GetLogicMap():ConvertToLocalPosition((w - 1)/2, (h - 1)/2)
end
function AllianceDecoratorSprite:ReloadSpriteCauseTerrainChanged(terrain_type)
    self:RefreshSprite()
end



---- override
function AllianceDecoratorSprite:CreateBase()
    self:GenerateBaseTiles(self:GetEntity():GetSize())
end
function AllianceDecoratorSprite:newBatchNode(w, h)
    local start_x, end_x, start_y, end_y = self:GetLocalRegion(w, h)
    local base_node = display.newBatchNode("grass_80x80_.png", 10)
    local map = self:GetLogicMap()
    for ix = start_x, end_x do
        for iy = start_y, end_y do
            display.newSprite(base_node:getTexture()):addTo(base_node):pos(map:ConvertToLocalPosition(ix, iy)):scale(2)
        end
    end
    return base_node
end
return AllianceDecoratorSprite






