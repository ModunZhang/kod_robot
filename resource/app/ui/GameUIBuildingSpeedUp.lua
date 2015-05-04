--
-- Author: Kenny Dai
-- Date: 2015-02-11 11:13:18
--
local WidgetSpeedUp = import("..widget.WidgetSpeedUp")
local SoldierManager = import("..entity.SoldierManager")
local Localize = import("..utils.Localize")
local GameUIBuildingSpeedUp = class("GameUIBuildingSpeedUp",WidgetSpeedUp)
local GameUtils = GameUtils
local DataUtils = DataUtils
local timer = app.timer

function GameUIBuildingSpeedUp:ctor(building)
    GameUIBuildingSpeedUp.super.ctor(self)
    self.building = building
    self:SetAccBtnsGroup(building:EventType(),building:UniqueUpgradingKey())
    self:SetUpgradeTip(string.format(_("正在升级 %s 到等级 %d"),Localize.getBuildingLocalizedKeyByBuildingType(building:GetType()),building:GetLevel()+1))
    self:CheckCanSpeedUpFree()
    self:OnFreeButtonClicked(handler(self, self.FreeSpeedUpAction))
    self:SetProgressInfo(GameUtils:formatTimeStyle1(building:GetUpgradingLeftTimeByCurrentTime(app.timer:GetServerTime())),building:GetUpgradingPercentByCurrentTime(app.timer:GetServerTime()))
    building:AddUpgradeListener(self)
end
function GameUIBuildingSpeedUp:FreeSpeedUpAction()
    local event_type = self.building:EventType()
    local unique_key = self.building:UniqueUpgradingKey()
    self:LeftButtonClicked()
    NetManager:getFreeSpeedUpPromise(event_type,unique_key)
end
function GameUIBuildingSpeedUp:onExit()
    self.building:RemoveUpgradeListener(self)
    GameUIBuildingSpeedUp.super.onCleanup(self)
    GameUIBuildingSpeedUp.super.onExit(self)
end

function GameUIBuildingSpeedUp:CheckCanSpeedUpFree()
    self:SetFreeButtonEnabled(self.building:GetUpgradingLeftTimeByCurrentTime(timer:GetServerTime()) <= DataUtils:getFreeSpeedUpLimitTime())
end
function GameUIBuildingSpeedUp:OnBuildingUpgradingBegin( building, current_time )
    self:SetProgressInfo(GameUtils:formatTimeStyle1(building:GetUpgradingLeftTimeByCurrentTime(current_time)),building:GetUpgradingPercentByCurrentTime(current_time))
end
function GameUIBuildingSpeedUp:OnBuildingUpgradeFinished( building )
    self:LeftButtonClicked()
end
function GameUIBuildingSpeedUp:OnBuildingUpgrading( building, current_time )
    self:CheckCanSpeedUpFree()
    self:SetProgressInfo(GameUtils:formatTimeStyle1(building:GetUpgradingLeftTimeByCurrentTime(current_time)),math.floor(building:GetUpgradingPercentByCurrentTime(current_time)))
end
return GameUIBuildingSpeedUp




