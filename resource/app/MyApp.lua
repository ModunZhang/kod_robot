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
local CityBuildApi = import(".CityBuildApi")
local OtherApi = import(".OtherApi")
local DragonApi = import(".DragonApi")
local DaliyApi = import(".DaliyApi")
local AllianceApi = import(".AllianceApi")
local AllianceFightApi = import(".AllianceFightApi")

local intInit = GameDatas.PlayerInitData.intInit

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
    end):next(function()
        print("登录游戏成功!")
        return NetManager:getSendGlobalMsgPromise("buildinglevel 1 40")
    end):catch(function(err)
        dump(err:reason())
        threadExit()
    end)
end

running = true
function MyApp:setRun()
    running = true
end
local function setRun()
    app:setRun()
end

-- -- 联盟方法组
-- local function JoinAlliance()
--     if Alliance_Manager:GetMyAlliance():IsDefault() then
--         NetManager:getFetchCanDirectJoinAlliancesPromise():done(function(response)
--             dump(response)
--             if not response.msg or not response.msg.allianceDatas then setRun() return end
--             if response.msg.allianceDatas then
--                 if response.msg.allianceDatas.members == response.msg.allianceDatas.membersMax then
--                     setRun()
--                     return
--                 end
--                 local find_id = response.msg.allianceDatas[math.random(#response.msg.allianceDatas)].id
--                 local p = app:JoinAlliance(find_id)
--                 if p then
--                     p:always(setRun)
--                 else
--                     setRun()
--                 end
--             end
--         end)
--     else
--         setRun()
--     end
-- end
-- local function CreateAlliance()
--     local p = app:CreateAlliance()
--     if p then
--         p:always(setRun)
--     else
--         setRun()
--     end
-- end
-- local function getQuitAlliancePromise()
--     local p = app:getQuitAlliancePromise()
--     if p then
--         p:always(setRun)
--     else
--         setRun()
--     end
-- end
-- 基础城建方法组
-- local function Recommend()
--     local p = app:Recommend()
--     if p then
--         p:always(setRun)
--     else
--         setRun()
--     end
-- end
-- local function BuildRandomHouse()
--     local p = app:BuildRandomHouse()
--     if p then
--         p:always(setRun)
--     else
--         setRun()
--     end
-- end
-- local function UnlockBuilding()
--     local p = app:UnlockBuilding()
--     if p then
--         p:always(setRun)
--     else
--         setRun()
--     end
-- end
-- local function SetUserName()
--     local p = app:SetUserName()
--     if p then
--         p:always(setRun)
--     else
--         setRun()
--     end
-- end

-- -- 散乱操作方法组
-- local function SetCityTerrain()
--     local p = app:SetCityTerrain()
--     if p then
--         p:always(setRun)
--     else
--         setRun()
--     end
-- end
-- local function SwitchBuilding()
--     local p = app:SwitchBuilding()
--     if p then
--         p:always(setRun)
--     else
--         setRun()
--     end
-- end

-- local function SetPlayerIcon()
--     local p = app:SetPlayerIcon()
--     if p then
--         p:always(setRun)
--     else
--         setRun()
--     end
-- end
-- local function Gacha()
--     local p = app:Gacha()
--     if p then
--         p:always(setRun)
--     else
--         setRun()
--     end
-- end
-- 龙方法组
-- local function HatchDragon()
--     local p = app:HatchDragon()
--     if p then
--         p:always(setRun)
--     else
--         setRun()
--     end
-- end
-- local function SetDefenceDragon()
--     local p = app:SetDefenceDragon()
--     if p then
--         p:always(setRun)
--     else
--         setRun()
--     end
-- end

--联盟战方法组
-- local function TreatSoldiers()
--     local p = app:TreatSoldiers()
--     if p then
--         p:always(setRun)
--     else
--         setRun()
--     end
-- end
-- local function RecruitNormalSoldier()
--     local p = app:RecruitNormalSoldier()
--     if p then
--         p:always(setRun)
--     else
--         setRun()
--     end
-- end
-- local function StartAllianceWar()
--     local p = app:StartAllianceWar()
--     if p then
--         p:always(setRun)
--     else
--         setRun()
--     end
-- end
-- local function AttackCity()
--     local p = app:AttackCity()
--     if p then
--         p:always(setRun)
--     else
--         setRun()
--     end
-- end
-- local function SpeedUpMarchEvent()
--     local p = app:SpeedUpMarchEvent()
--     if p then
--         p:always(setRun)
--     else
--         setRun()
--     end
-- end

--日常科技升级，任务方法组
-- local function DailyQuests()
--     local p = app:DailyQuests()
--     if p then
--         p:always(setRun)
--     else
--         setRun()
--     end
-- end
-- local function MilitaryTech()
--     local p = app:MilitaryTech()
--     if p then
--         p:always(setRun)
--     else
--         setRun()
--     end
-- end

func_map = {
    -- 基础城建方法组
    CityBuildApi,
    -- 散乱操作方法组
    OtherApi,
    -- 联盟方法组
    AllianceApi,
    -- 龙方法组
    DragonApi,
    -- 日常科技升级，任务方法组
    DaliyApi,
    -- 联盟战方法组
    AllianceFightApi,
}
api_group_index = 1
api_index = 1
function MyApp:RunAI()
    print("RunAI robot id:", device.getOpenUDID())
    if running then
        running = false
        local group = func_map[api_group_index]
        group[api_index]()
        print("run func index",api_group_index,api_index)
        if (api_index + 1) > #group then
            api_group_index = math.random(#func_map)
            api_index = 1
            print("api_group_index===",api_group_index)
        else
            api_index = api_index + 1
        end
    end
end

-- 辅助方法

-- 建筑是否解锁
function MyApp:IsBuildingUnLocked(location_id)
    local tile = City:GetTileByLocationId(location_id)
    local b_x,b_y =tile.x,tile.y
    -- 建筑是否已解锁
    return City:IsUnLockedAtIndex(b_x,b_y)
end


-- function MyApp:Recommend()
--     if #City:GetUpgradingBuildings() == 0 then
--         return self:UpgradingBuilding(City:GetHighestBuildingByType(City:GetRecommendTask():BuildingType()))
--     end
-- end

-- local house_type = {
--     "dwelling",
--     "woodcutter",
--     "farmer",
--     "quarrier",
--     "miner",
--     "miner",
--     "miner",
--     "miner",
-- }
-- function MyApp:CreateAlliance()
--     if Alliance_Manager:GetMyAlliance():IsDefault() then
--         local name , tag =DataUtils:randomAllianceNameTag()
--         local random = math.random(3)
--         local tmp = {"desert","iceField","grassLand"}
--         local terrian = tmp[random]
--         print("创建联盟")
--         return NetManager:getCreateAlliancePromise(name,tag,"all",terrian,Flag:RandomFlag():EncodeToJson())
--     end
-- end
-- function MyApp:JoinAlliance(id)
--     if id then
--         print("加入联盟：",id)
--         return NetManager:getJoinAllianceDirectlyPromise(id)
--     end
-- end
-- function MyApp:getQuitAlliancePromise()
--     if not Alliance_Manager:GetMyAlliance():IsDefault() and
--         Alliance_Manager:GetMyAlliance():Status() ~= "prepare" and
--         Alliance_Manager:GetMyAlliance():Status() ~= "fight" then
--         return NetManager:getQuitAlliancePromise()
--     end
-- end
-- function MyApp:UnlockBuilding()
--     for i,v in ipairs(GameDatas.Buildings.buildings) do
--         if v.location<21 then
--             local unlock_building = City:GetBuildingByLocationId(v.location)
--             local tile = City:GetTileByLocationId(v.location)

--             local b_x,b_y =tile.x,tile.y
--             -- 建筑是否可解锁
--             local canUnlock = City:IsTileCanbeUnlockAt(b_x,b_y)
--             if canUnlock then
--                 return app:UpgradingBuilding(unlock_building)
--             end
--         end
--     end
-- end

-- function MyApp:UpgradingBuilding(building)
--     local tile = City:GetTileWhichBuildingBelongs(building)
--     local location_id = tile.location_id
--     if building:IsAbleToUpgrade(true) == nil then
--         if building:IsHouse() then
--             local sub_location_id = tile:GetBuildingLocation(building)
--             return NetManager:getInstantUpgradeHouseByLocationPromise(location_id, sub_location_id)
--         elseif building:GetType() == "tower" then
--             return NetManager:getInstantUpgradeTowerPromise()
--         elseif building:GetType() == "wall" then
--             return NetManager:getInstantUpgradeWallByLocationPromise()
--         else
--             return NetManager:getInstantUpgradeBuildingByLocationPromise(location_id)
--         end
--     end
-- end

-- function MyApp:BuildRandomHouse()
--     return self:BuildHouseByType(house_type[math.random(#house_type)]) or
--         self:BuildHouseByType("dwelling")
-- end

-- function MyApp:BuildHouseByType(type_)
--     if City:GetLeftBuildingCountsByType(type_) > 0 then
--         local need_citizen = BuildingRegister[type_].new({building_type = type_, level = 1, finishTime = 0}):GetCitizen()
--         local citizen = City:GetResourceManager():GetPopulationResource():GetNoneAllocatedByTime(self.timer:GetServerTime())
--         if need_citizen <= citizen then
--             for i,v in ipairs(City:GetRuinsNotBeenOccupied()) do
--                 local tile = City:GetTileWhichBuildingBelongs(v)
--                 local location_id = tile.location_id
--                 local sub_location_id = tile:GetBuildingLocation(v)
--                 return NetManager:getCreateHouseByLocationPromise(location_id, sub_location_id, type_)
--             end
--         end
--     end
-- end

-- -- 个人修改地形
-- function MyApp:SetCityTerrain()
--     local rand = math.random(3)
--     if rand == 1 then
--         return NetManager:getChangeToGrassPromise()
--     elseif rand == 2 then
--         return NetManager:getChangeToDesertPromise()
--     else
--         return NetManager:getChangeToIceFieldPromise()
--     end
-- end
-- -- 个人名字修改
-- function MyApp:SetUserName()
--     local name = "机器人"..device.getOpenUDID()
--     if User:Name() ~= name then
--         return NetManager:getBuyAndUseItemPromise("changePlayerName",{["changePlayerName"] = {
--             ["playerName"] = name
--         }})
--     end
-- end

-- -- 设置头像
-- function MyApp:SetPlayerIcon()
--     local icon_key = math.random(11)
--     local can_set = false
--     -- 前六个默认解锁
--     if icon_key < 7 then
--         can_set = true
--     end
--     if icon_key == 7 then -- 刺客
--         can_set = User:Kill() >= 1000000
--     elseif icon_key == 8 then -- 将军
--         can_set = User:Power() >= 1000000
--     elseif icon_key == 9 then -- 术士
--         can_set = User:GetVipLevel() == 10
--     elseif icon_key == 10 then -- 贵妇
--         can_set = City:GetFirstBuildingByType("keep"):GetLevel() >= 40
--     elseif icon_key == 11 then -- 旧神
--         can_set = User:GetPVEDatabase():GetMapByIndex(3):IsComplete()
--     end
--     if can_set then
--         return NetManager:getSetPlayerIconPromise(icon_key)
--     end
-- end

-- --转换生产建筑类型
-- function MyApp:SwitchBuilding()
--     local location_id = math.random(10,13)
--     -- 建筑是否已解锁
--     if not self:IsBuildingUnLocked(location_id) then
--         return
--     end
--     local current_building = City:GetBuildingByLocationId(location_id)
--     if City:GetUser():GetGemResource():GetValue() < intInit.switchProductionBuilding.value then
--         return
--     elseif (City:GetMaxHouseCanBeBuilt(current_building:GetHouseType())-current_building:GetMaxHouseNum())<#City:GetBuildingByType(current_building:GetHouseType()) then
--         return
--     elseif current_building:IsUpgrading() then
--         return
--     end
--     local switch_to_building_type
--     local types = {
--         "foundry",
--         "stoneMason",
--         "lumbermill",
--         "mill",
--     }
--     while switch_to_building_type == current_building:GetType() or not switch_to_building_type do
--         switch_to_building_type = types[math.random(4)]
--     end
--     local config
--     for i,v in ipairs(GameDatas.Buildings.buildings) do
--         if v.name == switch_to_building_type then
--             config = v
--         end
--     end
--     -- 等级大于5级时有升级前置条件
--     if current_building:GetLevel()>5 then
--         local configParams = string.split(config.preCondition,"_")
--         local preType = configParams[1]
--         local preName = configParams[2]
--         local preLevel = tonumber(configParams[3])
--         local limit
--         if preType == "building" then
--             local find_buildings = City:GetBuildingByType(preName)
--             for i,v in ipairs(find_buildings) do
--                 if v:GetLevel()>=current_building:GetLevel()+preLevel then
--                     limit = true
--                 end
--             end
--         else
--             City:IteratorDecoratorBuildingsByFunc(function (index,house)
--                 if house:GetType() == preName and house:GetLevel()>=current_building:GetLevel()+preLevel then
--                     limit = true
--                 end
--             end)
--         end
--         if not limit then
--             return
--         end
--     end
--     print("SwitchBuilding ",current_building:GetType()," to ",switch_to_building_type)
--     return NetManager:getSwitchBuildingPromise(location_id,switch_to_building_type)
-- end
-- -- 抽奖
-- function MyApp:Gacha()
--     local normal_gacha = math.random(2) == 2
--     if normal_gacha then
--         if User:GetOddFreeNormalGachaCount() > 0
--             or self.city:GetResourceManager():GetCasinoTokenResource():GetValue() >= intInit.casinoTokenNeededPerNormalGacha.value then
--             return NetManager:getNormalGachaPromise()
--         end
--     else
--         if self.city:GetResourceManager():GetCasinoTokenResource():GetValue() >= intInit.casinoTokenNeededPerAdvancedGacha.value then
--             return NetManager:getAdvancedGachaPromise()
--         end
--     end
-- end
-- -- 治疗士兵
-- function MyApp:TreatSoldiers()
--     local soldiers = {}
--     local soldier_map = City:GetSoldierManager():GetTreatSoldierMap()
--     for k,v in pairs(soldier_map) do
--         if v > 0 then
--             table.insert(soldiers, {name = k, count = v})
--         end
--     end
--     if #soldiers < 1 then
--         return
--     end
--     local instant = math.random(2) == 1
--     if instant then
--         return NetManager:getInstantTreatSoldiersPromise(soldiers)
--     else
--         return NetManager:getTreatSoldiersPromise(soldiers)
--     end
-- end
-- -- 每日任务测试
-- function MyApp:DailyQuests()
--     -- 市政厅是否已解锁
--     if not self:IsBuildingUnLocked(15) then
--         return
--     end
--     -- 获取每日任务,若达到刷新时间则刷新不返回任务
--     local quests = User:GetDailyQuests()
--     -- 没有任务则为刷新
--     if not quests then return end
--     -- 检查是否有已经开始的任务
--     local started_quest
--     for i,q in ipairs(quests) do
--         if q.finishTime then
--             started_quest = q
--             dump(q,"开始了的任务")
--             break
--         end
--     end
--     if started_quest then
--         -- 任务已经完成,领取奖励
--         if started_quest.finishTime == 0 then
--             print("任务已经完成,领取奖励")
--             return NetManager:getDailyQeustRewardPromise(started_quest.id)
--         else
--             -- TODO 加速任务
--             return
--         end
--     end
--     -- 开始一个任务
--     local to_start_quest
--     for i,q in ipairs(quests) do
--         if not q.finishTime then
--             to_start_quest = q
--             break
--         end
--     end
--     -- 任务不是五星则提升一次星级
--     if to_start_quest.star ~= 5 then
--         print("任务不是五星则提升一次星级,开始一个任务")
--         return NetManager:getAddDailyQuestStarPromise(to_start_quest.id):next(function()
--             return NetManager:getStartDailyQuestPromise(to_start_quest.id)
--         end)
--     else
--         print(",开始一个任务")
--         return NetManager:getStartDailyQuestPromise(to_start_quest.id)
--     end
-- end
-- -- 军事科技
-- function MyApp:MilitaryTech()
--     local soldier_manager = City:GetSoldierManager()
--     -- 训练场
--     -- 猎手大厅
--     -- 马厩
--     -- 车间
--     local building_tech_map = {
--         {17 , "trainingGround"},
--         {18 , "hunterHall"},
--         {19 , "stable"},
--         {20 , "workshop"},
--     }
--     for i,map in ipairs(building_tech_map) do
--         local building_index,building_name = map[1] , map[2]
--         if self:IsBuildingUnLocked(building_index) then
--             -- 没有升级事件
--             if not soldier_manager:IsUpgradingMilitaryTech(building_name) then
--                 -- 随机晋升士兵星级或者升级科技
--                 local upgrade_soldier = math.random(10) < 4
--                 if upgrade_soldier then
--                     local soldiers_star = soldier_manager:FindSoldierStarByBuildingType(building_name)
--                     for soldier_type,v in pairs(soldiers_star) do
--                         -- 最大三星
--                         if v < soldier_manager:GetSoldierMaxStar() then
--                             -- 科技点是否满足
--                             local level_up_config =  GameDatas.Soldiers.normal[soldier_type.."_"..(soldier_manager:GetStarBySoldierType(soldier_type)+1)]
--                             local tech_points = soldier_manager:GetTechPointsByType(building_name)
--                             if tech_points<level_up_config.upgradeTechPointNeed then
--                                 return
--                             end
--                             local isFinishNow = math.random(2) == 2
--                             if isFinishNow then
--                                 print("立即晋升士兵：",soldier_type)
--                                 NetManager:getInstantUpgradeSoldierStarPromise(soldier_type)
--                             else
--                                 print("晋升士兵：",soldier_type)
--                                 NetManager:getUpgradeSoldierStarPromise(soldier_type)
--                             end
--                             break
--                         end
--                     end
--                 else
--                     local techs = soldier_manager:FindMilitaryTechsByBuildingType(building_name)
--                     local upgrade_tech = techs[math.random(#techs)]
--                     local upgrade_tech_name = techs[math.random(#techs)]:Name()
--                     if upgrade_tech:Level() < 15 then
--                         -- 立即升级或者普通升级
--                         local isFinishNow = math.random(2) == 2
--                         if isFinishNow then
--                             print("立即升级军事科技：",upgrade_tech_name)
--                             NetManager:getInstantUpgradeMilitaryTechPromise(upgrade_tech_name)
--                         else
--                             print("升级军事科技：",upgrade_tech_name)
--                             NetManager:getUpgradeMilitaryTechPromise(upgrade_tech_name)
--                         end
--                     end
--                 end

--             else
--                 -- 加速军事科技升级
--                 local upgrading_tech = soldier_manager:GetUpgradingMilitaryTech(building_name)
--                 -- 随机使用事件加速道具
--                 local speedUp_item_name = "speedup_"..math.random(8)
--                 print("使用"..speedUp_item_name.."加速"..upgrading_tech:GetEventType().." ,id:",upgrading_tech:Id())
--                 NetManager:getBuyAndUseItemPromise(speedUp_item_name,{[speedUp_item_name] = {
--                     eventType = upgrading_tech:GetEventType(),
--                     eventId = upgrading_tech:Id()
--                 }})
--             end

--         end
--     end
-- end

-- -- 孵化龙
-- function MyApp:HatchDragon()
--     local dragon_manager = City:GetFirstBuildingByType("dragonEyrie"):GetDragonManager()
--     -- 没有已孵化的龙
--     if dragon_manager:NoDragonHated() then
--         local hate_dragon_type = {"redDragon","blueDragon","greenDragon"}
--         local dragon_type = hate_dragon_type[math.random(3)]
--         print("没有已孵化的龙 孵化第一条龙",dragon_type)
--         return NetManager:getHatchDragonPromise(dragon_type)
--     end
--     for __,dragon in pairs(dragon_manager:GetDragons()) do
--         if not dragon:Ishated() then
--             local dragonEvent = dragon_manager:GetDragonEventByDragonType(dragon:Type())
--             if dragonEvent then
--                 -- TODO 加速孵化
--                 print("TODO 加速孵化")
--                 return
--             else
--                 print(" 孵化更多龙",dragon:Type())
--                 return NetManager:getHatchDragonPromise(dragon:Type())
--             end
--         end
--     end
-- end
-- -- 驻防龙
-- function MyApp:SetDefenceDragon()
--     local dragon_manager = City:GetFirstBuildingByType("dragonEyrie"):GetDragonManager()
--     -- 没有已孵化的龙
--     if dragon_manager:NoDragonHated() then
--         return
--     end
--     -- 已经有龙驻防
--     if dragon_manager:GetDefenceDragon() then
--         return
--     end
--     for __,dragon in pairs(dragon_manager:GetDragons()) do
--         if dragon:Ishated() then
--             return NetManager:getSetDefenceDragonPromise(dragon:Type())
--         end
--     end
-- end
-- -- 招募普通士兵
-- function MyApp:RecruitNormalSoldier()
--     -- 兵营是否已解锁
--     if self:IsBuildingUnLocked(5) then
--         local barracks = City:GetFirstBuildingByType("barracks")
--         local unlock_soldiers = {}
--         local level = barracks:GetLevel()

--         for k,v in pairs(barracks:GetUnlockSoldiers()) do
--             if v <= level then
--                 table.insert(unlock_soldiers, k)
--             end
--         end
--         dump(unlock_soldiers)
--         local soldier_type = unlock_soldiers[math.random(#unlock_soldiers)]
--         print("立即招募普通士兵",soldier_type)
--         return NetManager:getInstantRecruitNormalSoldierPromise(soldier_type, 10)
--     end
-- end
-- -- 开启联盟战
-- function MyApp:StartAllianceWar()
--     if not Alliance_Manager:GetMyAlliance():IsDefault() then
--         if Alliance_Manager:GetMyAlliance():Status()~="peace" then
--             return
--         end
--         local isEqualOrGreater = Alliance_Manager:GetMyAlliance():GetMemeberById(User:Id())
--             :IsTitleEqualOrGreaterThan("general")
--         if isEqualOrGreater then
--             print("开启联盟战")
--             return NetManager:getFindAllianceToFightPromose()
--         end
--     end
-- end
-- -- 攻打敌方城市
-- function MyApp:AttackCity()
--     if not Alliance_Manager:GetMyAlliance():IsDefault() then
--         if Alliance_Manager:GetMyAlliance():Status()=="fight" then
--             if not Alliance_Manager:GetMyAlliance():GetAllianceBelvedere():IsReachEventLimit() then
--                 local allMembers = Alliance_Manager:GetEnemyAlliance():GetAllMembers()
--                 local can_attack = {}
--                 for k,v in pairs(allMembers) do
--                     if not v:IsProtected() then
--                         table.insert(can_attack, v)
--                     end
--                 end
--                 local dragon_manager = City:GetFirstBuildingByType("dragonEyrie"):GetDragonManager()
--                 local dragonType
--                 for k,dragon in pairs(dragon_manager:GetDragons()) do
--                     if dragon:Status()=="free" and not dragon:IsDead() then
--                         if dragon:GetWeight() > dragonWidget then
--                             dragonWidget = dragon:GetWeight()
--                             dragonType = k
--                         end
--                     end
--                 end
--                 local fight_soldiers = {}
--                 for k,v in pairs(City:GetSoldierManager():GetSoldierMap()) do
--                     if v > 0 then
--                         table.insert(fight_soldiers,{ name = k,count = math.random(v)})
--                     end
--                 end
--                 if #fight_soldiers > 0 and dragonType and #can_attack > 0 then
--                     local attack_target = can_attack[math.random(#can_attack)]
--                     print("攻打敌方城市,敌方名字:",attack_target:Name())
--                     print("攻打敌方城市,派出龙:",dragon)
--                     dump(fight_soldiers,"攻打敌方城市,派出士兵")
--                     return NetManager:getAttackPlayerCityPromise(dragon, fight_soldiers, attack_target:Id())
--                 end
--             end
--         end


--     end
-- end
-- -- 加速自己所有行军事件
-- function  MyApp:SpeedUpMarchEvent()
--     -- 有正在行军的则加速
--     local my_events = Alliance_Manager:GetMyAlliance():GetAllianceBelvedere():GetMyEvents()
--     for k,march_event in pairs(my_events) do
--         if march_event:WithObject():GetTime() > 10 then
--             print("加速行军事件",march_event:WithObject():Id(),march_event:GetEventServerType(),march_event:WithObject():GetTime())
--             NetManager:getBuyAndUseItemPromise("warSpeedupClass_2",{
--                 ["warSpeedupClass_2"]={
--                     eventType = march_event:GetEventServerType(),
--                     eventId=march_event:WithObject():Id()
--                 }
--             })
--         end
--     end
-- end

return MyApp





































