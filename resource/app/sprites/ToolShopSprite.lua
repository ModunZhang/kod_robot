local FunctionUpgradingSprite = import(".FunctionUpgradingSprite")
local ToolShopSprite = class("ToolShopSprite", FunctionUpgradingSprite)


function ToolShopSprite:OnBeginMakeMaterialsWithEvent()
    self:DoAni()
end
function ToolShopSprite:OnMakingMaterialsWithEvent()
end
function ToolShopSprite:OnEndMakeMaterialsWithEvent()
    self:DoAni()
    app:GetAudioManager():PlayeEffectSoundWithKey("COMPLETE")
end
function ToolShopSprite:OnGetMaterialsWithEvent()
end

function ToolShopSprite:ctor(city_layer, entity, city)
    ToolShopSprite.super.ctor(self, city_layer, entity, city)
    entity:AddToolShopListener(self)
    self:DoAni()
end
function ToolShopSprite:RefreshSprite()
    ToolShopSprite.super.RefreshSprite(self)
    self:DoAni()
end
function ToolShopSprite:DoAni()
    if self:GetEntity():IsUnlocked() then
        if self:GetEntity():IsMakingAny(app.timer:GetServerTime()) then
            self:PlayAni()
        else
            self:StopAni()
        end
    end
end
function ToolShopSprite:PlayAni()
    for _,v in pairs(self:GetAniArray()) do
        local animation = v:show():getAnimation()
        animation:setSpeedScale(2)
        animation:playWithIndex(0)
    end
end
function ToolShopSprite:StopAni()
    for _,v in pairs(self:GetAniArray()) do
        v:hide():getAnimation():stop()
    end
end


return ToolShopSprite









