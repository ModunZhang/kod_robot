--
-- Author: Kenny Dai
-- Date: 2015-01-28 15:06:05
--
local Observer = import(".Observer")
local ItemEvent = class("ItemEvent",Observer)
local property = import("..utils.property")

function ItemEvent:ctor()
	ItemEvent.super.ctor(self)
	property(self,"id","")
	property(self,"type","")
	property(self,"startTime",0)	
	property(self,"finishTime",0)	
end

function ItemEvent:OnPropertyChange()
end

function ItemEvent:UpdateData(json_data)
	self:SetId(json_data.id or self.id or "")
	self:SetType(json_data.type or self.type or "")
	self:SetStartTime(json_data.startTime/1000 or self.startTime or 0)
	self:SetFinishTime(json_data.finishTime/1000 or self.finishTime or 0)
end

function ItemEvent:Reset()
	self:RemoveAllObserver()
end

function ItemEvent:OnTimer(current_time)
	self.times_ = math.ceil(self:FinishTime() - current_time)
	if self.times_ >= 0 then
		self:NotifyObservers(function(listener)
			listener:OnItemEventTimer(self)
		end)
	end
end

function ItemEvent:GetTime()
	return self.times_ or 0
end

return ItemEvent