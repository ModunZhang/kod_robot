local zz = import("..particles.zz")
local smoke = import("..particles.smoke")
local FunctionUpgradingSprite = import(".FunctionUpgradingSprite")
local ToolShopSprite = class("ToolShopSprite", FunctionUpgradingSprite)


function ToolShopSprite:OnUserDataChanged_materialEvents()
    self:DoAni() 
end

local WORK_TAG = 11201
local TIP_TAG = 11202
local EMPTY_TAG = 11400
function ToolShopSprite:ctor(city_layer, entity, city)
    ToolShopSprite.super.ctor(self, city_layer, entity, city)
    city:GetUser():AddListenOnType(self, "materialEvents")
end
function ToolShopSprite:RefreshSprite()
    ToolShopSprite.super.RefreshSprite(self)
    self:DoAni()
end
function ToolShopSprite:DoAni()
    if self:GetEntity():IsUnlocked() then
        if self:GetEntity():BelongCity():GetUser():IsMakingMaterials() then
            self:PlayWorkAnimation()
            self:removeChildByTag(EMPTY_TAG)
        else
            self:PlayEmptyAnimation()
            self:removeChildByTag(WORK_TAG)
        end
        if self:GetEntity():BelongCity():GetUser():IsStoreMaterials() then
            if not self:getChildByTag(TIP_TAG) then
                local x,y = self:GetSpriteTopPosition()
                x = x - 30
                y = y - 40
                display.newSprite("tmp_tips_56x60.png")
                :addTo(self,1,TIP_TAG):align(display.BOTTOM_CENTER,x,y)
                :runAction(UIKit:ShakeAction(true, 2))
            end
        else
            self:removeChildByTag(TIP_TAG)
        end
    end
end


----
function ToolShopSprite:PlayWorkAnimation()
    if not self:getChildByTag(WORK_TAG) then
        local x,y = self:GetSprite():getPosition()
        smoke():addTo(self,1,WORK_TAG):pos(x + 40,y + 70)
    end
end
function ToolShopSprite:PlayEmptyAnimation()
    if not self:getChildByTag(EMPTY_TAG) then
        local x,y = self:GetSprite():getPosition()
        zz():addTo(self,1,EMPTY_TAG):pos(x + 50,y + 50)
    end
end


return ToolShopSprite









