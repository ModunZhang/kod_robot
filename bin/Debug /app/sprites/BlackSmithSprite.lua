local zz = import("..particles.zz")
local smoke = import("..particles.smoke")
local FunctionUpgradingSprite = import(".FunctionUpgradingSprite")
local BlackSmithSprite = class("BlackSmithSprite", FunctionUpgradingSprite)

function BlackSmithSprite:OnUserDataChanged_dragonEquipmentEvents()
    self:DoAni()
end


local WORK_TAG = 11201
local EMPTY_TAG = 11400
function BlackSmithSprite:ctor(city_layer, entity, city)
    BlackSmithSprite.super.ctor(self, city_layer, entity, city)
    city:GetUser():AddListenOnType(self, "dragonEquipmentEvents")
end
function BlackSmithSprite:RefreshSprite()
    BlackSmithSprite.super.RefreshSprite(self)
    self:DoAni()
end
function BlackSmithSprite:DoAni()
    if self:GetEntity():IsUnlocked() then
        if #self:GetEntity():BelongCity():GetUser().dragonEquipmentEvents > 0 then
            self:PlayWorkAnimation()
            self:removeChildByTag(EMPTY_TAG)
        else
            self:PlayEmptyAnimation()
            self:removeChildByTag(WORK_TAG)
        end
    end
end


function BlackSmithSprite:PlayWorkAnimation()
    if not self:getChildByTag(WORK_TAG) then
        local x,y = self:GetSprite():getPosition()
        smoke():addTo(self,1,WORK_TAG):pos(x - 50,y + 90)
    end
end
function BlackSmithSprite:PlayEmptyAnimation()
    if not self:getChildByTag(EMPTY_TAG) then
        local x,y = self:GetSprite():getPosition()
        zz():addTo(self,1,EMPTY_TAG):pos(x + 50,y + 50)
    end
end


return BlackSmithSprite









