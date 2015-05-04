local FunctionUpgradingSprite = import(".FunctionUpgradingSprite")
local BarracksSprite = class("BarracksSprite", FunctionUpgradingSprite)

function BarracksSprite:OnBeginRecruit()
    self:DoAni()
end
function BarracksSprite:OnRecruiting()
end
function BarracksSprite:OnEndRecruit()
    self:DoAni()
    app:GetAudioManager():PlayeEffectSoundWithKey("COMPLETE")
end

function BarracksSprite:ctor(city_layer, entity, city)
    BarracksSprite.super.ctor(self, city_layer, entity, city)
    entity:AddBarracksListener(self)
    self:DoAni()
end
function BarracksSprite:RefreshSprite()
    BarracksSprite.super.RefreshSprite(self)
    self:DoAni()
end
function BarracksSprite:DoAni()
    if self:GetEntity():IsUnlocked() then
        if self:GetEntity():IsRecruting() then
            self:PlayAni()
        else
            self:StopAni()
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


return BarracksSprite








