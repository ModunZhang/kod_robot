--
-- Author: Kenny Dai
-- Date: 2015-02-11 11:33:52
--
local WidgetSpeedUp = import("..widget.WidgetSpeedUp")
local SoldierManager = import("..entity.SoldierManager")
local Localize = import("..utils.Localize")
local GameUITreatSoldierSpeedUp = class("GameUITreatSoldierSpeedUp",WidgetSpeedUp)
local GameUtils = GameUtils

function GameUITreatSoldierSpeedUp:ctor(building)
    GameUITreatSoldierSpeedUp.super.ctor(self)
    self.building = building
    self:SetAccBtnsGroup(self:GetEventType(),building:GetTreatEvent():Id())
    self:SetAccTips(_("治疗伤兵不能免费加速"))
    self:SetUpgradeTip(string.format(_("正在治愈%d人口的伤兵"),self:GetTreatCount()))
    self:SetProgressInfo(GameUtils:formatTimeStyle1(building:GetTreatEvent():LeftTime(app.timer:GetServerTime())),building:GetTreatEvent():Percent(app.timer:GetServerTime()))
    building:AddHospitalListener(self)
end

function GameUITreatSoldierSpeedUp:GetEventType()
    return "treatSoldierEvents"
end
function GameUITreatSoldierSpeedUp:onCleanup()
    self.building:RemoveHospitalListener(self)
    GameUITreatSoldierSpeedUp.super.onCleanup(self)
end

function GameUITreatSoldierSpeedUp:CheckCanSpeedUpFree()
	return false
end
function GameUITreatSoldierSpeedUp:OnBeginTreat(hospital, event)
    self:OnTreating(hospital, event, app.timer:GetServerTime())
end
function GameUITreatSoldierSpeedUp:GetTreatCount()
    local treat_count = 0
    local soldiers = self.building:GetTreatEvent():GetTreatInfo()
    for k,v in pairs(soldiers) do
        treat_count = treat_count + v.count
    end
    return treat_count
end
function GameUITreatSoldierSpeedUp:OnTreating(hospital, event, current_time)
    self:SetProgressInfo(GameUtils:formatTimeStyle1(hospital:GetTreatEvent():LeftTime(current_time)),hospital:GetTreatEvent():Percent(current_time))
end

function GameUITreatSoldierSpeedUp:OnEndTreat(hospital, event, soldiers, current_time)
    self:LeftButtonClicked()
end
return GameUITreatSoldierSpeedUp





