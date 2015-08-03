--
-- Author: Kenny Dai
-- Date: 2015-01-31 14:56:48
--
local Observer = import(".Observer")
local VipEvent = class("VipEvent",Observer)
local property = import("..utils.property")

function VipEvent:ctor()
    VipEvent.super.ctor(self)
    property(self,"id","")
    property(self,"startTime",0)
    property(self,"finishTime",0)
end

function VipEvent:OnPropertyChange()
end

function VipEvent:UpdateData(json_data)
    self:SetId(json_data.id or self.id or "")
    self:SetStartTime(json_data.startTime and json_data.startTime/1000 or self.startTime or 0)
    self:SetFinishTime(json_data.finishTime and json_data.finishTime/1000 or self.finishTime or 0)
end

function VipEvent:Reset()
    self:SetId("")
    self:SetStartTime(0)
    self:SetFinishTime(0)
    self.times_ = 0
end

function VipEvent:OnTimer(current_time)
    self.times_ = math.ceil(self:FinishTime() - current_time)
    if self.times_ >= 0 then
        self:NotifyObservers(function(listener)
            listener:OnVipEventTimer(self)
        end)
    else
        self.times_ = 0
    end
end

function VipEvent:GetTime()
    return self.times_ or 0
end
function VipEvent:IsActived()
    return (self.times_ and self.times_ > 0) or (self.finishTime - self.startTime > 0)
end
return VipEvent



