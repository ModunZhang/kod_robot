local heal = import("..particles.heal")
local FunctionUpgradingSprite = import(".FunctionUpgradingSprite")
local HospitalSprite = class("HospitalSprite", FunctionUpgradingSprite)

function HospitalSprite:OnBeginTreat()
    self:DoAni()
end
function HospitalSprite:OnTreating()
end
function HospitalSprite:OnEndTreat()
    self:DoAni()
end

local WOUNDED_TAG = 114
function HospitalSprite:ctor(city_layer, entity, city)
    HospitalSprite.super.ctor(self, city_layer, entity, city)
    entity:AddHospitalListener(self)
    display.newNode():addTo(self):schedule(function()
        if self:GetEntity():IsUnlocked() then
            if self:GetEntity():BelongCity():GetSoldierManager():HasAnyWoundedSoldiers() then
                self:PlayWoundedSoldiersAni()
            elseif self:getChildByTag(WOUNDED_TAG) then
                self:removeChildByTag(WOUNDED_TAG)
            end
        end
    end, 1)
end
function HospitalSprite:RefreshSprite()
    HospitalSprite.super.RefreshSprite(self)
    self:DoAni()
end
function HospitalSprite:DoAni()
    if self:GetEntity():IsUnlocked() then
        if self:GetEntity():IsTreating() then
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
        heal():addTo(self, 1, WOUNDED_TAG):pos(x-30,y-80)
    end
end


return HospitalSprite











