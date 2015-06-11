local zz = import("..particles.zz")
local smoke = import("..particles.smoke")
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



local WORK_TAG = 11201
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
            self:PlayWorkAnimation()
            self:removeChildByTag(EMPTY_TAG)
        else
            self:PlayEmptyAnimation()
            self:removeChildByTag(WORK_TAG)
        end
    end
end


----
function ToolShopSprite:PlayWorkAnimation()
    if not self:getChildByTag(WORK_TAG) then
        local x,y = self:GetSprite():getPosition()
        smoke():addTo(self,1,WORK_TAG):pos(x + 40,y + 70)
    end
end
function ToolShopSprite:PlayEmptyAnimation()
    if not self:getChildByTag(EMPTY_TAG) then
        local x,y = self:GetSprite():getPosition()
        zz():addTo(self,1,EMPTY_TAG):pos(x + 50,y + 50)
    end
end


return ToolShopSprite









