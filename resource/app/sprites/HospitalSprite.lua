local heal = import("..particles.heal")
local FunctionUpgradingSprite = import(".FunctionUpgradingSprite")
local HospitalSprite = class("HospitalSprite", FunctionUpgradingSprite)


function HospitalSprite:OnUserDataChanged_treatSoldierEvents()
    self:DoAni()
end

local WOUNDED_TAG = 114
function HospitalSprite:ctor(city_layer, entity, city)
    HospitalSprite.super.ctor(self, city_layer, entity, city)
    entity:BelongCity():GetUser():AddListenOnType(self, "treatSoldierEvents")
    scheduleAt(self, function() self:CheckEvent() end)
end
function HospitalSprite:RefreshSprite()
    HospitalSprite.super.RefreshSprite(self)
    self:DoAni()
end
function HospitalSprite:CheckEvent()
    if self:GetEntity():IsUnlocked() then
        if self:GetEntity():BelongCity():GetUser():HasAnyWoundedSoldiers() then
            self:PlayWoundedSoldiersAni()
        elseif self:getChildByTag(WOUNDED_TAG) then
            self:removeChildByTag(WOUNDED_TAG)
        end
    end
end
function HospitalSprite:DoAni()
    if self:GetEntity():IsUnlocked() then
        if #self:GetEntity():BelongCity():GetUser().treatSoldierEvents > 0 then
            self:PlayAni()
        else
            self:StopAni()
        end
    end
end
function HospitalSprite:PlayAni()
    local animation = self:GetAniArray()[1]:show():getAnimation()
    animation:stop()
    animation:setSpeedScale(2)
    animation:playWithIndex(0)
end
function HospitalSprite:StopAni()
    self:GetAniArray()[1]:hide():getAnimation():stop()
end
function HospitalSprite:PlayWoundedSoldiersAni()
    if not self:getChildByTag(WOUNDED_TAG) then
        local x,y = self:GetSprite():getPosition()
        local emitter = heal():addTo(self, 1, WOUNDED_TAG):pos(x-30,y-80)
        -- for i = 1, 500 do
        --     emitter:update(0.01)
        -- end
    end
end


return HospitalSprite













