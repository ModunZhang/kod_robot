--
-- Author: Danny He
-- Date: 2014-12-02 09:26:02
--
local Observer = import(".Observer")
local MarchAttackEvent = class("MarchAttackEvent",Observer)
local Enum = import("..utils.Enum")
local property = import("..utils.property")
local Localize = import("..utils.Localize")

local monsterConfig = GameDatas.AllianceInitData.monster

MarchAttackEvent.MARCH_EVENT_PLAYER_ROLE = Enum("SENDER","RECEIVER","NOTHING")


property(MarchAttackEvent, "id", "")
property(MarchAttackEvent, "startTime", "")
property(MarchAttackEvent, "arriveTime", "")
property(MarchAttackEvent, "marchType", "")
property(MarchAttackEvent, "attackPlayerData", {})
property(MarchAttackEvent, "defencePlayerData", {})
property(MarchAttackEvent, "defenceVillageData", {})
property(MarchAttackEvent, "defenceShrineData", {})
property(MarchAttackEvent, "defenceMonsterData", {})
property(MarchAttackEvent, "isStrikeEvent",false)


function MarchAttackEvent:ctor(isStrike)
	MarchAttackEvent.super.ctor(self)
	if type(isStrike) ~= 'boolean' then
		isStrike = false
	end
	self:SetIsStrikeEvent(isStrike)
end
function MarchAttackEvent:GetTargetName()
	if self:MarchType() == "city" or self:MarchType() == "helpDefence"then
		return self:GetDefenceData().name
	elseif self:MarchType() == "village" then
		local village_data = self:GetDefenceData() 
		return Localize.village_name[village_data.name] .. "Lv" .. village_data.level
	elseif self:MarchType() == "shrine" then
		return _("圣地")
	elseif self:MarchType() == "monster" then
		local soldier_type = unpack(string.split(self:GetDefenceData().name, "_"))
		return Localize.soldier_name[soldier_type]
	end
end
--判断该玩家是这个事件的发送者/接受者/无关
function MarchAttackEvent:GetPlayerRole()
	local Me_Id = User:Id()
	if Me_Id == self:AttackPlayerData().id then
		return self.MARCH_EVENT_PLAYER_ROLE.SENDER
	elseif  Me_Id == self:GetDefenceData().id then
		return self.MARCH_EVENT_PLAYER_ROLE.RECEIVER
	else
		return self.MARCH_EVENT_PLAYER_ROLE.NOTHING 
	end
end

function MarchAttackEvent:Reset()
	self:RemoveAllObserver()
end
--是否为返回事件
function MarchAttackEvent:IsReturnEvent()
	return false
end

function MarchAttackEvent:OnTimer(current_time)
	self.times_ = math.ceil(self:ArriveTime() - current_time)
	if self.times_ >= 0 then
		self:NotifyObservers(function(listener)
			listener:OnMarchEventTimer(self)
		end)
	end
end

function MarchAttackEvent:GetTime()
	return self.times_ or 0
end


function MarchAttackEvent:FromLocation()
	return self:AttackPlayerData().location,self:AttackPlayerData().alliance.id
end
function MarchAttackEvent:TargetLocation()
	return self:GetDefenceData().location,self:GetDefenceData().alliance.id
end

function MarchAttackEvent:OnPropertyChange()
end

function MarchAttackEvent:GetDefenceData()
	if self:MarchType() == "village" then
		return self:DefenceVillageData()
	elseif self:MarchType() == "city" or  self:MarchType() == "helpDefence" then
		return self:DefencePlayerData()
	elseif self:MarchType() == "shrine" then
		return self:DefenceShrineData()
	elseif self:MarchType() == "monster" then
		return self:DefenceMonsterData()
	else
		assert(false,"不支持此种行军事件 --> " .. self:MarchType())
	end
end

function MarchAttackEvent:GetTotalTime()
	return self:ArriveTime() - self:StartTime()
end

function MarchAttackEvent:GetPercent()
	return (1 - self:GetTime() / self:GetTotalTime()) * 100
end

function MarchAttackEvent:UpdateData(json_data,refresh_time)
	self:SetId(json_data.id or "")
	self:SetStartTime(json_data.startTime and json_data.startTime/1000.0 or 0)
	self:SetArriveTime(json_data.arriveTime and json_data.arriveTime/1000.0 or 0)
	self:SetMarchType(json_data.marchType or "")
	self:SetAttackPlayerData(json_data.attackPlayerData or {})
	self:SetDefencePlayerData(json_data.defencePlayerData or {})
	self:SetDefenceVillageData(json_data.defenceVillageData or {})
	self:SetDefenceShrineData(json_data.defenceShrineData or {})
	self:SetDefenceMonsterData(json_data.defenceMonsterData or {})
	self.times_ = math.ceil(self:ArriveTime() - refresh_time)
end

return MarchAttackEvent