local zz = import("..particles.zz")
local FunctionUpgradingSprite = import(".FunctionUpgradingSprite")
local BarracksSprite = class("BarracksSprite", FunctionUpgradingSprite)

function BarracksSprite:OnUserDataChanged_soldierEvents(userData, deltaData)
    self:DoAni()
end



local EMPTY_TAG = 11400
function BarracksSprite:ctor(city_layer, entity, city)
    BarracksSprite.super.ctor(self, city_layer, entity, city)
    city:GetUser():AddListenOnType(self, "soldierEvents")
end
function BarracksSprite:RefreshSprite()
    BarracksSprite.super.RefreshSprite(self)
    self:DoAni()
end
function BarracksSprite:DoAni()
    if self:GetEntity():IsUnlocked() then
        if #self:GetEntity():BelongCity():GetUser().soldierEvents > 0 then
            self:PlayAni()
            self:removeChildByTag(EMPTY_TAG)
        else
            self:StopAni()
            self:PlayEmptyAnimation()
        end
    end
end
function BarracksSprite:PlayAni()
    local animation = self:GetAniArray()[1]:show():getAnimation()
    animation:stop()
    animation:setSpeedScale(2)
    animation:playWithIndex(0)
end
function BarracksSprite:StopAni()
    self:GetAniArray()[1]:hide():getAnimation():stop()
end
function BarracksSprite:PlayEmptyAnimation()
    if not self:getChildByTag(EMPTY_TAG) then
        local x,y = self:GetSprite():getPosition()
        zz():addTo(self,1,EMPTY_TAG):pos(x + 50,y + 50)
    end
end


return BarracksSprite








