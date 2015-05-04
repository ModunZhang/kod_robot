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

function HospitalSprite:ctor(city_layer, entity, city)
    HospitalSprite.super.ctor(self, city_layer, entity, city)
    entity:AddHospitalListener(self)
    self:DoAni()
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


return HospitalSprite









