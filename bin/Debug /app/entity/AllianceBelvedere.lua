--
-- Author: Danny He
-- Date: 2014-12-30 15:10:58
--
--[[ 
给瞭望塔、区域地图事件条使用、区域地图的行军路线会从这里读取属性来判定是否显示
--]]
local Enum = import("..utils.Enum")
local MultiObserver = import(".MultiObserver")
local AllianceBelvedere = class("AllianceBelvedere",MultiObserver)
local BelvedereEntity = import(".BelvedereEntity")
local client_config_watchTower = GameDatas.ClientInitGame.watchTower
AllianceBelvedere.LISTEN_TYPE = Enum("OnCommingDataChanged","OnMarchDataChanged","OnAttackMarchEventTimerChanged","OnVillageEventTimer","OnFightEventTimerChanged","OnStrikeMarchEventDataChanged","OnAttackMarchEventDataChanged","CheckNotHaveTheEventIf")

function AllianceBelvedere:ctor(alliance)
	AllianceBelvedere.super.ctor(self)
	self.alliance = alliance
end

function AllianceBelvedere:GetMarchLimit()
	return User:MarchQueue()
end

function AllianceBelvedere:IsReachEventLimit()
	return self:GetMarchLimit() <= #self:GetMyEvents()
end

function AllianceBelvedere:GetEnemyAlliance()
	return Alliance_Manager:GetEnemyAlliance()
end

function AllianceBelvedere:GetAlliance()
	return self.alliance
end

function AllianceBelvedere:Handler2BelvedereEntity(dis,src,entity_type)
	for _,v in ipairs(src) do
		local belvedereEntity = BelvedereEntity.new(v)
		belvedereEntity:SetType(entity_type)
		table.insert(dis, 1,belvedereEntity)
	end
end

--其他人对于我的行军事件
function AllianceBelvedere:GetOtherEvents()
	local other_events = {}
	--敌方联盟
	local marching_in_events = LuaUtils:table_filteri(self:GetEnemyAlliance():GetAttackMarchEvents(),function(_,marchAttackEvent)
		return marchAttackEvent:GetPlayerRole() == marchAttackEvent.MARCH_EVENT_PLAYER_ROLE.RECEIVER and marchAttackEvent:GetTime() <= self:GetWarningTime()
	end)
	self:Handler2BelvedereEntity(other_events,marching_in_events,BelvedereEntity.ENTITY_TYPE.MARCH_OUT)
	--突袭
	local marching_strike_events = LuaUtils:table_filteri(self:GetEnemyAlliance():GetStrikeMarchEvents(),function(_,strikeMarchEvent)
		return strikeMarchEvent:GetPlayerRole() == strikeMarchEvent.MARCH_EVENT_PLAYER_ROLE.RECEIVER and strikeMarchEvent:GetTime() <= self:GetWarningTime()
	end)
	self:Handler2BelvedereEntity(other_events,marching_strike_events,BelvedereEntity.ENTITY_TYPE.STRIKE_OUT)
	local help_events = self:GetAlliance():GetAttackMarchEvents("helpDefence")
	local helpByOhters = LuaUtils:table_filteri(help_events,function(_,marchAttackEvent)
		return marchAttackEvent:GetPlayerRole() == marchAttackEvent.MARCH_EVENT_PLAYER_ROLE.RECEIVER 
	end)
	self:Handler2BelvedereEntity(other_events,helpByOhters,BelvedereEntity.ENTITY_TYPE.MARCH_OUT)
	return other_events
