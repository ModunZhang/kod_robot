--
-- Author: Kenny Dai
-- Date: 2015-02-11 11:33:52
--
local Localize = import("..utils.Localize")
local WidgetSpeedUp = import("..widget.WidgetSpeedUp")
local GameUITreatSoldierSpeedUp = class("GameUITreatSoldierSpeedUp",WidgetSpeedUp)
local GameUtils = GameUtils

function GameUITreatSoldierSpeedUp:ctor()
    GameUITreatSoldierSpeedUp.super.ctor(self)
    local event = User.treatSoldierEvents[1]
    if not event then
        self:LeftButtonClicked()
        return
    end
    self:SetAccBtnsGroup(self:GetEventType(), event.id)
    self:SetAccTips(_("治疗伤兵不能免费加速"))
    local treat_count = 0
    for i,v in ipairs(event.soldiers) do
        treat_count = treat_count + v.count
    end
    self:SetUpgradeTip(string.format(_("正在治愈%d人口的伤兵"), treat_count))
    scheduleAt(self, function()
        local event = User.treatSoldierEvents[1]
        if not event then 
            self:LeftButtonClicked()
            return 
        end
        local time, percent = UtilsForEvent:GetEventInfo(event)
        self:SetProgressInfo(GameUtils:formatTimeStyle1(time), percent)
    end)
    User:AddListenOnType(self, "treatSoldierEvents")
end
function GameUITreatSoldierSpeedUp:GetEventType()
    return "treatSoldierEvents"
end
function GameUITreatSoldierSpeedUp:onCleanup()
    User:RemoveListenerOnType(self, "treatSoldierEvents")
    GameUITreatSoldierSpeedUp.super.onCleanup(self)
end

function GameUITreatSoldierSpeedUp:CheckCanSpeedUpFree()
	return false
end
function GameUITreatSoldierSpeedUp:OnUserDataChanged_treatSoldierEvents(userData, deltaData)
    if deltaData("treatSoldierEvents.remove") then
        self:LeftButtonClicked()
    end
end
return GameUITreatSoldierSpeedUp





