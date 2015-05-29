local zz = import("..particles.zz")
local FunctionUpgradingSprite = import(".FunctionUpgradingSprite")
local TownHallSprite = class("TownHallSprite", FunctionUpgradingSprite)

function TownHallSprite:OnNewDailyQuestsEvent(changed_map)
    local changed_map = changed_map or {}
    for _,v in ipairs(changed_map.edit or {}) do
        if v.finishTime == 0 then
            app:GetAudioManager():PlayeEffectSoundWithKey("COMPLETE")
            break
        end
    end
    self:DoAni()
end




local EMPTY_TAG = 11400
function TownHallSprite:ctor(city_layer, entity, city)
    TownHallSprite.super.ctor(self, city_layer, entity, city)
    city:GetUser():AddListenOnType(self, city:GetUser().LISTEN_TYPE.NEW_DALIY_QUEST_EVENT)
    self:DoAni()
end
function TownHallSprite:RefreshSprite()
    TownHallSprite.super.RefreshSprite(self)
    self:DoAni()
end
function TownHallSprite:DoAni()
    if self:GetEntity():IsUnlocked() then
        if self:GetEntity():BelongCity():GetUser():IsOnDailyQuestEvents() then
            self:PlayAni()
            self:removeChildByTag(EMPTY_TAG)
        else
            self:StopAni()
            self:PlayEmptyAnimation()
        end
    end
end
function TownHallSprite:PlayAni()
    local animation = self:GetAniArray()[1]:show():getAnimation()
    animation:stop()
    animation:setSpeedScale(2)
    animation:playWithIndex(0)
end
function TownHallSprite:StopAni()
    self:GetAniArray()[1]:hide():getAnimation():stop()
end
function TownHallSprite:PlayEmptyAnimation()
    if not self:getChildByTag(EMPTY_TAG) then
        local x,y = self:GetSprite():getPosition()
        zz():addTo(self,1,EMPTY_TAG):pos(x + 50,y + 50)
    end
end

return TownHallSprite











