--
-- Author: Danny He
-- Date: 2014-11-12 21:11:01
--
local Observer = import(".Observer")
local ShrineFightEvent = class("ShrineFightEvent",Observer)
local property = import("..utils.property")

function ShrineFightEvent:ctor()
	ShrineFightEvent.super.ctor(self)
	property(self,"stageName","")
	property(self,"startTime","")
	property(self,"id","")
	property(self,"playerTroops",{})
	property(self,"stage","") -- will be set in
end

function ShrineFightEvent:OnPropertyChange()
end

function ShrineFightEvent:Update(json_data,refresh_time)
	self:SetStageName(json_data.stageName)
	self:SetStartTime(json_data.startTime/1000.0)
	self:SetId(json_data.id)
	self:SetPlayerTroops(json_data.playerTroops)
	self.times = math.ceil(self:StartTime() - refresh_time)
end


function ShrineFightEvent:OnTimer(current_time)
	self.times = math.ceil(self:StartTime() - current_time)
	if self.times >= 0 then
		self:NotifyObservers(function(listener)
			listener:OnFightEventTimer(self)
		end)
	end
end

function ShrineFightEvent:GetTime()
	return self.times or 0
end

function ShrineFightEvent:Reset()
	self:RemoveAllObserver()
end

return ShrineFightEvent