end
--自己操作的所有事件(攻打玩家、攻打村落、圣地、突袭)
function AllianceBelvedere:GetMyEvents()
	local my_events = {}
	--所有正在进行的出去行军
	local marching_out_events = LuaUtils:table_filteri(self:GetAlliance():GetAttackMarchEvents(),function(_,marchAttackEvent)
		return marchAttackEvent:GetPlayerRole() == marchAttackEvent.MARCH_EVENT_PLAYER_ROLE.SENDER 
	end)
	self:Handler2BelvedereEntity(my_events,marching_out_events,BelvedereEntity.ENTITY_TYPE.MARCH_OUT)
	--已出去采集村落、协防、圣地打仗
	local village_ing = LuaUtils:table_filteri(self:GetAlliance():GetVillageEvent(),function(_,villageEvent)
		return villageEvent:GetPlayerRole() == villageEvent.EVENT_PLAYER_ROLE.Me
	end)
	self:Handler2BelvedereEntity(my_events,village_ing,BelvedereEntity.ENTITY_TYPE.COLLECT)
	local helpToTroops = City:GetHelpToTroops()
	self:Handler2BelvedereEntity(my_events,helpToTroops,BelvedereEntity.ENTITY_TYPE.HELPTO)
	local shrine_Event = self:GetAlliance():GetAllianceShrine():GetSelfJoinedShrineEvent()
	self:Handler2BelvedereEntity(my_events,{shrine_Event},BelvedereEntity.ENTITY_TYPE.SHIRNE)
	--所有正在进行的返回行军
	local marching_out_return_events = LuaUtils:table_filteri(self:GetAlliance():GetAttackMarchReturnEvents(),function(_,marchAttackEvent)
		return marchAttackEvent:GetPlayerRole() == marchAttackEvent.MARCH_EVENT_PLAYER_ROLE.RECEIVER 
	end)
	self:Handler2BelvedereEntity(my_events,marching_out_return_events,BelvedereEntity.ENTITY_TYPE.MARCH_RETURN)
	--突袭
	local marching_strike_events = LuaUtils:table_filteri(self:GetAlliance():GetStrikeMarchEvents(),function(_,strikeMarchEvent)
		return strikeMarchEvent:GetPlayerRole() == strikeMarchEvent.MARCH_EVENT_PLAYER_ROLE.SENDER 
	end)
	self:Handler2BelvedereEntity(my_events,marching_strike_events,BelvedereEntity.ENTITY_TYPE.STRIKE_OUT)
	local marching_strike_events_return = LuaUtils:table_filteri(self:GetAlliance():GetStrikeMarchReturnEvents(),function(_,strikeMarchReturnEvent)
		return strikeMarchReturnEvent:GetPlayerRole() == strikeMarchReturnEvent.MARCH_EVENT_PLAYER_ROLE.RECEIVER 
	end)
	self:Handler2BelvedereEntity(my_events,marching_strike_events_return,BelvedereEntity.ENTITY_TYPE.STRIKE_RETURN)
	return my_events
end

function AllianceBelvedere:Reset()
	self:ClearAllListener()
end

function AllianceBelvedere:IsMeBeAttacked()
	local other_events = self:GetOtherEvents()
	for __,v in ipairs(other_events) do
		local march_type = v:WithObject():MarchType()
		if march_type ~= 'helpDefence' then
			return true
		end
	end
	return false
end

--返回是否有瞭望塔事件发生 和瞭望塔事件数量(包含协防事件)
function AllianceBelvedere:HasEvents()
	if self:GetAlliance():IsDefault() then return false,0 end
	local hasMyEvents,my_count = self:HasMyEvents()
	local hasOtherEvents,other_count = self:HasOtherEvents()
	return hasMyEvents or hasOtherEvents,my_count + other_count
end

--返回是否有"我的事件"及数量
function  AllianceBelvedere:HasMyEvents()
	local count = #self:GetMyEvents()
	return count > 0,count
end
--返回是否有"来袭事件"及数量
function AllianceBelvedere:HasOtherEvents()
	local other_count = #self:GetOtherEvents()
	return other_count > 0,other_count
end

function AllianceBelvedere:OnAttackMarchEventTimerChanged(attackMarchEvent)
	if attackMarchEvent:GetPlayerRole() == attackMarchEvent.MARCH_EVENT_PLAYER_ROLE.RECEIVER then
		local showComming = false
		self:NotifyListeneOnType(self.LISTEN_TYPE.CheckNotHaveTheEventIf,function(listener)
			if listener.CheckNotHaveTheEventIf then
				showComming = listener:CheckNotHaveTheEventIf(attackMarchEvent)
			end
		end)
		if showComming then
			self:NotifyCommingDataChanged()
		else
			self:CallEventsChangedListeners(AllianceBelvedere.LISTEN_TYPE.OnAttackMarchEventTimerChanged,{attackMarchEvent})
		end
	elseif attackMarchEvent:GetPlayerRole() == attackMarchEvent.MARCH_EVENT_PLAYER_ROLE.SENDER then
		self:CallEventsChangedListeners(AllianceBelvedere.LISTEN_TYPE.OnAttackMarchEventTimerChanged,{attackMarchEvent})
	end
