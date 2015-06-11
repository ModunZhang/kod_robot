--
-- Author: Kenny Dai
-- Date: 2015-02-11 16:50:55
--
local WidgetSpeedUp = import("..widget.WidgetSpeedUp")
local GameUIBlackSmithSpeedUp = class("GameUIBlackSmithSpeedUp",WidgetSpeedUp)
local GameUtils = GameUtils

function GameUIBlackSmithSpeedUp:ctor(building)
    GameUIBlackSmithSpeedUp.super.ctor(self)
    self.building = building

    local making_event = building:GetMakeEquipmentEvent()
    self:SetAccBtnsGroup(self:GetEventType(),making_event:Id())
    self:SetAccTips(_("制造装备不能免费加速"))
    self:SetUpgradeTip(_("制造装备").."X 1")
    self:SetProgressInfo(GameUtils:formatTimeStyle1(making_event:LeftTime(app.timer:GetServerTime())),making_event:Percent(app.timer:GetServerTime()))
    building:AddBlackSmithListener(self)
end

function GameUIBlackSmithSpeedUp:GetEventType()
    return "dragonEquipmentEvents"
end
function GameUIBlackSmithSpeedUp:onCleanup()
    self.building:RemoveBlackSmithListener(self)
    GameUIBlackSmithSpeedUp.super.onCleanup(self)
end

function GameUIBlackSmithSpeedUp:CheckCanSpeedUpFree()
	return false
end
function GameUIBlackSmithSpeedUp:OnBeginMakeEquipmentWithEvent(blackSmith, event)
    self:OnMakingEquipmentWithEvent(blackSmith, event, app.timer:GetServerTime())
end
function GameUIBlackSmithSpeedUp:OnMakingEquipmentWithEvent(blackSmith, event, current_time)
    self:SetProgressInfo(GameUtils:formatTimeStyle1(event:LeftTime(current_time)),event:Percent(current_time))
end

function GameUIBlackSmithSpeedUp:OnEndMakeEquipmentWithEvent(blackSmith, event, current_time)
    self:LeftButtonClicked()
end

return GameUIBlackSmithSpeedUp





