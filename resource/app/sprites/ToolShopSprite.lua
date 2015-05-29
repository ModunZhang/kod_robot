local zz = import("..particles.zz")
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




local EMPTY_TAG = 11400
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
            self:removeChildByTag(EMPTY_TAG)
        else
            self:StopAni()
            self:PlayEmptyAnimation()
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


function ToolShopSprite:PlayEmptyAnimation()
    if not self:getChildByTag(EMPTY_TAG) then
        local x,y = self:GetSprite():getPosition()
        zz():addTo(self,1,EMPTY_TAG):pos(x + 50,y + 50)
    end
end


return ToolShopSprite









