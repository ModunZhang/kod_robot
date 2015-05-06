require("app.utils.LuaUtils")
require("app.utils.GameUtils")
require("app.utils.DataUtils")
require("app.service.NetManager")
require("app.service.DataManager")
local BuildingRegister = import("app.entity.BuildingRegister")
local Flag = import("app.entity.Flag")
local promise = import("app.utils.promise")
local GameDefautlt = import("app.utils.GameDefautlt")
local ChatManager = import("app.entity.ChatManager")
local Timer = import('.utils.Timer')

_ = function(...) return ... end
local MyApp = class("MyApp")
function MyApp:GetAudioManager()
    return {PlayeEffectSoundWithKey = function ( ... )
    end}
end

function MyApp:ctor()
    NetManager:init()
    self.GameDefautlt_ = GameDefautlt.new()
    self.ChatManager_  = ChatManager.new(self:GetGameDefautlt())
    self.timer = Timer.new()
    app = self
    app.GetPushManager = function()
        return {
            CancelAll = function() end
        }
    end
end
function MyApp:GetGameDefautlt()
    return self.GameDefautlt_
end
function MyApp:GetChatManager()
    return self.ChatManager_
end

function MyApp:run()
    local file = io.open("log", "a+")
    if file then
        file:write("login : "..device.getOpenUDID().."\n")
        io.close(file)
    end
    NetManager:getConnectGateServerPromise():next(function()
        return NetManager:getLogicServerInfoPromise()
    end):next(function()
        return NetManager:getConnectLogicServerPromise()
    end):next(function()
        return NetManager:getLoginPromise(device.getOpenUDID())
    end):next(function()
        print("登录游戏成功!")
        return NetManager:getSendGlobalMsgPromise("resources gem 99999999999")
    end):catch(function(err)
        dump(err:reason())
        threadExit()
    end)
end

running = true
local function setRun()
    running = true
end
local function JoinAlliance()
    local p = app:JoinAlliance()
    if p then
        p:always(setRun)
    else
        setRun()
    end
end
local function getQuitAlliancePromise()
    local p = app:getQuitAlliancePromise()
    if p then
        p:always(setRun)
    else
        setRun()
    end
end
local function Recommend()
    local p = app:Recommend()
    if p then
        p:always(setRun)
    else
        setRun()
    end
end
local function BuildRandomHouse()
    local p = app:BuildRandomHouse()
    if p then
        p:always(setRun)
    else
        setRun()
    end
end
local function UnlockBuilding()
    local p = app:UnlockBuilding()
    if p then
        p:always(setRun)
    else
        setRun()
    end
end
local function SetCityTerrain()
    local p = app:SetCityTerrain()
    if p then
        p:always(setRun)
    else
        setRun()
    end
end
local function SwitchBuilding()
    local p = app:SwitchBuilding()
    if p then
        p:always(setRun)
    else
        setRun()
    end
end
local function TreatSoldiers()
    local p = app:TreatSoldiers()
    if p then
        p:always(setRun)
    else
        setRun()
    end
end
local function DailyQuests()
    local p = app:DailyQuests()
    if p then
        p:always(setRun)
    else
        setRun()
    end
end
local function SetPlayerIcon()
    local p = app:SetPlayerIcon()
    if p then
        p:always(setRun)
    else
        setRun()
    end
end
local function Fight()
    local p = app:Fight()
    if p then
        p:always(setRun)
    else
        setRun()
    end
end

local function idle()
    setRun()
end
func_map = {
    idle,
    -- getQuitAlliancePromise,
    -- JoinAlliance,
    BuildRandomHouse,
    UnlockBuilding,
    Recommend,
    -- SwitchBuilding,
    -- TreatSoldiers,
    -- SetCityTerrain,
    SetPlayerIcon,
    -- DailyQuests,
    Fight,
}
api_index = 1
function MyApp:RunAI()
    print("RunAI robot id:", device.getOpenUDID())
    running = false
    func_map[api_index]()
    api_index = (api_index + 1) > #func_map and 1 or (api_index + 1)
