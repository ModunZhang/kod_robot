local FunctionUpgradingSprite = import(".FunctionUpgradingSprite")
local AcademySprite = class("AcademySprite", FunctionUpgradingSprite)

function AcademySprite:OnProductionTechnologyEventDataChanged(changed_map)
    self:DoAni()
    changed_map = changed_map or {}
    if next(changed_map.remove or {}) then
        app:GetAudioManager():PlayeEffectSoundWithKey("COMPLETE")
    end
end
function AcademySprite:ctor(city_layer, entity, city)
    AcademySprite.super.ctor(self, city_layer, entity, city)
    city:AddListenOnType(self, city.LISTEN_TYPE.PRODUCTION_EVENT_CHANGED)
    self:DoAni()
end
function AcademySprite:RefreshSprite()
    AcademySprite.super.RefreshSprite(self)
    self:DoAni()
end
function AcademySprite:DoAni()
    if self:GetEntity():IsUnlocked() then
        if self:GetEntity():BelongCity():HaveProductionTechEvent() then
            self:PlayAni()
        else
            self:StopAni()
        end
    end
end
function AcademySprite:PlayAni()
    local animation = self:GetAniArray()[1]:show():getAnimation()
    animation:stop()
    animation:setSpeedScale(2)
    animation:playWithIndex(0)
end
function AcademySprite:StopAni()
    self:GetAniArray()[1]:hide():getAnimation():stop()
end


return AcademySprite








