--
-- Author: Danny He
-- Date: 2015-01-15 19:42:52
--
local Observer = import(".Observer")
local ProductionTechnologyEvent = class("ProductionTechnologyEvent",Observer)
local property = import("..utils.property")
local Localize = import("..utils.Localize")

function ProductionTechnologyEvent:OnPropertyChange()
end

function ProductionTechnologyEvent:ctor()
	ProductionTechnologyEvent.super.ctor(self)
	property(self,"id","")
	property(self,"name","")
	property(self,"startTime","")
	property(self,"finishTime","")
	property(self,"entity","")
end

function ProductionTechnologyEvent:OnTimer(current_time)
	self.times_ = math.ceil(self:FinishTime() - current_time)
	if self.times_ >= 0 then
		self:NotifyObservers(function(listener)
			listener:OnProductionTechnologyEventTimer(self)
		end)
	end
end

function ProductionTechnologyEvent:UpdateData(json_data)
	self:SetId(json_data.id or "")
	self:SetStartTime(json_data.startTime and json_data.startTime/1000.0 or 0)
	self:SetFinishTime(json_data.finishTime and  json_data.finishTime/1000.0 or 0)
	self:SetName(json_data.name)
	if self:FinishTime() == 0 then
		self:CancelLocalPush()
	else
		self:GeneralLocalPush()
	end
end

function ProductionTechnologyEvent:GetTime()
	return self.times_ or math.ceil(self:FinishTime() - app.timer:GetServerTime()) 
end
function ProductionTechnologyEvent:GetBuffLocalizedDesc()
	return Localize.productiontechnology_buffer[self:Name()] or ""
end
function ProductionTechnologyEvent:GetBuffLocalizedDescComplete()
	return Localize.productiontechnology_buffer_complete[self:Name()] or ""
end
function ProductionTechnologyEvent:Reset()
	self:RemoveAllObserver()
end
function ProductionTechnologyEvent:GeneralLocalPush()
    if ext and ext.localpush then
        local title = self:GetBuffLocalizedDescComplete()
        app:GetPushManager():UpdateTechnologyPush(self:FinishTime(),title,self.id)
    end
end
function ProductionTechnologyEvent:CancelLocalPush()
    if ext and ext.localpush then
        app:GetPushManager():CancelTechnologyPush(self.id)
    end
end
--TODO:
function ProductionTechnologyEvent:GetPercent()
	local totalTime = app.timer:GetServerTime() - self:StartTime()
	return totalTime/self:Entity():GetLevelUpCost().buildTime * 100
end
function ProductionTechnologyEvent:LeftTime()
	return self.times_ or 0
end
function ProductionTechnologyEvent:Percent()
	return self:GetPercent()
end

return ProductionTechnologyEvent