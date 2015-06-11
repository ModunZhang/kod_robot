--
-- Author: Kenny Dai
-- Date: 2015-02-11 14:43:05
--
local WidgetSpeedUp = import("..widget.WidgetSpeedUp")
local SoldierManager = import("..entity.SoldierManager")
local Localize = import("..utils.Localize")
local GameUIBarracksSpeedUp = class("GameUIBarracksSpeedUp",WidgetSpeedUp)
local GameUtils = GameUtils
function GameUIBarracksSpeedUp:ctor(building)
    GameUIBarracksSpeedUp.super.ctor(self)
    self.building = building

    local event = building:GetRecruitEvent()
    local soldier_type, count = event:GetRecruitInfo()
    self:SetAccBtnsGroup(self:GetEventType(),building:GetRecruitEvent():Id())
    self:SetAccTips(_("招募士兵不能免费加速"))
    self:SetUpgradeTip(string.format("%s%s x%d", _("招募"), Localize.soldier_name[soldier_type], count))
    self:SetProgressInfo(GameUtils:formatTimeStyle1(building:GetRecruitEvent():LeftTime(app.timer:GetServerTime())),building:GetRecruitEvent():Percent(app.timer:GetServerTime()))
    building:AddBarracksListener(self)
end

function GameUIBarracksSpeedUp:GetEventType()
    return "soldierEvents"
end
function GameUIBarracksSpeedUp:onCleanup()
    self.building:RemoveBarracksListener(self)
    GameUIBarracksSpeedUp.super.onCleanup(self)
end

function GameUIBarracksSpeedUp:CheckCanSpeedUpFree()
	return false
end
function GameUIBarracksSpeedUp:OnBeginRecruit(barracks, event)
    self:OnRecruiting(barracks, event, app.timer:GetServerTime())
end
function GameUIBarracksSpeedUp:OnRecruiting(barracks, event, current_time)
    self:SetProgressInfo(GameUtils:formatTimeStyle1(barracks:GetRecruitEvent():LeftTime(current_time)),barracks:GetRecruitEvent():Percent(current_time))
end

function GameUIBarracksSpeedUp:OnEndRecruit(barracks, event, current_time)
    self:LeftButtonClicked()
end

return GameUIBarracksSpeedUp





