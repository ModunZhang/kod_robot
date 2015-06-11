--
-- Author: Kenny Dai
-- Date: 2015-02-11 09:05:01
--
local WidgetSpeedUp = import("..widget.WidgetSpeedUp")
local SoldierManager = import("..entity.SoldierManager")
local GameUIMilitaryTechSpeedUp = class("GameUIMilitaryTechSpeedUp",WidgetSpeedUp)
local GameUtils = GameUtils

function GameUIMilitaryTechSpeedUp:ctor(event)
    GameUIMilitaryTechSpeedUp.super.ctor(self)
    self.militaryEvent = event
    self:SetAccBtnsGroup(self:GetEvent():GetEventType(),event:Id())
    self:SetUpgradeTip(event:GetLocalizeDesc())
    self:SetProgressInfo(GameUtils:formatTimeStyle1(event:GetTime()),event:Percent())
    self:CheckCanSpeedUpFree()
    self:OnFreeButtonClicked(handler(self, self.FreeSpeedUpAction))

    City:GetSoldierManager():AddListenOnType(self,SoldierManager.LISTEN_TYPE.OnSoldierStarEventsTimer)
    City:GetSoldierManager():AddListenOnType(self,SoldierManager.LISTEN_TYPE.OnMilitaryTechEventsTimer)
    City:GetSoldierManager():AddListenOnType(self,SoldierManager.LISTEN_TYPE.MILITARY_TECHS_EVENTS_CHANGED)
    City:GetSoldierManager():AddListenOnType(self,SoldierManager.LISTEN_TYPE.SOLDIER_STAR_EVENTS_CHANGED)
end

function GameUIMilitaryTechSpeedUp:FreeSpeedUpAction()
    NetManager:getFreeSpeedUpPromise(self:GetEvent():GetEventType(),self:GetEvent():Id()):done(function()
        self:LeftButtonClicked()
    end)
end

function GameUIMilitaryTechSpeedUp:onCleanup()
    City:GetSoldierManager():RemoveListenerOnType(self,SoldierManager.LISTEN_TYPE.OnSoldierStarEventsTimer)
    City:GetSoldierManager():RemoveListenerOnType(self,SoldierManager.LISTEN_TYPE.OnMilitaryTechEventsTimer)
    City:GetSoldierManager():RemoveListenerOnType(self,SoldierManager.LISTEN_TYPE.MILITARY_TECHS_EVENTS_CHANGED)
    City:GetSoldierManager():RemoveListenerOnType(self,SoldierManager.LISTEN_TYPE.SOLDIER_STAR_EVENTS_CHANGED)
    GameUIMilitaryTechSpeedUp.super.onCleanup(self)
end

function GameUIMilitaryTechSpeedUp:OnMilitaryTechEventsTimer(event)
    if self.progress and event:Id() == self.militaryEvent:Id() then
        self:SetProgressInfo(GameUtils:formatTimeStyle1(event:GetTime()),event:Percent())
        self:CheckCanSpeedUpFree()
    end
end
function GameUIMilitaryTechSpeedUp:OnSoldierStarEventsTimer(event)
    if self.progress and event:Id() == self.militaryEvent:Id() then
        self:SetProgressInfo(GameUtils:formatTimeStyle1(event:GetTime()),event:Percent())
        self:CheckCanSpeedUpFree()
    end
end
function GameUIMilitaryTechSpeedUp:OnMilitaryTechEventsChanged(soldier_manager,changed_map)
    if changed_map[3] then
        for i,v in ipairs(changed_map[3]) do
            if v:Id() ==  self.militaryEvent:Id() then
                self:LeftButtonClicked()
            end
        end
    end
end
function GameUIMilitaryTechSpeedUp:OnSoldierStarEventsChanged(soldier_manager,changed_map)
    if changed_map[3] then
        for i,v in ipairs(changed_map[3]) do
            if v:Id() ==  self.militaryEvent:Id() then
                self:LeftButtonClicked()
            end
        end
    end
end
function GameUIMilitaryTechSpeedUp:GetEvent()
    return self.militaryEvent
end

function GameUIMilitaryTechSpeedUp:CheckCanSpeedUpFree()
    self:SetFreeButtonEnabled(self:GetEvent():GetTime() <= DataUtils:getFreeSpeedUpLimitTime())
end

return GameUIMilitaryTechSpeedUp



