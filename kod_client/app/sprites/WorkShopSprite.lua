local smoke = import("..particles.smoke")
local FunctionUpgradingSprite = import(".FunctionUpgradingSprite")
local WorkShopSprite = class("WorkShopSprite", FunctionUpgradingSprite)

function WorkShopSprite:OnUserDataChanged_soldierStarEvents()
    self:DoAni()
end
function WorkShopSprite:OnUserDataChanged_militaryTechEvents()
    self:DoAni()
end



local WORK_TAG = 11201
function WorkShopSprite:ctor(city_layer, entity, city)
    WorkShopSprite.super.ctor(self, city_layer, entity, city)
    local User = city:GetUser()
    User:AddListenOnType(self, "soldierStarEvents")
    User:AddListenOnType(self, "militaryTechEvents")
end
function WorkShopSprite:RefreshSprite()
    WorkShopSprite.super.RefreshSprite(self)
    self:DoAni()
end
function WorkShopSprite:DoAni()
    if self:GetEntity():IsUnlocked() then
        if self:GetEntity():BelongCity():GetUser():HasMilitaryTechEventBy("workshop") then
            self:PlayWorkAnimation()
        else
            self:removeChildByTag(WORK_TAG)
        end
    end
end
function WorkShopSprite:PlayWorkAnimation()
    if not self:getChildByTag(WORK_TAG) then
        local x,y = self:GetSprite():getPosition()
        smoke():addTo(self,1,WORK_TAG):pos(x - 65,y + 80)
    end
end



return WorkShopSprite










