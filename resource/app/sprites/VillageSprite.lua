--
-- Author: Danny He
-- Date: 2014-11-28 08:56:14
--
local Sprite = import(".Sprite")
local VillageSprite = class("VillageSprite", Sprite)
local Localize = import("..utils.Localize")
local UILib = import("..ui.UILib")
local SpriteConfig = import(".SpriteConfig")

function VillageSprite:ctor(city_layer, entity, is_my_alliance)
    self:setNodeEventEnabled(true)
    self.is_my_alliance = is_my_alliance
    local x, y = city_layer:GetLogicMap():ConvertToMapPosition(entity:GetLogicPosition())
    VillageSprite.super.ctor(self, city_layer, entity, x, y)
    -- self:CreateBase()
end
function VillageSprite:onExit()
    if self.info then
        self.info:removeFromParent()
    end
end
function VillageSprite:GetSpriteFile()
    local village_info = self:VillageInfo()
    if not village_info  then
        local village_name = self:GetEntity():GetName()
        if village_name == 'woodVillage' then
            local decorate_tree = UILib.decorator_image[self:GetMapLayer():Terrain()].decorate_tree_1
            return decorate_tree
        elseif village_name == 'ironVillage' then
            return "iron_ruins_276x200.png",120/276
        elseif village_name == 'stoneVillage' then
            local stone_mountain = UILib.decorator_image[self:GetMapLayer():Terrain()].stone_mountain
            return stone_mountain
        elseif village_name == 'foodVillage' then
            local farmland = UILib.decorator_image[self:GetMapLayer():Terrain()].farmland
            return farmland
        end
    else
        local build_png = SpriteConfig[village_info.name]:GetConfigByLevel(village_info.level).png
	    return build_png
    end
end
function VillageSprite:GetSpriteOffset()
	return self:GetLogicMap():ConvertToLocalPosition(0, 0)
end
function VillageSprite:VillageInfo()
    return self:GetEntity():GetAllianceVillageInfo() 
end
function VillageSprite:RefreshSprite()
    VillageSprite.super.RefreshSprite(self)
    if self.info then
        self.info:removeFromParent()
        self.info = nil
    end

    local map_layer = self:GetMapLayer()
    local x,y = map_layer:GetLogicMap():ConvertToMapPosition(self:GetEntity():GetLogicPosition())
    self.info = display.newNode():addTo(map_layer:GetInfoNode()):pos(x, y - 50):scale(0.8):zorder(x * y)

    local banners = self.is_my_alliance and UILib.my_city_banner or UILib.enemy_city_banner
    self.banner = display.newSprite(banners[0]):addTo(self.info):align(display.CENTER_TOP)
    self.level = UIKit:ttfLabel({
        size = 22,
        color = 0xffedae,
    }):addTo(self.banner):align(display.CENTER, 30, 30)
    self.name = UIKit:ttfLabel({
        size = 20,
        color = 0xffedae,
    }):addTo(self.banner):align(display.LEFT_CENTER, 60, 32)
    self:RefreshInfo()
end
function VillageSprite:RefreshInfo()
    local info = self:VillageInfo()
    -- self.level:setString(info.level)
    -- self.name:setString(Localize.village_name[self:GetEntity():GetName()])
end


---
function VillageSprite:CreateBase()
    self:GenerateBaseTiles(1, 1)
end
function VillageSprite:newBatchNode(w, h)
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
return VillageSprite