--
-- Author: Kenny Dai
-- Date: 2015-02-11 11:13:18
--
local Localize = import("..utils.Localize")
local WidgetSpeedUp = import("..widget.WidgetSpeedUp")
local GameUIBuildingSpeedUp = class("GameUIBuildingSpeedUp",WidgetSpeedUp)
local GameUtils = GameUtils
local DataUtils = DataUtils
local timer = app.timer

function GameUIBuildingSpeedUp:ctor(event)
    GameUIBuildingSpeedUp.super.ctor(self)
    local User = User
    if not event then
        self:LeftButtonClicked()
        return
    end
    self.event = event
    self.eventType = event.location and "buildingEvents" or "houseEvents"
    self:SetAccBtnsGroup(self.eventType, event.id)
    local building = User:GetBuildingByEvent(event)
    self:SetUpgradeTip(string.format(_("正在升级 %s 到等级 %d"), Localize.building_name[building.type], building.level + 1))
    self:OnFreeButtonClicked(handler(self, self.FreeSpeedUpAction))
    scheduleAt(self, function()
        local time, percent = UtilsForEvent:GetEventInfo(self.event)
        self:SetFreeButtonEnabled(time <= DataUtils:getFreeSpeedUpLimitTime())
        self:SetProgressInfo(GameUtils:formatTimeStyle1(time), percent)
    end)

    User:AddListenOnType(self, "houseEvents")
    User:AddListenOnType(self, "buildingEvents")
end
function GameUIBuildingSpeedUp:FreeSpeedUpAction()
    local time, percent = UtilsForEvent:GetEventInfo(self.event)
    if time > 2 then
        NetManager:getFreeSpeedUpPromise(self.eventType, self.event.id)
        self:LeftButtonClicked()
    end
end
function GameUIBuildingSpeedUp:onExit()
    User:RemoveListenerOnType(self, "houseEvents")
    User:RemoveListenerOnType(self, "buildingEvents")
    GameUIBuildingSpeedUp.super.onExit(self)
end
function GameUIBuildingSpeedUp:OnUserDataChanged_buildingEvents(userData, deltaData)
    local ok, value = deltaData("buildingEvents.remove")
    if ok then
        for i,v in ipairs(value) do
            if v.id == self.event.id then
                self:LeftButtonClicked()
                return
            end
        end
    end
    local ok, value = deltaData("buildingEvents.edit")
    if ok then
        for i,v in ipairs(value) do
            if v.id == self.event.id then
                self.event = v
            end
        end
    end
end
function GameUIBuildingSpeedUp:OnUserDataChanged_houseEvents(userData, deltaData)
    local ok, value = deltaData("houseEvents.remove")
    if ok then
        for i,v in ipairs(value) do
            if v.id == self.event.id then
                self:LeftButtonClicked()
                return
            end
        end
    end
    local ok, value = deltaData("houseEvents.edit")
    if ok then
        for i,v in ipairs(value) do
            if v.id == self.event.id then
                self.event = v
            end
        end
    end
end
return GameUIBuildingSpeedUp




