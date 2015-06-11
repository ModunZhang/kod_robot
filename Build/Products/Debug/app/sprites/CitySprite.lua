local UILib = import("..ui.UILib")
local Sprite = import(".Sprite")
local fire = import("..particles.fire")
local smoke_city = import("..particles.smoke_city")
local SpriteConfig = import(".SpriteConfig")
local CitySprite = class("CitySprite", Sprite)


local timer = app.timer
function CitySprite:ctor(city_layer, entity, is_my_alliance)
    self:setNodeEventEnabled(true)
    self.is_my_alliance = is_my_alliance
    local x, y = city_layer:GetLogicMap():ConvertToMapPosition(entity:GetLogicPosition())
    CitySprite.super.ctor(self, city_layer, entity, x, y)

    self:CheckStatus()
end
function CitySprite:onExit()
    if self.info then
        self.info:removeFromParent()
    end
end
function CitySprite:GetSpriteFile()
    return self:GetConfig().png
end
function CitySprite:GetConfig()
    local config
    if self.is_my_alliance then
        config = SpriteConfig["my_keep"]
    else
        config = SpriteConfig["other_keep"]
    end
    return config:GetConfigByLevel(self:GetEntity():GetAllianceMemberInfo():KeepLevel())
end
function CitySprite:GetSpriteOffset()
    return self:GetLogicMap():ConvertToLocalPosition(0, 0)
end
function CitySprite:RefreshSprite()
    CitySprite.super.RefreshSprite(self)
    self.sprite:setAnchorPoint(self:GetConfig().offset.anchorPoint)


    if self.info then
        self.info:removeFromParent()
        self.info = nil
    end

    local lx,ly = self:GetEntity():GetLogicPosition()
    local map_layer = self:GetMapLayer()
    local logic_map = map_layer:GetLogicMap()
    local x,y = map_layer:GetLogicMap():ConvertToMapPosition(lx,ly)
    local w,h = logic_map:GetSize()
    self.info = display.newNode():addTo(map_layer:GetInfoNode()):pos(x, y - 50):scale(0.8):zorder(x * lx + ly)

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

local FIRE_TAG = 11900
local SMOKE_TAG = 12000
function CitySprite:RefreshInfo()
    local entity = self:GetEntity()
    local info = entity:GetAllianceMemberInfo()
    local banners = self.is_my_alliance and UILib.my_city_banner or UILib.enemy_city_banner
    self.banner:setTexture(banners[info:HelpedByTroopsCount()])
    self.level:setString(info:KeepLevel())
    self.name:setString(string.format("[%s]%s", entity:GetAlliance():Tag(), info:Name()))

    self:CheckStatus()
end
function CitySprite:CheckStatus()
    local memberInfo = self:GetEntity():GetAllianceMemberInfo()
    if memberInfo:IsProtected() then
        if self:getChildByTag(SMOKE_TAG) then
            self:removeChildByTag(SMOKE_TAG)
        end
        if not self:getChildByTag(FIRE_TAG) then
            local x,y = self:GetSpriteOffset()
            fire():addTo(self, 2, FIRE_TAG):pos(x + 20, y)
        end
    else
        if self:getChildByTag(FIRE_TAG) then
            self:removeChildByTag(FIRE_TAG)
        end

        local is_smoke = (timer:GetServerTime() - memberInfo:LastBeAttackedTime()) < 10 * 60
        if is_smoke then
            if not self:getChildByTag(SMOKE_TAG) then
                smoke_city():addTo(self, 2, SMOKE_TAG):pos(self:GetSpriteOffset())
            end
        else
            if self:getChildByTag(SMOKE_TAG) then
                self:removeChildByTag(SMOKE_TAG)
            end
        end
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