end


function AllianceBelvedere:OnAttackMarchEventDataChanged(changed_map)
	if self:GetAlliance():IsMyAlliance() then --my alliance
		local showMarch,showComming = false,false
		for _,data in pairs(changed_map) do
			if showMarch or showComming then break end
			for _,marchEvent in ipairs(data) do
				if marchEvent:GetPlayerRole() == marchEvent.MARCH_EVENT_PLAYER_ROLE.RECEIVER then
					if marchEvent:MarchType() == "helpDefence" then 
						showComming = true
						break
					elseif marchEvent:GetTime() <= self:GetWarningTime() then
						showComming = true
						break
					end
				end
				if marchEvent:GetPlayerRole() == marchEvent.MARCH_EVENT_PLAYER_ROLE.SENDER then
					showMarch = true
					break
				end
			end
		end
		if showMarch then
			self:NotifyMarchDataChanged()
		end
		if showComming then
			self:NotifyCommingDataChanged()
		end
	else
		self:CallEventsChangedListeners(AllianceBelvedere.LISTEN_TYPE.OnAttackMarchEventDataChanged,{changed_map})
	end
end

function AllianceBelvedere:OnAttackMarchReturnEventDataChanged(changed_map)
	if not self:GetAlliance():IsMyAlliance() then return end
	local showMarch = false 
	for _,data in pairs(changed_map) do
		if showMarch then break end
		for _,marchReturnEvent in ipairs(data) do
			if marchReturnEvent:GetPlayerRole() == marchReturnEvent.MARCH_EVENT_PLAYER_ROLE.RECEIVER then
				showMarch = true
				break
			end
		end
	end
	if showMarch then
		self:NotifyMarchDataChanged()
	end
end
function AllianceBelvedere:OnStrikeMarchEventDataChanged(changed_map)
	if self:GetAlliance():IsMyAlliance() then --my alliance
		local showMarch,showComming = false,false
		for _,data in pairs(changed_map) do
			if showMarch or showComming then break end
			for _,strikeMarchEvent in ipairs(data) do
				if strikeMarchEvent:GetPlayerRole() == strikeMarchEvent.MARCH_EVENT_PLAYER_ROLE.RECEIVER and strikeMarchEvent:GetTime() <= self:GetWarningTime() then
					showComming = true
					break
				end
				if strikeMarchEvent:GetPlayerRole() == strikeMarchEvent.MARCH_EVENT_PLAYER_ROLE.SENDER then
					showMarch = true
					break
				end
			end
		end
		if showMarch then
			self:NotifyMarchDataChanged()
		end
		if showComming then
			self:NotifyCommingDataChanged()
		end
	else
		self:CallEventsChangedListeners(AllianceBelvedere.LISTEN_TYPE.OnStrikeMarchEventDataChanged,{changed_map})
	end
end
function AllianceBelvedere:OnStrikeMarchReturnEventDataChanged(changed_map)
	if not self:GetAlliance():IsMyAlliance() then return end
	local showMarch = false 
	for _,data in pairs(changed_map) do
		if showMarch then break end
		for _,strikeMarchReturnEvent in ipairs(data) do
			if strikeMarchReturnEvent:GetPlayerRole() == strikeMarchReturnEvent.MARCH_EVENT_PLAYER_ROLE.RECEIVER then
				showMarch = true
				break
			end
		end
	end
	if showMarch then
		self:NotifyMarchDataChanged()
	end
end
function AllianceBelvedere:OnVillageEventsDataChanged(changed_map)
	if not self:GetAlliance():IsMyAlliance() then return end
	local showMarch = false 
	for _,data in pairs(changed_map) do
		if showMarch then break end
		for _,villageEvent in ipairs(data) do
			if villageEvent:GetPlayerRole() == villageEvent.EVENT_PLAYER_ROLE.Me then
				showMarch = true
				break
			end
		end
	end
	if showMarch then
		self:NotifyMarchDataChanged()
	end
