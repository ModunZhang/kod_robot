local FunctionUpgradingSprite = import(".FunctionUpgradingSprite")
local BlackSmithSprite = class("BlackSmithSprite", FunctionUpgradingSprite)

function BlackSmithSprite:OnBeginMakeEquipmentWithEvent()
    self:DoAni()
end
function BlackSmithSprite:OnMakingEquipmentWithEvent()
end
function BlackSmithSprite:OnEndMakeEquipmentWithEvent()
    self:DoAni()
    app:GetAudioManager():PlayeEffectSoundWithKey("COMPLETE")
end

function BlackSmithSprite:ctor(city_layer, entity, city)
    BlackSmithSprite.super.ctor(self, city_layer, entity, city)
    entity:AddBlackSmithListener(self)
    self:DoAni()
end
function BlackSmithSprite:RefreshSprite()
    BlackSmithSprite.super.RefreshSprite(self)
    self:DoAni()
end
function BlackSmithSprite:DoAni()
    if self:GetEntity():IsUnlocked() then
        if self:GetEntity():IsMakingEquipment() then
            self:PlayAni()
        else
            self:StopAni()
        end
    end
end
function BlackSmithSprite:PlayAni()
    for _,v in pairs(self:GetAniArray()) do
        local animation = v:show():getAnimation()
        animation:setSpeedScale(2)
        animation:playWithIndex(0)
    end
end
function BlackSmithSprite:StopAni()
    for _,v in pairs(self:GetAniArray()) do
        v:hide():getAnimation():stop()
    end
end


return BlackSmithSprite









