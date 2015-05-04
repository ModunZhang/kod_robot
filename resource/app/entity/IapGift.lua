--
-- Author: Danny He
-- Date: 2015-04-07 11:33:46
--
local Observer = import(".Observer")
local IapGift = class("IapGift",Observer)
local property = import("..utils.property")
local config_intInit = GameDatas.PlayerInitData.intInit

function IapGift:ctor()
	IapGift.super.ctor(self)
	property(self,"count",0)
	property(self,"time",0)
	property(self,"id","")
	property(self,"from","")
	property(self,"name","")
end

function IapGift:OnPropertyChange()
end

function IapGift:Update(json_data)
	self:SetCount(json_data.count)
	self:SetTime(json_data.time/1000 + config_intInit.giftExpireHours.value * 60 * 60)
	self:SetId(json_data.id)
	self:SetFrom(json_data.from)
	self:SetName(json_data.name)
end

function IapGift:OnTimer(current_time)
	self.times = math.ceil(self:Time() - current_time)
		self:NotifyObservers(function(listener)
			listener:OnIapGiftTimer(self)
		end)
end

function IapGift:GetTime()
	return self.times or 0
end

function IapGift:Reset()
	self:RemoveAllObserver()
end

return IapGift

