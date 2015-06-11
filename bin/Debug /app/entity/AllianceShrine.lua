--
-- Author: Danny He
-- Date: 2014-11-07 15:21:22
--
local config_shrineStage = GameDatas.AllianceInitData.shrineStage
local config_shrine = GameDatas.AllianceBuilding.shrine
local AllianceShrineStage = import(".AllianceShrineStage")
local MultiObserver = import(".MultiObserver")
local property = import("..utils.property")
local AllianceShrine = class("AllianceShrine",MultiObserver)
local AutomaticUpdateResource = import(".AutomaticUpdateResource")
local Enum = import("..utils.Enum")
local ShrineFightEvent = import(".ShrineFightEvent")
local ShrineReport = import(".ShrineReport")
local GameUtils = GameUtils
local Localize = import("..utils.Localize")

AllianceShrine.LISTEN_TYPE = Enum(
	"OnPerceotionChanged",
	"OnNewStageOpened",
	"OnFightEventTimerChanged",
	"OnShrineEventsChanged",
	"OnShrineEventsRefresh",
	"OnShrineReportsChanged"
)

function AllianceShrine:ctor(alliance)
	AllianceShrine.super.ctor(self)
	self.alliance = alliance
	self.shrineEvents = {} -- 关卡事件
	self.shrineReports = {}
	self:loadStages()
end

function AllianceShrine:GetAlliance()
	return self.alliance
end

--配置表加载所有的关卡
function AllianceShrine:loadStages()
	if self.stages then return end
	local stages_ = {}
	local large_key = "1_1"
	table.foreach(config_shrineStage,function(key,config)
		local stage = AllianceShrineStage.new(config) 
		stages_[key] = stage
		if key > large_key then
			large_key = key
		end
	end)
	property(self,"stages",stages_)
	local s,_ = string.find(large_key,"_")
	local ret = string.sub(large_key,1,s-1)
	property(self,"maxCountOfStage",checknumber(ret))
end

function AllianceShrine:Reset()
	table.foreach(self:Stages(),function(stage_name,stage)
		stage:Reset()
	end)
	table.foreach(self.shrineEvents,function(_,shrineEvent)
		shrineEvent:Reset()
	end)
	self.shrineEvents = {}
	self.shrineReports = {}
	self.maxCountOfStage = nil
	self.perception = nil
end

function AllianceShrine:OnPropertyChange(property_name, old_value, value)
end

function AllianceShrine:GetMaxStageFromServer(alliance_data,deltaData)
	local is_fully_update = deltaData == nil
    local is_delta_update = not is_fully_update and deltaData.shrineDatas ~= nil
    if is_fully_update then
		--默认第一关始终打开
		self:GetStatgeByName("1_1"):SetIsLocked(false)
		if alliance_data.shrineDatas then
			local large_key = ""
			for _,v in ipairs(alliance_data.shrineDatas) do
				if v.stageName > large_key and v.maxStar > 0 then
					large_key = v.stageName
				end
				self:GetStatgeByName(v.stageName):SetIsLocked(false)
				self:GetStatgeByName(v.stageName):SetStar(v.maxStar)
			end
			if large_key ~= "" then
				local next_stage = self:GetStageByIndex(self:GetStatgeByName(large_key):Index() + 1)
				if next_stage then
					next_stage:SetIsLocked(false)
				end
			end
		end
	end
	if is_delta_update then
		local large_key = ""
		local max_star = 0
		local changed_map = GameUtils:Handler_DeltaData_Func(
			deltaData.shrineDatas,
			function(data)
				if data.stageName > large_key then
					large_key = data.stageName
					max_star = data.maxStar
				end
				self:GetStatgeByName(data.stageName):SetIsLocked(false)
				self:GetStatgeByName(data.stageName):SetStar(data.maxStar)
				return data
			end,
			function(data)
				if data.stageName > large_key then
					large_key = data.stageName
					max_star = data.maxStar
				end
				self:GetStatgeByName(data.stageName):SetIsLocked(false)
				self:GetStatgeByName(data.stageName):SetStar(data.maxStar)
				return data
			end,
			function(data)
			end
		)
		if large_key ~= "" then
			local next_stage = self:GetStageByIndex(self:GetStatgeByName(large_key):Index() + 1)
			if next_stage and max_star > 0 then
				next_stage:SetIsLocked(false)
			end
		end
		self:OnNewStageOpened(changed_map)
	end
end

function  AllianceShrine:OnNewStageOpened(changed_map)
	self:NotifyListeneOnType(self.LISTEN_TYPE.OnNewStageOpened,function(listener)
		listener.OnNewStageOpened(listener,changed_map)
	end)
