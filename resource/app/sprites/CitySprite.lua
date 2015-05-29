local UILib = import("..ui.UILib")
local Sprite = import(".Sprite")
local fire = import("..particles.fire")
local SpriteConfig = import(".SpriteConfig")
local CitySprite = class("CitySprite", Sprite)
function CitySprite:ctor(city_layer, entity, is_my_alliance)
    self:setNodeEventEnabled(true)
    self.is_my_alliance = is_my_alliance
    local x, y = city_layer:GetLogicMap():ConvertToMapPosition(entity:GetLogicPosition())
    CitySprite.super.ctor(self, city_layer, entity, x, y)

    self:CheckProtected()
end
function CitySprite:onExit()
    if self.info then
        self.info:removeFromParent()
    end
end
function CitySprite:GetSpriteFile()
    local config
    if self.is_my_alliance then
        config = SpriteConfig["my_keep"]
    else
        config = SpriteConfig["other_keep"]
    end
    return config:GetConfigByLevel(self:GetEntity():GetAllianceMemberInfo():KeepLevel()).png
end
function CitySprite:GetSpriteOffset()
    return self:GetLogicMap():ConvertToLocalPosition(0, 0)
end
function CitySprite:RefreshSprite()
    CitySprite.super.RefreshSprite(self)
    if self.info then
        self.info:removeFromParent()
        self.info = nil
    end

    local map_layer = self:GetMapLayer()
    local lx,ly = self:GetEntity():GetLogicPosition()
    local x,y = map_layer:GetLogicMap():ConvertToMapPosition(lx,ly)
    self.info = display.newNode():addTo(map_layer:GetInfoNode()):pos(x, y - 50):scale(0.8):zorder(x * y)

    self.banner = display.newSprite("city_banner.png"):addTo(self.info):align(display.CENTER_TOP)
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

local FIRE_TAG = 119
function CitySprite:RefreshInfo()
    local entity = self:GetEntity()
    local info = entity:GetAllianceMemberInfo()
    local banners = self.is_my_alliance and UILib.my_city_banner or UILib.enemy_city_banner
    self.banner:setTexture(banners[info:HelpedByTroopsCount()])
    self.level:setString(info:KeepLevel())
    self.name:setString(string.format("[%s]%s", entity:GetAlliance():Tag(), info:Name()))


    self:CheckProtected()
end
function CitySprite:CheckProtected()
    local is_protected = self:GetEntity():GetAllianceMemberInfo():IsProtected()
    if is_protected then
        if not self:getChildByTag(FIRE_TAG) then
            fire():addTo(self, 2, FIRE_TAG):pos(0, -50)
        end
    else
        self:removeChildByTag(FIRE_TAG)
    end
end




---
function CitySprite:CreateBase()
    self:GenerateBaseTiles(1, 1)
end
function CitySprite:newBatchNode(w, h)
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
return CitySprite




