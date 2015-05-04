local FunctionUpgradingSprite = import(".FunctionUpgradingSprite")
local TradeGuildSprite = class("TradeGuildSprite", FunctionUpgradingSprite)

function TradeGuildSprite:ctor(city_layer, entity, city)
    self.action_node = display.newNode():addTo(self)
    TradeGuildSprite.super.ctor(self, city_layer, entity, city)
    self:DoAni()
end
function TradeGuildSprite:RefreshSprite()
    TradeGuildSprite.super.RefreshSprite(self)
    self:DoAni()
end
function TradeGuildSprite:DoAni()
    if self:GetEntity():IsUnlocked() then
        self:PlayAni()
    end
end
function TradeGuildSprite:PlayAni()
    local animation = self:GetAniArray()[1]:getAnimation()
    animation:stop()
    animation:setSpeedScale(2)
    animation:playWithIndex(0, -1, 0)
    self.action_node:stopAllActions()
    self.action_node:performWithDelay(function()
        self:PlayAni()
    end, math.random(3, 6))
end


return TradeGuildSprite










