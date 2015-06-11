--
-- Author: Danny He
-- Date: 2015-01-05 17:28:37
--
--龙巢孵化事件
local Observer = import(".Observer")
local DragonEvent = class("DragonEvent",Observer)
local property = import("..utils.property")

function DragonEvent:ctor()
	DragonEvent.super.ctor(self)
	property(self,"id","")
	property(self,"dragonType","")
	property(self,"finishTime","")	
	property(self,"startTime","")	
end

function DragonEvent:OnPropertyChange()
end

function DragonEvent:UpdateData(json_data)
	self:SetId(json_data.id or "")
	self:SetDragonType(json_data.dragonType or  "")
	self:SetFinishTime(json_data.finishTime/1000 or 0)
	self:SetStartTime(json_data.startTime/1000 or 0)
end

function DragonEvent:Reset()
	self:RemoveAllObserver()
end

function DragonEvent:OnTimer(current_time)
	self.times_ = math.ceil(self:FinishTime() - current_time)
	if self.times_ >= 0 then
		self:NotifyObservers(function(listener)
			listener:OnDragonEventTimer(self)
		end)
	end
end

function DragonEvent:GetTime()
	return self.times_ or 0
end

function DragonEvent:GetPercent()
	local totalTime = self:FinishTime() - self:StartTime()
	return math.ceil(100 - self:GetTime()/totalTime*100)
end


return DragonEvent