end

function AllianceBelvedere:OnVillageEventTimer(villageEvent,left_resource)
	if not self:GetAlliance():IsMyAlliance() then return end
	if villageEvent:GetPlayerRole() ~= villageEvent.EVENT_PLAYER_ROLE.Me then return end
	self:CallEventsChangedListeners(AllianceBelvedere.LISTEN_TYPE.OnVillageEventTimer,{villageEvent,left_resource})
end

function AllianceBelvedere:OnShrineEventsChanged(changed_map)
	if self:GetAlliance():IsMyAlliance() then
		self:NotifyMarchDataChanged()
	end
end

function AllianceBelvedere:OnShrineEventsRefresh()
	self:OnShrineEventsChanged()
end

function AllianceBelvedere:OnFightEventTimerChanged(fightEvent)
	if self:GetAlliance():IsMyAlliance() then
		self:CallEventsChangedListeners(AllianceBelvedere.LISTEN_TYPE.OnFightEventTimerChanged,{fightEvent}) 
	end
end
-- 刷新事件 我方联盟刷新会发送 OnMarchDataChanged 敌方联盟刷新会发送OnCommingDataChanged
function AllianceBelvedere:OnMarchEventRefreshed(changed_event_name)
	if self:GetAlliance():IsMyAlliance() then
		self:NotifyMarchDataChanged()
	else
		Alliance_Manager:GetMyAlliance():GetAllianceBelvedere():NotifyCommingDataChanged()
	end
end

function AllianceBelvedere:NotifyMarchDataChanged()
	self:CallEventsChangedListeners(AllianceBelvedere.LISTEN_TYPE.OnMarchDataChanged,{})
end

function AllianceBelvedere:NotifyCommingDataChanged()
	self:CallEventsChangedListeners(AllianceBelvedere.LISTEN_TYPE.OnCommingDataChanged,{})
end

function AllianceBelvedere:CallEventsChangedListeners(LISTEN_TYPE,args)
    self:NotifyListeneOnType(LISTEN_TYPE, function(listener)
        listener[AllianceBelvedere.LISTEN_TYPE[LISTEN_TYPE]](listener,unpack(args))
    end)
end

--- 瞭望塔等级功能
------------------------------------------------------------------------------------
function AllianceBelvedere:GetWatchTowerLevel()
	return City:GetWatchTowerLevel()
end

--获取显示进攻事件的最大时间
function AllianceBelvedere:GetWarningTime(level)
	local watcher_level = level or self:GetWatchTowerLevel()
	local seconds = client_config_watchTower[watcher_level].waringMinute * 60
	print(string.format("AllianceBelvedere:GetWarningTime--->%s seconds",seconds))
	return seconds
end
--显示来袭的玩家名称
function AllianceBelvedere:CanDisplayCommingPlayerName(level)
	local watcher_level = level or self:GetWatchTowerLevel()
	return watcher_level >= 2
end
--------------------------------废弃
function AllianceBelvedere:CanDisplayCommingCityName(level)
	local watcher_level = level or self:GetWatchTowerLevel()
	return watcher_level >= 4
end

--显示敌方的行军路线 除去攻击我的事件
function AllianceBelvedere:CanDisplayEnemyAllianceMarchEventNotAttackMe(level)
	local watcher_level = level or self:GetWatchTowerLevel()
	return watcher_level >= 4
end

--显示龙的类型 
function AllianceBelvedere:CanDisplayCommingDragonType(level)
	local watcher_level = level or self:GetWatchTowerLevel()
	return watcher_level >= 6
end
--显示详情按钮
function AllianceBelvedere:CanViewEventDetail(level)
	local watcher_level = level or self:GetWatchTowerLevel()
	return watcher_level >= 10
end
--区域地图能查看敌方城市
function AllianceBelvedere:CanEnterEnemyCity(level)
	local watcher_level = level or self:GetWatchTowerLevel()
	return watcher_level >= 8
end

return AllianceBelvedere
