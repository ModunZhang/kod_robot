--
-- Author: Kenny Dai
-- Date: 2015-02-11 16:50:55
--
local WidgetSpeedUp = import("..widget.WidgetSpeedUp")
local GameUIBlackSmithSpeedUp = class("GameUIBlackSmithSpeedUp",WidgetSpeedUp)
local GameUtils = GameUtils

function GameUIBlackSmithSpeedUp:ctor(building)
    GameUIBlackSmithSpeedUp.super.ctor(self)
    local event = User.dragonEquipmentEvents[1]
    if not event then
        self:LeftButtonClicked()
        return
    end
    self:SetAccBtnsGroup(self:GetEventType(), event.id)
    self:SetAccTips(_("制造装备不能免费加速"))
    self:SetUpgradeTip(_("制造装备").."X 1")
    scheduleAt(self, function()
        local event = User.dragonEquipmentEvents[1]
        if not event then
            self:LeftButtonClicked()
            return 
        end
        local time, percent = UtilsForEvent:GetEventInfo(event)
        self:SetProgressInfo(GameUtils:formatTimeStyle1(time), percent)
    end)
    User:AddListenOnType(self, "dragonEquipmentEvents")
end

function GameUIBlackSmithSpeedUp:GetEventType()
    return "dragonEquipmentEvents"
end
function GameUIBlackSmithSpeedUp:onCleanup()
    User:RemoveListenerOnType(self, "dragonEquipmentEvents")
    GameUIBlackSmithSpeedUp.super.onCleanup(self)
end

function GameUIBlackSmithSpeedUp:CheckCanSpeedUpFree()
	return false
end
function GameUIBlackSmithSpeedUp:OnUserDataChanged_dragonEquipmentEvents(userData, deltaData)
    if deltaData("dragonEquipmentEvents.remove") then
        self:LeftButtonClicked()
    end
end

return GameUIBlackSmithSpeedUp





