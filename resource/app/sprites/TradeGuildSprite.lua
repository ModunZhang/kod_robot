local FunctionUpgradingSprite = import(".FunctionUpgradingSprite")
local TradeGuildSprite = class("TradeGuildSprite", FunctionUpgradingSprite)


local TIP_TAG = 112001

function TradeGuildSprite:ctor(city_layer, entity, city)
    self.action_node = display.newNode():addTo(self)
    TradeGuildSprite.super.ctor(self, city_layer, entity, city)
    display.newNode():addTo(self):schedule(function()
        self:CheckTips()
    end, 1)
end
function TradeGuildSprite:RefreshSprite()
    TradeGuildSprite.super.RefreshSprite(self)
    self:DoAni()
end
function TradeGuildSprite:DoAni()
    if self:GetEntity():IsUnlocked() then
        self:PlayAni()
        self:CheckTips()
    end
end
function TradeGuildSprite:CheckTips()
    if not self:GetEntity():IsUnlocked() then return end
    if self:GetEntity():BelongCity():GetUser():GetTradeManager():IsSoldOut() then
        if not self:getChildByTag(TIP_TAG) then
            local x,y = self:GetSpriteTopPosition()
            x = x - 20
            display.newSprite("tmp_tips_56x60.png")
                :addTo(self,1,TIP_TAG):align(display.BOTTOM_CENTER,x,y)
                :runAction(UIKit:ShakeAction(true,2))
        end
    elseif self:getChildByTag(TIP_TAG) then
        self:removeChildByTag(TIP_TAG)
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











