local zz = import("..particles.zz")
local FunctionUpgradingSprite = import(".FunctionUpgradingSprite")
local TownHallSprite = class("TownHallSprite", FunctionUpgradingSprite)

function TownHallSprite:OnUserDataChanged_dailyQuestEvents(userData, deltaData)
    local ok, value = deltaData("dailyQuestEvents.edit")
    if ok then
        for _,v in ipairs(value) do
            if v.finishTime == 0 then
                app:GetAudioManager():PlayeEffectSoundWithKey("COMPLETE")
                break
            end
        end
    end
    self:CheckEvent()
end


local EMPTY_TAG = 11400
local TIP_TAG = 11201
function TownHallSprite:ctor(city_layer, entity, city)
    TownHallSprite.super.ctor(self, city_layer, entity, city)
    city:GetUser():AddListenOnType(self, "dailyQuestEvents")
    display.newNode():addTo(self):schedule(function()
        self:CheckEvent()
    end,1)
end
function TownHallSprite:RefreshSprite()
    TownHallSprite.super.RefreshSprite(self)
    self:CheckEvent()
end
function TownHallSprite:CheckEvent()
    if self:GetEntity():IsUnlocked() then
        local user = self:GetEntity():BelongCity():GetUser()
        if user:IsOnDailyQuestEvents() then
            self:GetAniArray()[1]:show()
            self:RemoveEmptyanimation()
        elseif user:IsFinishedAllDailyQuests() then
            self:GetAniArray()[1]:hide()
            self:RemoveEmptyanimation()
        else
            self:GetAniArray()[1]:hide()
            self:PlayEmptyAnimation()
        end
        if user:CouldGotDailyQuestReward() then
            if not self:getChildByTag(TIP_TAG) then
                local x,y = self:GetSpriteTopPosition()
                x = x - 20
                y = y - 100
                display.newSprite("tmp_tips_56x60.png")
                    :addTo(self,1,TIP_TAG):align(display.BOTTOM_CENTER,x,y)
                    :runAction(UIKit:ShakeAction(true,2))
            end
        elseif self:getChildByTag(TIP_TAG) then
            self:removeChildByTag(TIP_TAG)
        end
    end
end
function TownHallSprite:RemoveEmptyanimation()
    if self:getChildByTag(EMPTY_TAG) then
        self:removeChildByTag(EMPTY_TAG)
    end
end
function TownHallSprite:PlayEmptyAnimation()
    if not self:getChildByTag(EMPTY_TAG) then
        local x,y = self:GetSprite():getPosition()
        zz():addTo(self,1,EMPTY_TAG):pos(x + 50,y + 50)
    end
end

return TownHallSprite












