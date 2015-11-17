local zz = import("..particles.zz")
local FunctionUpgradingSprite = import(".FunctionUpgradingSprite")
local AcademySprite = class("AcademySprite", FunctionUpgradingSprite)

function AcademySprite:OnUserDataChanged_productionTechEvents(userData, deltaDate)
    if deltaDate("productionTechEvents.remove") then
        app:GetAudioManager():PlayeEffectSoundWithKey("COMPLETE")
    end
end



local EMPTY_TAG = 11400
function AcademySprite:ctor(city_layer, entity, city)
    AcademySprite.super.ctor(self, city_layer, entity, city)
    city:GetUser():AddListenOnType(self, "productionTechEvents")
    scheduleAt(self, function() self:CheckEvent() end)
end
function AcademySprite:RefreshSprite()
    AcademySprite.super.RefreshSprite(self)
    self:CheckEvent()
end
function AcademySprite:CheckEvent()
    if self:GetEntity():IsUnlocked() then
        if self:GetEntity():BelongCity():GetUser():HasProductionTechEvent() then
            self:PlayWorkingAnimation()
        else
            self:StopAni()
            self:PlayEmptyAnimation()
        end
    end
end
function AcademySprite:PlayWorkingAnimation()
    if self:getChildByTag(EMPTY_TAG) then
        self:removeChildByTag(EMPTY_TAG)
        self:PlayAni()
    end
end
function AcademySprite:PlayEmptyAnimation()
    if not self:getChildByTag(EMPTY_TAG) then
        local x,y = self:GetSprite():getPosition()
        zz():addTo(self,1,EMPTY_TAG):pos(x + 50,y + 50)
    end
end
function AcademySprite:PlayAni()
    local animation = self:GetAniArray()[1]:show():getAnimation()
    animation:stop()
    animation:setSpeedScale(2)
    animation:playWithIndex(0)
end
function AcademySprite:StopAni()
    if self:GetAniArray()[1]:isVisible() then
        self:GetAniArray()[1]:hide():getAnimation():stop()
    end
end

return AcademySprite