end


function MyApp:Recommend()
    if #City:GetUpgradingBuildings() == 0 then
        return self:UpgradingBuilding(City:GetHighestBuildingByType(City:GetRecommendTask():BuildingType()))
    end
end

local house_type = {
    "dwelling",
    "woodcutter",
    "farmer",
    "quarrier",
    "miner",
    "miner",
    "miner",
    "miner",
}
function MyApp:CreateAlliance()
    if Alliance_Manager:GetMyAlliance():IsDefault() then
        local name , tag =DataUtils:randomAllianceNameTag()
        local random = math.random(3)
        local tmp = {"desert","iceField","grassLand"}
        local terrian = tmp[random]
        return NetManager:getCreateAlliancePromise(name,tag,"all",terrian,Flag:RandomFlag():EncodeToJson())
    end
end
function MyApp:JoinAlliance(id)
    if Alliance_Manager:GetMyAlliance():IsDefault() then
        if id then
            return NetManager:getJoinAllianceDirectlyPromise(id)
        else
            local find_id
            NetManager:getFetchCanDirectJoinAlliancesPromise():done(function(response)
                if not response.msg or not response.msg.allianceDatas then return end
                if response.msg.allianceDatas then
                    find_id = response.msg.allianceDatas[math.random(#response.msg.allianceDatas)].id
                end
            end)
            if find_id then
                return self:JoinAlliance(find_id)
            end
        end
    end
end
function MyApp:getQuitAlliancePromise()
    if not Alliance_Manager:GetMyAlliance():IsDefault() and
        Alliance_Manager:GetMyAlliance():Status() ~= "prepare" and
        Alliance_Manager:GetMyAlliance():Status() ~= "fight" then
        return NetManager:getQuitAlliancePromise()
    end
end
function MyApp:UnlockBuilding()
    for i,v in ipairs(GameDatas.Buildings.buildings) do
        if v.location<21 then
            local unlock_building = City:GetBuildingByLocationId(v.location)
            local tile = City:GetTileByLocationId(v.location)

            local b_x,b_y =tile.x,tile.y
            -- 建筑是否可解锁
            local canUnlock = City:IsTileCanbeUnlockAt(b_x,b_y)
            if canUnlock then
                return app:UpgradingBuilding(unlock_building)
            end
        end
    end
end

function MyApp:UpgradingBuilding(building)
    local tile = City:GetTileWhichBuildingBelongs(building)
    local location_id = tile.location_id
    if building:IsAbleToUpgrade(true) == nil then
        if building:IsHouse() then
            local sub_location_id = tile:GetBuildingLocation(building)
            return NetManager:getInstantUpgradeHouseByLocationPromise(location_id, sub_location_id)
        elseif building:GetType() == "tower" then
            return NetManager:getInstantUpgradeTowerPromise()
        elseif building:GetType() == "wall" then
            return NetManager:getInstantUpgradeWallByLocationPromise()
        else
            return NetManager:getInstantUpgradeBuildingByLocationPromise(location_id)
        end
    end
end

function MyApp:BuildRandomHouse()
    return self:BuildHouseByType(house_type[math.random(#house_type)]) or
        self:BuildHouseByType("dwelling")
end

function MyApp:BuildHouseByType(type_)
    if City:GetLeftBuildingCountsByType(type_) > 0 then
        local need_citizen = BuildingRegister[type_].new({building_type = type_, level = 1, finishTime = 0}):GetCitizen()
        local citizen = City:GetResourceManager():GetPopulationResource():GetNoneAllocatedByTime(self.timer:GetServerTime())
        if need_citizen <= citizen then
            for i,v in ipairs(City:GetRuinsNotBeenOccupied()) do
                local tile = City:GetTileWhichBuildingBelongs(v)
                local location_id = tile.location_id
                local sub_location_id = tile:GetBuildingLocation(v)
                return NetManager:getCreateHouseByLocationPromise(location_id, sub_location_id, type_)
            end
        end
    end
end

-- 个人修改地形
function MyApp:SetCityTerrain()
    local rand = math.random(3)
    if rand == 1 then
        return NetManager:getChangeToGrassPromise()
    elseif rand == 2 then
        return NetManager:getChangeToDesertPromise()
    else
        return NetManager:getChangeToIceFieldPromise()
    end
end

-- 设置头像
function MyApp:SetPlayerIcon()
    local icon_key = math.random(11)
    local can_set = false
    -- 前六个默认解锁
    if icon_key < 7 then
        can_set = true
    end
    if icon_key == 7 then -- 刺客
        can_set = User:Kill() >= 1000000
    elseif icon_key == 8 then -- 将军
        can_set = User:Power() >= 1000000
    elseif icon_key == 9 then -- 术士
        can_set = User:GetVipLevel() == 10
    elseif icon_key == 10 then -- 贵妇
        can_set = City:GetFirstBuildingByType("keep"):GetLevel() >= 40
    elseif icon_key == 11 then -- 旧神
        can_set = User:GetPVEDatabase():GetMapByIndex(3):IsComplete()
    end
    if can_set then
        return NetManager:getSetPlayerIconPromise(icon_key)
    end
end

--转换生产建筑类型
function MyApp:SwitchBuilding()
    local location_id = math.random(10,13)
    -- 建筑是否已解锁
    if not self:IsBuildingUnLocked(location_id) then
        return
    end
    local current_building = City:GetBuildingByLocationId(location_id)
    if City:GetUser():GetGemResource():GetValue()<GameDatas.PlayerInitData.intInit.switchProductionBuilding.value then
        return
    elseif (City:GetMaxHouseCanBeBuilt(current_building:GetHouseType())-current_building:GetMaxHouseNum())<#City:GetBuildingByType(current_building:GetHouseType()) then
        return
    elseif current_building:IsUpgrading() then
        return
    end
    local switch_to_building_type
    local types = {
        "foundry",
        "stoneMason",
        "lumbermill",
        "mill",
    }
    while switch_to_building_type == current_building:GetType() or not switch_to_building_type do
        switch_to_building_type = types[math.random(4)]
    end
    local config
    for i,v in ipairs(GameDatas.Buildings.buildings) do
        if v.name == switch_to_building_type then
            config = v
        end
    end
    -- 等级大于5级时有升级前置条件
    if current_building:GetLevel()>5 then
        local configParams = string.split(config.preCondition,"_")
        local preType = configParams[1]
        local preName = configParams[2]
        local preLevel = tonumber(configParams[3])
        local limit
        if preType == "building" then
            local find_buildings = City:GetBuildingByType(preName)
            for i,v in ipairs(find_buildings) do
                if v:GetLevel()>=current_building:GetLevel()+preLevel then
                    limit = true
                end
            end
        else
            City:IteratorDecoratorBuildingsByFunc(function (index,house)
                if house:GetType() == preName and house:GetLevel()>=current_building:GetLevel()+preLevel then
                    limit = true
                end
            end)
        end
        if not limit then
            return
        end
    end
    print("SwitchBuilding ",current_building:GetType()," to ",switch_to_building_type)
    return NetManager:getSwitchBuildingPromise(location_id,switch_to_building_type)
end
-- 治疗士兵
function MyApp:TreatSoldiers()
    local soldiers = {}
    local soldier_map = City:GetSoldierManager():GetTreatSoldierMap()
    for k,v in pairs(soldier_map) do
        if v > 0 then
            table.insert(soldiers, {name = k, count = v})
        end
    end
    if #soldiers < 1 then
        return
    end
    local instant = math.random(2) == 1
    if instant then
        return NetManager:getInstantTreatSoldiersPromise(soldiers)
    else
        return NetManager:getTreatSoldiersPromise(soldiers)
    end
end
-- 每日任务测试
function MyApp:DailyQuests()
    -- 市政厅是否已解锁
    if not self:IsBuildingUnLocked(15) then
        return
    end
    -- 获取每日任务,若达到刷新时间则刷新不返回任务
    local quests = User:GetDailyQuests()
    -- 没有任务则为刷新
    if not quests then return end
    -- 检查是否有已经开始的任务
    local started_quest
    for i,q in ipairs(quests) do
        if q.finishTime then
            started_quest = q
            dump(q,"开始了的任务")
            break
        end
    end
    if started_quest then
        -- 任务已经完成,领取奖励
        if started_quest.finishTime == 0 then
            print("任务已经完成,领取奖励")
            return NetManager:getDailyQeustRewardPromise(started_quest.id)
        else
            -- TODO 加速任务
            return
        end
    end
    -- 开始一个任务
    local to_start_quest
    for i,q in ipairs(quests) do
        if not q.finishTime then
            to_start_quest = q
            break
        end
    end
    -- 任务不是五星则提升一次星级
    if to_start_quest.star ~= 5 then
        print("任务不是五星则提升一次星级,开始一个任务")
        return NetManager:getAddDailyQuestStarPromise(to_start_quest.id):next(function()
            return NetManager:getStartDailyQuestPromise(to_start_quest.id)
        end)
    else
        print(",开始一个任务")
        return NetManager:getStartDailyQuestPromise(to_start_quest.id)
    end
end
-- 加入或创建一个联盟
function MyApp:CreateOrJoinAlliance()
    -- 没有联盟
    if Alliance_Manager:GetMyAlliance():IsDefault() then
        -- 随机加入一个联盟或者创建一个联盟
        local createOrJoin = math.random(2)
        if createOrJoin == 1 then
            print("加入一个联盟")
            return self:JoinAlliance()
        else
            print("创建一个联盟")
            return self:CreateAlliance()
        end
    end
end
-- 孵化龙
function MyApp:HatchDragon()
    local dragon_manager = City:GetFirstBuildingByType("dragonEyrie"):GetDragonManager()
    -- 没有已孵化的龙
    if dragon_manager:NoDragonHated() then
        local hate_dragon_type = {"redDragon","blueDragon","greenDragon"}
        local dragon_type = hate_dragon_type[math.random(3)]
        print("没有已孵化的龙 孵化第一条龙",dragon_type)
        return NetManager:getHatchDragonPromise(dragon_type)
    end
    for __,dragon in pairs(dragon_manager:GetDragons()) do
        if not dragon:Ishated() then
            local dragonEvent = dragon_manager:GetDragonEventByDragonType(dragon:Type())
            if dragonEvent then
                -- TODO 加速孵化
                print("TODO 加速孵化")
                return promise.new()
            else
                print(" 孵化更多龙",dragon:Type())
                return NetManager:getHatchDragonPromise(dragon:Type())
            end
        end
    end
end
-- 招募普通士兵
function MyApp:RecruitNormalSoldier()
    -- 兵营是否已解锁
    if self:IsBuildingUnLocked(5) then
        local barracks = City:GetFirstBuildingByType("barracks")
        local unlock_soldiers = {}
    local level = barracks:GetLevel()
    
        for k,v in pairs(barracks:GetUnlockSoldiers()) do
            if v <= level then
                table.insert(unlock_soldiers, k)
            end
        end
        dump(unlock_soldiers)
        local soldier_type = unlock_soldiers[math.random(#unlock_soldiers)]
        print("立即招募普通士兵",soldier_type)
        return NetManager:getInstantRecruitNormalSoldierPromise(soldier_type, 10)
    end
end
-- 战斗
function MyApp:Fight()
    self:CreateOrJoinAlliance()
    self:HatchDragon()
    return self:RecruitNormalSoldier()
end

-- 辅助方法

-- 建筑是否解锁
function MyApp:IsBuildingUnLocked(location_id)
    local tile = City:GetTileByLocationId(location_id)
    local b_x,b_y =tile.x,tile.y
    -- 建筑是否已解锁
    return City:IsUnLockedAtIndex(b_x,b_y)
end
return MyApp






