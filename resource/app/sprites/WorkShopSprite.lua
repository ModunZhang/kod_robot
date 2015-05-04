local FunctionUpgradingSprite = import(".FunctionUpgradingSprite")
local WorkShopSprite = class("WorkShopSprite", FunctionUpgradingSprite)

function WorkShopSprite:OnMilitaryTechEventsChanged()
    self:DoAni()
end
function WorkShopSprite:OnSoldierStarEventsChanged()
    self:DoAni()
end
function WorkShopSprite:ctor(city_layer, entity, city)
    WorkShopSprite.super.ctor(self, city_layer, entity, city)
    city:GetSoldierManager():AddListenOnType(self, city:GetSoldierManager().LISTEN_TYPE.SOLDIER_STAR_EVENTS_CHANGED)
    city:GetSoldierManager():AddListenOnType(self, city:GetSoldierManager().LISTEN_TYPE.MILITARY_TECHS_EVENTS_CHANGED)
    self:DoAni()
end
function WorkShopSprite:RefreshSprite()
    WorkShopSprite.super.RefreshSprite(self)
    self:DoAni()
end
function WorkShopSprite:DoAni()
    if self:GetEntity():IsUnlocked() then
        if self:GetEntity():BelongCity():GetSoldierManager():IsUpgradingMilitaryTech("workshop") then
            self:PlayAni()
        else
            self:StopAni()
        end
    end
end
function WorkShopSprite:PlayAni()
    local animation = self:GetAniArray()[1]:show():getAnimation()
    animation:stop()
    animation:setSpeedScale(2)
    animation:playWithIndex(0)
end
function WorkShopSprite:StopAni()
    self:GetAniArray()[1]:hide():getAnimation():stop()
end


return WorkShopSprite