end
-- 洞察力 升级后改变生产量(alliance_data.buildings.shrine.level)
function AllianceShrine:InitOrUpdatePerception(alliance_data)
	if not  alliance_data.basicInfo or not alliance_data.basicInfo.perceptionRefreshTime then return end
	if not self.perception then
		local resource_refresh_time = alliance_data.basicInfo.perceptionRefreshTime / 1000.0
		self.perception = AutomaticUpdateResource.new()
		local building
		for i,v in ipairs(alliance_data.buildings) do
			if v.name == "shrine" then
				building = v
				break
			end
		end
		local shire_building = config_shrine[building.level]
        self.perception:SetProductionPerHour(resource_refresh_time,shire_building.pRecoveryPerHour)
        self.perception:SetValueLimit(shire_building.perception)
		self.perception:UpdateResource(resource_refresh_time,alliance_data.basicInfo.perception)
    else
    	if alliance_data.basicInfo and alliance_data.basicInfo.perception then
    		local resource_refresh_time = alliance_data.basicInfo.perceptionRefreshTime / 1000.0
    		local building
			for i,v in ipairs(alliance_data.buildings) do
				if v.name == "shrine" then
					building = v
					break
				end
			end
			if building then
				local shire_building = config_shrine[building.level]
		        self.perception:SetProductionPerHour(resource_refresh_time,shire_building.pRecoveryPerHour)
		        self.perception:SetValueLimit(shire_building.perception)
		    end
			self.perception:UpdateResource(resource_refresh_time,alliance_data.basicInfo.perception)
    	end
	end
end

function AllianceShrine:OnTimer(current_time)
	if self.perception then
		self:OnPerceotionChanged()
	end
	for _,shrineEvent in pairs(self.shrineEvents) do
		shrineEvent:OnTimer(current_time)
	end
end

function AllianceShrine:OnPerceotionChanged()
	self:NotifyListeneOnType(self.LISTEN_TYPE.OnPerceotionChanged,function(listener)
		listener.OnPerceotionChanged(listener)
	end)
end

function AllianceShrine:GetPerceptionResource()
	return self.perception
end

--事件
function AllianceShrine:OnFightEventTimer(fightEvent)
	self:OnFightEventTimerChanged(fightEvent)
end

function AllianceShrine:OnFightEventTimerChanged(fightEvent)
	self:NotifyListeneOnType(self.LISTEN_TYPE.OnFightEventTimerChanged,function(listener)
		listener.OnFightEventTimerChanged(listener,fightEvent)
	end)
	if self:GetAlliance():GetAllianceBelvedere()['OnFightEventTimerChanged'] then
		self:GetAlliance():GetAllianceBelvedere():OnFightEventTimerChanged(fightEvent)
	end
end
--是否有圣地事件
function AllianceShrine:HaveEvent()
	return not LuaUtils:table_empty(self.shrineEvents)
end

function AllianceShrine:RefreshEvents(alliance_data,deltaData,refresh_time)
	local is_fully_update = deltaData == nil
    local is_delta_update = not is_fully_update and deltaData.shrineEvents ~= nil
    if is_fully_update then
		if alliance_data.shrineEvents then
			--清空之前的数据
			table.foreach(self.shrineEvents,function(_,shrineEvent)
				shrineEvent:Reset()
			end)
			self.shrineEvents = {}
			for _,v in ipairs(alliance_data.shrineEvents) do
				local fightEvent = ShrineFightEvent.new()
				fightEvent:Update(v,refresh_time)
				fightEvent:SetStage(self:GetStatgeByName(fightEvent:StageName()))
				self.shrineEvents[fightEvent:Id()] = fightEvent
				fightEvent:AddObserver(self)
			end
			self:OnShrineEventsRefreshed()
		end
	end
	if is_delta_update then
		local change_map = GameUtils:Handler_DeltaData_Func(
			deltaData.shrineEvents
			,function(event) --add
				if not self.shrineEvents[event.id] then
					local fightEvent = ShrineFightEvent.new()
					fightEvent:Update(event,refresh_time)
					fightEvent:SetStage(self:GetStatgeByName(fightEvent:StageName()))
					self.shrineEvents[fightEvent:Id()] = fightEvent
					fightEvent:AddObserver(self)
					return fightEvent
				end
			end
			,function(event) --edit
				local fightEvent = self:GetShrineEventById(event.id)
				if fightEvent then
					fightEvent:Update(event,refresh_time)
				end
				return fightEvent
			end
			,function(event) --remove
				local fightEvent = self:GetShrineEventById(event.id)
				if fightEvent then
					fightEvent:RemoveObserver(self)
					self.shrineEvents[event.id] = nil
					return fightEvent
				end
			end
		)
		self:OnShrineEventsChanged(GameUtils:pack_event_table(change_map))
	end

end

function AllianceShrine:IsNeedRequestReportFromServer()
	return not DataManager:getUserAllianceData().shrineReports
end

function AllianceShrine:OnShrineReportsDataChanged(alliance_data,deltaData)	
	if alliance_data.shrineReports then
		if alliance_data.shrineReports then
			self.shrineReports = {}
			for _,v in ipairs(alliance_data.shrineReports) do
				local report = ShrineReport.new()
				report:Update(v)
				report:SetStage(self:GetStatgeByName(report:StageName()))
				table.insert(self.shrineReports,report)
			end
		end
	end
	self:OnShrineReportsChanged({})
end

