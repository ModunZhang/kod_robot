--
-- Author: Kenny Dai
-- Date: 2015-02-11 09:05:01
--
local WidgetSpeedUp = import("..widget.WidgetSpeedUp")
local GameUIMilitaryTechSpeedUp = class("GameUIMilitaryTechSpeedUp",WidgetSpeedUp)
local GameUtils = GameUtils

function GameUIMilitaryTechSpeedUp:ctor(event)
    local User = User
    GameUIMilitaryTechSpeedUp.super.ctor(self)
    self.militaryEvent = event
    self:SetAccBtnsGroup(User:EventType(event),event.id)
    local str
    if User:IsSoldierStarEvent(event) then
        str = UtilsForEvent:GetMilitaryTechEventLocalize(event.name, User:SoldierStarByName(event.name))
    else
        str = UtilsForEvent:GetMilitaryTechEventLocalize(event.name, User:GetMilitaryTechLevel(event.name))
    end
    self:SetUpgradeTip(str)
    local time, percent = UtilsForEvent:GetEventInfo(event)
    self:SetProgressInfo(GameUtils:formatTimeStyle1(time), percent)
    self:CheckCanSpeedUpFree()
    self:OnFreeButtonClicked(handler(self, self.FreeSpeedUpAction))

    User:AddListenOnType(self, "soldierStarEvents")
    User:AddListenOnType(self, "militaryTechEvents")
    scheduleAt(self, function()
        if self.progress then
            local time, percent = UtilsForEvent:GetEventInfo(self:GetEvent())
            self:SetProgressInfo(GameUtils:formatTimeStyle1(time), percent)
            self:CheckCanSpeedUpFree()
        end
    end)
end

function GameUIMilitaryTechSpeedUp:FreeSpeedUpAction()
    local time, percent = UtilsForEvent:GetEventInfo(self:GetEvent())
    if time > 2 then
        NetManager:getFreeSpeedUpPromise(User:EventType(self:GetEvent()),self:GetEvent().id)
    end
end

function GameUIMilitaryTechSpeedUp:onCleanup()
    User:RemoveListenerOnType(self, "soldierStarEvents")
    User:RemoveListenerOnType(self, "militaryTechEvents")
    GameUIMilitaryTechSpeedUp.super.onCleanup(self)
end
function GameUIMilitaryTechSpeedUp:OnUserDataChanged_militaryTechEvents(userData, deltaData)
    local ok, value = deltaData("militaryTechEvents.edit")
    if ok then
        self.militaryEvent = User:GetEventById(self.militaryEvent.id)
    end
    local ok, value = deltaData("militaryTechEvents.remove")
    if ok then
        for i,v in ipairs(value) do
            if v.id ==  self.militaryEvent.id then
                self:LeftButtonClicked()
            end
        end
    end
end
function GameUIMilitaryTechSpeedUp:OnUserDataChanged_soldierStarEvents(userData, deltaData)
    local ok, value = deltaData("soldierStarEvents.edit")
    if ok then
        self.militaryEvent = User:GetEventById(self.militaryEvent.id)
    end
    local ok, value = deltaData("soldierStarEvents.remove")
    if ok then
        for i,v in ipairs(value) do
            if v.id ==  self.militaryEvent.id then
                self:LeftButtonClicked()
            end
        end
    end
end
function GameUIMilitaryTechSpeedUp:GetEvent()
    return self.militaryEvent
end

function GameUIMilitaryTechSpeedUp:CheckCanSpeedUpFree()
    local time, percent = UtilsForEvent:GetEventInfo(self:GetEvent())
    self:SetFreeButtonEnabled(time <= DataUtils:getFreeSpeedUpLimitTime())
end

return GameUIMilitaryTechSpeedUp



