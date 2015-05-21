--
-- Author: Danny He
-- Date: 2014-12-27 09:48:47
--
--村落采集事件
local Enum = import("..utils.Enum")
local Observer = import(".Observer")
local property = import("..utils.property")
local VillageEvent = class("VillageEvent", Observer)
local VillageConfig = GameDatas.AllianceVillage

VillageEvent.EVENT_PLAYER_ROLE = Enum("Me","Ally")


property(VillageEvent, "id", "")
property(VillageEvent, "startTime", "")
property(VillageEvent, "finishTime", "")
property(VillageEvent, "playerData", "")
property(VillageEvent, "villageData", "")
property(VillageEvent, "collectPercent", 0)
property(VillageEvent, "collectCount", 0)


function VillageEvent:OnPropertyChange()
end

function VillageEvent:GetPlayerRole()
	local Me_Id = User:Id()
	if Me_Id == self:PlayerData().id then
		return self.EVENT_PLAYER_ROLE.Me 
	else
		return self.EVENT_PLAYER_ROLE.Ally
	end
end


function VillageEvent:ctor()
	VillageEvent.super.ctor(self)
end

function VillageEvent:UpdateData(json_data,refresh_time)
	self:SetId(json_data.id or "")
	self:SetStartTime(json_data.startTime and json_data.startTime/1000.0 or "")
	self:SetFinishTime(json_data.finishTime and json_data.finishTime/1000.0 or "")
	self:SetPlayerData(json_data.playerData or  {})
	self:SetVillageData(json_data.villageData or {})
	self.times_ = math.ceil(self:FinishTime() - refresh_time)
end

function VillageEvent:FromLocation()
	return self:PlayerData().location,self:PlayerData().alliance.id
end

function VillageEvent:TargetLocation()
	return self:VillageData().location,self:VillageData().alliance.id
end

function VillageEvent:Reset()
	self:RemoveAllObserver()
end

function VillageEvent:OnTimer(current_time)
	self.times_ = math.ceil(self:FinishTime() - current_time)
	if self.times_ >= 0 then
		local collectTime = current_time - self:StartTime()
		local collectCount = math.floor(self:GetCollectSpeed() * collectTime)
		local collectPercent = math.floor(collectCount/self:VillageData().collectTotal * 100)
		self:SetCollectPercent(collectPercent)
		self:SetCollectCount(collectCount)
		self:NotifyObservers(function(listener)
			listener:OnVillageEventTimer(self)
		end)
	else
		self:SetCollectPercent(100)
		self:SetCollectCount(self:VillageData().collectTotal)
	end
end

function VillageEvent:GetCurrentCollect()
	return "",""
end

function VillageEvent:GetCollectSpeed()
	return self:VillageData().collectTotal/(self:FinishTime() - self:StartTime())
end

function VillageEvent:GetTime()
	return math.max(self.times_ or 0,0)
end

function VillageEvent:GetVillageConfig()
	return self.GetVillageConfig(self:VillageData().type,self:VillageData().level)
end

function VillageEvent.GetVillageConfig(type,level)
	local villageWithType = VillageConfig[type]
	return villageWithType[level]
end

return VillageEvent