function AllianceShrine:OnShrineEventsRefreshed()
	self:NotifyListeneOnType(self.LISTEN_TYPE.OnShrineEventsRefresh,function(listener)
		listener.OnShrineEventsRefresh(listener)
	end)
	if self:GetAlliance():GetAllianceBelvedere()['OnShrineEventsRefresh'] then
		self:GetAlliance():GetAllianceBelvedere():OnShrineEventsRefresh()
	end
end

function AllianceShrine:OnShrineReportsChanged(changed_map)
	self:NotifyListeneOnType(self.LISTEN_TYPE.OnShrineReportsChanged,function(listener)
		listener.OnShrineReportsChanged(listener,changed_map)
	end)
end

function AllianceShrine:OnShrineEventsChanged(changed_map)
	self:NotifyListeneOnType(self.LISTEN_TYPE.OnShrineEventsChanged,function(listener)
		listener.OnShrineEventsChanged(listener,changed_map)
	end)
	if self:GetAlliance():GetAllianceBelvedere()['OnShrineEventsChanged'] then
		self:GetAlliance():GetAllianceBelvedere():OnShrineEventsChanged(changed_map)
	end
end

-- 数据
function AllianceShrine:OnAllianceDataChanged(alliance_data,deltaData,refresh_time)
	self:DecodeObjectsFromJsonAlliance(alliance_data,deltaData,refresh_time)
end

function AllianceShrine:DecodeObjectsFromJsonAlliance(alliance_data,deltaData,refresh_time)
	self:GetMaxStageFromServer(alliance_data,deltaData)
	self:InitOrUpdatePerception(alliance_data)
	self:RefreshEvents(alliance_data,deltaData,refresh_time)
	self:OnShrineReportsDataChanged(alliance_data,deltaData)
end

function AllianceShrine:GetShireObjectFromMap()
	local object
	self:GetAlliance():GetAllianceMap():IteratorAllianceBuildings(function(__,map_obj)
		if map_obj.name == 'shrine' then
			object = map_obj
			return true
		end
	end)
	return object
end

function AllianceShrine:GetPlayerLocation(playerId)
	return self:GetAlliance():GetMemeberById(playerId).location
end

-- api
--------------------------------------------------------------------------------------
--联盟危机

function AllianceShrine:GetShrineReports()
	return self.shrineReports
end

function AllianceShrine:GetShrineEventById(id)
	return self.shrineEvents[id]
end

function AllianceShrine:GetShrineEventByStageName(stage_name)
	for k,event in pairs(self.shrineEvents) do
		if event:Stage():StageName() == stage_name then
			return event
		end
	end
end

function AllianceShrine:GetShrineEvents()
	local r = {}
	for _,v in pairs(self.shrineEvents) do
		table.insert(r,v)
	end
	table.sort( r, function(a,b)
		return a:StartTime() > b:StartTime()
	end)
	return r
end

function AllianceShrine:GetStageByIndex(index)
	for _,v in pairs(self:Stages()) do
		if v:Index() == index then
			return v
		end
	end
	return nil
end

function AllianceShrine:GetStatgeByName(state_name)
	return self:Stages()[state_name]
end


function AllianceShrine:GetStarInfoByMainStage(statge_index)
	local current_star,total_star = 0,0
	for key,stage in pairs(self:Stages()) do
		if tonumber(string.sub(key,1,1)) == statge_index then
			current_star = current_star + stage:Star()
			total_star = total_star + stage:MaxStar()
		end
	end
	return current_star,total_star
end

-- state is number 1~6
function AllianceShrine:GetSubStagesByMainStage(statge_index)
	local tempStages = {}
	for key,stage in pairs(self:Stages()) do
		if tonumber(string.sub(key,1,1)) == statge_index then
			table.insert(tempStages,stage)
		end
	end
	table.sort(tempStages,function(a,b) return a:StageName() < b:StageName() end)
	return tempStages
end

function AllianceShrine:GetMainStageDescName(statge_index)
	return Localize.shrine_desc[string.format("main_stage_%s",statge_index)]
end
-- 限制玩家只能派遣一支部队去圣地
function AllianceShrine:CheckPlayerCanDispathSoldiers(playerId)
	if self:GetShrineEventByPlayerId(playerId) then 
		printInfo("%s","已经驻防的部队检查到玩家信息")
		return false
	end
	--check 正在行军的部队
	for _,marchEvent in ipairs(self:GetAlliance():GetAttackMarchEvents("shrine")) do
		if marchEvent:GetPlayerRole() == marchEvent.MARCH_EVENT_PLAYER_ROLE.SENDER then
			printInfo("%s","正在行军的部队检查到玩家信息")
			return false
		end
	end
	return true
end

function AllianceShrine:CheckSelfCanDispathSoldiers()
	return self:CheckPlayerCanDispathSoldiers(User:Id())
end

function AllianceShrine:GetSelfJoinedShrineEvent()
	return self:GetShrineEventByPlayerId(User:Id())
end

function AllianceShrine:GetShrineEventByPlayerId(playerId)
	for _,shireEvent in ipairs(self:GetShrineEvents()) do
		for _,shireEventPlayer in ipairs(shireEvent:PlayerTroops()) do
			if shireEventPlayer.id == playerId then
				return shireEvent
			end
		end
	end
	return nil
end

return AllianceShrine
