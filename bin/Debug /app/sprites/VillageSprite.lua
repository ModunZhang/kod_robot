local Localize = import("..utils.Localize")
local SpriteConfig = import(".SpriteConfig")
local WithInfoSprite = import(".WithInfoSprite")
local VillageSprite = class("VillageSprite", WithInfoSprite)

function VillageSprite:ctor(city_layer, entity, is_my_alliance)
    VillageSprite.super.ctor(self, city_layer, entity, is_my_alliance)
end
function VillageSprite:GetSpriteFile()
    local village_info = self:GetEntity():GetAllianceVillageInfo()
    local config = SpriteConfig[village_info.name]:GetConfigByLevel(village_info.level)
	return config.png, config.scale
end
function VillageSprite:GetSpriteOffset()
	return self:GetLogicMap():ConvertToLocalPosition(0, 0)
end
function VillageSprite:GetInfo()
    return self:GetEntity():GetAllianceVillageInfo().level, Localize.village_name[self:GetEntity():GetName()]
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