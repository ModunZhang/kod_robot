--
-- Author: Kenny Dai
-- Date: 2015-02-11 14:43:05
--
local Localize = import("..utils.Localize")
local WidgetSpeedUp = import("..widget.WidgetSpeedUp")
local GameUIBarracksSpeedUp = class("GameUIBarracksSpeedUp",WidgetSpeedUp)
local GameUtils = GameUtils
function GameUIBarracksSpeedUp:ctor()
    GameUIBarracksSpeedUp.super.ctor(self)
    local event = User:GetSoldierEventsBySeq()[1]
    if not event then
        self:LeftButtonClicked()
        return
    end
    self:SetAccBtnsGroup(self:GetEventType(), event.id)
    self:SetAccTips(_("招募士兵不能免费加速"))
    self:SetUpgradeTip(string.format(_("招募%s x%d"), Localize.soldier_name[event.name], event.count))
    
    User:AddListenOnType(self, "soldierEvents")
    scheduleAt(self, function()
        local event = User:GetSoldierEventsBySeq()[1]
        if not event then
            self:LeftButtonClicked()
        end
        local time, percent = UtilsForEvent:GetEventInfo(event)
        self:SetProgressInfo(GameUtils:formatTimeStyle1(time), percent)
    end)
end

function GameUIBarracksSpeedUp:GetEventType()
    return "soldierEvents"
end
function GameUIBarracksSpeedUp:onCleanup()
    User:RemoveListenerOnType(self, "soldierEvents")
    GameUIBarracksSpeedUp.super.onCleanup(self)
end

function GameUIBarracksSpeedUp:CheckCanSpeedUpFree()
	return false
end
function GameUIBarracksSpeedUp:OnUserDataChanged_soldierEvents(userData, deltaData)
    if deltaData("soldierEvents.remove") then
        self:LeftButtonClicked()
    end
end

return GameUIBarracksSpeedUp





