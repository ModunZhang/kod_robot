local Observer = import(".Observer")
local MoonGateMarchEvent = class("MoonGateMarchEvent",Observer)
local property = import("..utils.property")

function MoonGateMarchEvent:ctor()
	MoonGateMarchEvent.super.ctor(self)
	property(self,"id","")
	property(self,"startTime","")
	property(self,"arriveTime","")
	property(self,"playerData","")
end

function MoonGateMarchEvent:OnPropertyChange()
end

function MoonGateMarchEvent:Update(json_data)
	self:SetId(json_data.id)
	self:SetStartTime(json_data.startTime/1000.0)
	self:SetArriveTime(json_data.arriveTime/1000.0)
	self:SetPlayerData(json_data.playerData) -- playerData is table
end

function MoonGateMarchEvent:Reset()
	self:RemoveAllObserver()
end

function MoonGateMarchEvent:SetLocationInfo(from,target)
	self:SetFromLocation(from)
	self:SetTargetLocation(target)
end

function MoonGateMarchEvent:SetFromLocation( from )
	self.fromLocation = from
end

function MoonGateMarchEvent:FromLocation()
	return self.fromLocation
end

function MoonGateMarchEvent:SetTargetLocation( target )
	self.targetLocation = target
end

function MoonGateMarchEvent:TargetLocation()
	return self.targetLocation
end

return MoonGateMarchEvent