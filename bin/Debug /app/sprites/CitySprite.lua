local UILib = import("..ui.UILib")
local fire = import("..particles.fire")
local smoke_city = import("..particles.smoke_city")
local SpriteConfig = import(".SpriteConfig")
local WithInfoSprite = import(".WithInfoSprite")
local CitySprite = class("CitySprite", WithInfoSprite)


local timer = app.timer
function CitySprite:ctor(city_layer, entity, is_my_alliance)
    CitySprite.super.ctor(self, city_layer, entity, is_my_alliance)
    self:CheckStatus()
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
local FIRE_TAG = 11900
local SMOKE_TAG = 12000
function CitySprite:RefreshInfo()
    CitySprite.super.RefreshInfo(self)
    self:GetSprite():setAnchorPoint(self:GetConfig().offset.anchorPoint)

    self:CheckStatus()
end
function CitySprite:GetInfo()
    local entity = self:GetEntity()
    local info = entity:GetAllianceMemberInfo()
    local banners = self.is_my_alliance and UILib.my_city_banner or UILib.enemy_city_banner
    return info:KeepLevel(), string.format("[%s]%s", entity:GetAlliance():Tag(), info:Name()), banners[info:HelpedByTroopsCount()]
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




