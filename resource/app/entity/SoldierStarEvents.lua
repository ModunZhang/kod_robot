--
-- Author: Kenny Dai
-- Date: 2015-02-10 15:09:26
--
local Observer = import(".Observer")
local Localize = import("..utils.Localize")
local SoldierStarEvents = class("SoldierStarEvents",Observer)
local property = import("..utils.property")

function SoldierStarEvents:ctor()
    SoldierStarEvents.super.ctor(self)
    property(self,"id","")
    property(self,"name","")
    property(self,"startTime",0)
    property(self,"finishTime",0)
end

function SoldierStarEvents:OnPropertyChange()
end

function SoldierStarEvents:UpdateData(json_data)
    self:SetId(json_data.id or self.id or "")
    self:SetName(json_data.name or self.name or "")
    self:SetStartTime(json_data.startTime/1000 or self.startTime or 0)
    self:SetFinishTime(json_data.finishTime/1000 or self.finishTime or 0)
end

function SoldierStarEvents:Reset()
    self:RemoveAllObserver()
end

function SoldierStarEvents:OnTimer(current_time)
    self.times_ = math.ceil(self:FinishTime() - current_time)
    if self.times_ >= 0 then
        self:NotifyObservers(function(listener)
            listener:OnSoldierStarEventsTimer(self)
        end)
    end
end
function SoldierStarEvents:Percent(current_time)
    local c_time = current_time or app.timer:GetServerTime()
    local start_time = self:StartTime()
    local elapse_time = c_time - start_time
    local total_time = self.finishTime - start_time
    return elapse_time * 100.0 / total_time
end
function SoldierStarEvents:GetTime()
    return self.times_ or 0
end
function SoldierStarEvents:LeftTime()
    return self.times_ or 0
end
function SoldierStarEvents:GetLocalizeDesc()
    local star = City:GetSoldierManager():GetStarBySoldierType(self.name)
    return string.format(_("晋升%s的星级 star %d"),Localize.soldier_name[self.name],star+1)
end
function SoldierStarEvents:GetEventType()
    return "soldierStarEvents"
end
return SoldierStarEvents

