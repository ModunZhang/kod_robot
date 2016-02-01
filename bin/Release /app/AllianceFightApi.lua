--
-- Author: Kenny Dai
-- Date: 2015-05-07 21:24:05
--
local AllianceFightApi = {}

-- 治疗士兵
function AllianceFightApi:TreatSoldiers()
    local soldiers = {}
    local soldier_map = User.woundedSoldiers
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
-- 招募普通士兵
function AllianceFightApi:RecruitNormalSoldier()
    -- 兵营是否已解锁
    if app:IsBuildingUnLocked(5) then
        local barracks = City:GetFirstBuildingByType("barracks")
        local unlock_soldiers = {}
        local level = barracks:GetLevel()

        for k,v in pairs(barracks:GetUnlockSoldiers()) do
            if v <= level then
                table.insert(unlock_soldiers, k)
            end
        end
        local soldier_type = unlock_soldiers[math.random(#unlock_soldiers)]
        print("招募普通士兵",soldier_type)
        if math.random(2) == 2 then
            return NetManager:getRecruitNormalSoldierPromise(soldier_type, 10)
        else
            return NetManager:getInstantRecruitNormalSoldierPromise(soldier_type, 10)
        end
    end
end
-- 招募特殊士兵
function AllianceFightApi:RecruitSpecialSoldier()
    -- 兵营是否已解锁
    if app:IsBuildingUnLocked(5) then
        local barracks = City:GetFirstBuildingByType("barracks")
        local re_time = DataUtils:GetNextRecruitTime()
        if tolua.type(re_time) == "boolean" then
            -- 检查材料是否足够
            local soldier_types = {
                "skeletonWarrior",
                "skeletonArcher",
                "deathKnight",
                "meatWagon",
            }
            local soldier_type = soldier_types[math.random(#soldier_types)]
            local soldier_config = User:GetSoldierConfig(soldier_type)
            local count = 1 -- 招募一个
            local specialMaterials = string.split(soldier_config.specialMaterials,",")
            local is_enough = true
            for k,v in pairs(specialMaterials) do
                local temp = string.split(v, "_")
                local total = User.soldierMaterials[temp[1]]
                if total < count then
                    is_enough = false
                    break
                end
            end
            if is_enough then
                print("招募特殊士兵：",soldier_type)
                if math.random(2) == 2 then
                    return NetManager:getRecruitSpecialSoldierPromise(soldier_type, count)
                else
                    return NetManager:getInstantRecruitSpecialSoldierPromise(soldier_type, count)
                end
            end
        end
    end
end
local function RandomMapIndex()
    return math.random(0,35 * 35 - 1)
end
local function EnterMapIndexAndFunc(mapIndex,func)
    return NetManager:getEnterMapIndexPromise(mapIndex):done(function ( response )
        NetManager:getLeaveMapIndexPromise(mapIndex)
        local allianceData = response.msg.allianceData
        if allianceData and allianceData ~= json.null then
            return func(allianceData)
        end
    end)
end


-- 开启联盟战
function AllianceFightApi:StartAllianceWar()
    if not Alliance_Manager:GetMyAlliance():IsDefault() then
        if Alliance_Manager:GetMyAlliance().basicInfo.status ~= "peace" then
            return
        end
        local isEqualOrGreater = Alliance_Manager:GetMyAlliance():GetSelf()
            :IsTitleEqualOrGreaterThan("general")
        if isEqualOrGreater then
            -- 查找到一个可以开启盟战的联盟
            local mapIndex = RandomMapIndex()
            return EnterMapIndexAndFunc(mapIndex,function (allianceData)
                if allianceData.basicInfo.status == "peace" then
                    print("开启联盟战",allianceData.basicInfo.tag)
                    return NetManager:getAttackAlliancePromose(allianceData._id)
                end
            end)
        end
    end
end
-- 行军事件
function AllianceFightApi:March()
    local alliance = Alliance_Manager:GetMyAlliance()
    -- local enemy_alliance = Alliance_Manager:GetEnemyAlliance()
    local dragon_manager = City:GetFirstBuildingByType("dragonEyrie"):GetDragonManager()
    if not alliance:IsDefault() then
        -- 解锁第二条行军队列
        if User.basicInfo.marchQueue < 2 then
            return NetManager:getUnlockPlayerSecondMarchQueuePromise()
        end
        local function __getSoldierConfig(soldier_type,level)
            local normal = GameDatas.Soldiers.normal
            local SPECIAL = GameDatas.Soldiers.special
            local level = level or 1
            return normal[soldier_type.."_"..level] or SPECIAL[soldier_type]
        end
        -- 首先检查是否有条件攻打，龙，兵
        local dragonType
        local dragonWidget = 0
        local dragon
        for k,d in pairs(dragon_manager:GetDragons()) do
            if d:Status() == "free" and not d:IsDead() and d:Ishated() then
                if d:GetWeight() > dragonWidget then
                    dragonWidget = d:GetWeight()
                    dragonType = k
                    dragon = d
                end
            end
        end
        local fight_soldiers = {}
        if dragon then
            -- 带兵量判定
            local leadCitizen = dragon:LeadCitizen()
            local soldiers_citizen = 0
            for k,v in pairs(User.soldiers) do
                if v > 0 then
                    local count = math.random(v)
                    soldiers_citizen = soldiers_citizen+count*__getSoldierConfig(k,User:SoldierStarByName(k)).citizen

                    if leadCitizen >= soldiers_citizen then
                        table.insert(fight_soldiers,{ name = k, count = count})
                    else
                        break
                    end
                end
            end
        end
        print("行军事件",#fight_soldiers,dragonType)


        -- 可选的各种行军事件
        local march_types = {
            "attackCity", -- 攻打城市
            "attackMonster", -- 攻打城市
            "strikeCity", -- 突袭城市
            "village", -- 采集自己的村落
            "retreatFromVillage", -- 从村落撤军
            "enemyVillage", -- 采集敌方的村落
            "shrine", -- 圣地
            "helpDefence", -- 协防
            "retreatHelped", -- 撤防
        }
        local excute = march_types[math.random(#march_types)]
        local isReachEventLimit = alliance:IsReachEventLimit()
        local canSendTroop = #fight_soldiers > 0 and dragonType
        -- 战争期寻找对战联盟mapIndex
        local mapIndex
        if alliance.basicInfo.status == "fight" then
            local alliance = alliance.allianceFight.attacker.alliance.id == alliance._id and alliance.allianceFight.defencer.alliance or alliance.allianceFight.attacker.alliance
            mapIndex = alliance.mapIndex
        else
            -- 随机找一个地图，有联盟则攻打
            mapIndex = RandomMapIndex()
        end
        -- excute = "strikeCity"
        if excute == "attackCity" and not isReachEventLimit and canSendTroop then
            -- 攻打城市
            -- 盟战期间打敌方联盟
            local function AttackCity(allianceData)
                local can_attack = {}
                for k,v in pairs(allianceData.members) do
                    if not v.isProtected then
                        table.insert(can_attack, v)
                    end
                end

                if #can_attack > 0 then
                    local attack_target = can_attack[math.random(#can_attack)]
                    print("攻打敌方城市,敌方名字:",attack_target.name)
                    print("攻打敌方城市,派出龙:",dragonType)
                    dump(fight_soldiers,"攻打敌方城市,派出士兵")
                    return NetManager:getAttackPlayerCityPromise(dragonType, fight_soldiers, allianceData._id, attack_target.id)
                end
            end
            return EnterMapIndexAndFunc(mapIndex,AttackCity)
        elseif excute == "attackMonster" and not isReachEventLimit and canSendTroop then
            -- 攻打野怪
            local function AttackMonster(allianceData)
                local can_attack = allianceData.monsters
                if #can_attack > 0 then
                    local attack_target = can_attack[math.random(#can_attack)]
                    print("攻打敌方野怪,野怪名字:",attack_target.name)
                    print("攻打敌方野怪,派出龙:",dragonType)
                    dump(fight_soldiers,"攻打敌方城市,派出士兵")
                    return NetManager:getAttackMonsterPromise(dragonType, fight_soldiers, allianceData._id, attack_target.id)
                end
            end
            return EnterMapIndexAndFunc(mapIndex,AttackMonster)
        elseif excute == "strikeCity" and not isReachEventLimit and dragonType then
            local function StrikeCity(allianceData)
                local can_attack = {}
                for k,v in pairs(allianceData.members) do
                    if not v.isProtected then
                        table.insert(can_attack, v)
                    end
                end

                if #can_attack > 0 then
                    local attack_target = can_attack[math.random(#can_attack)]
                    print("突袭敌方城市,敌方名字:",attack_target.name)
                    print("突袭敌方城市,派出龙:",dragonType)
                    return NetManager:getStrikePlayerCityPromise(dragonType,attack_target.id,allianceData._id)
                end
            end
            return EnterMapIndexAndFunc(mapIndex,StrikeCity)
        elseif excute == "village" and not isReachEventLimit and canSendTroop then
            local villages = alliance.villages
            local clone_villages = {}
            for k,v in pairs(villages) do
                table.insert(clone_villages, v)
            end
            local attack_village = clone_villages[math.random(#clone_villages)]
            print("占领自己村落:",attack_village.name)
            print("占领自己村落,派出龙:",dragonType)
            dump(fight_soldiers,"占领自己村落,派出士兵")
            return NetManager:getAttackVillagePromise(dragonType,fight_soldiers,alliance._id,attack_village.id)
        elseif excute == "retreatFromVillage" then
            local villageEvents = alliance.villageEvents
            for k,event in pairs(villageEvents) do
                if UtilsForEvent:IsMyVillageEvent(event) then
                    print("从村落撤军")
                    return  NetManager:getRetreatFromVillagePromise(event.id)
                end
            end
        elseif excute == "enemyVillage" and not isReachEventLimit and canSendTroop then
            if alliance.basicInfo.status=="fight" then
                local function AttackOtherVillage(allianceData)
                    local clone_villages = {}
                    for k,v in pairs(allianceData.villages) do
                        table.insert(clone_villages, v)
                    end
                    local attack_village = clone_villages[math.random(#clone_villages)]
                    print("占领敌方村落:",attack_village.name)
                    print("占领敌方村落,派出龙:",dragonType)
                    dump(fight_soldiers,"占领敌方村落,派出士兵")
                    return NetManager:getAttackVillagePromise(dragonType,fight_soldiers,allianceData._id,attack_village.id)
                end
                return EnterMapIndexAndFunc(mapIndex,AttackOtherVillage)
            end
        elseif excute == "shrine" and not isReachEventLimit then
            -- 圣地
            -- 小几率执行获取圣地战历史记录api
            if math.random(100) < 5 then
                print("小几率执行获取圣地战历史记录api")
                return NetManager:getShrineReportsPromise()
            else
                local shrine_events = alliance:GetShrineEventsBySeq()
                if #shrine_events > 0 and alliance:CanSendTroopToShrine(User:Id()) and canSendTroop then
                    local fightEvent = shrine_events[math.random(#shrine_events)]
                    print("攻打圣地,派出龙:",dragonType)
                    dump(fight_soldiers,"攻打圣地,派出士兵")
                    return NetManager:getMarchToShrinePromose(fightEvent.id,dragonType,fight_soldiers)
                else
                    local member = alliance:GetSelf()
                    if member:CanActivateShirneEvent()  then
                        local shrineStage = GameDatas.AllianceInitData.shrineStage

                        local can_active_stage = {}
                        for k,stage in pairs(shrineStage) do
                            if alliance:IsSubStageUnlock(stage.stageName) then
                                table.insert(can_active_stage, stage)
                            end
                        end
                        local to_active_stage = can_active_stage[math.random(#can_active_stage)]
                        if to_active_stage.needPerception <= alliance:GetPerception()
                            and not alliance:GetShrineEventByStageName(to_active_stage.stageName)
                        then
                            print("激活联盟圣地事件",to_active_stage.stageName)
                            return NetManager:getActivateAllianceShrineStagePromise(to_active_stage.stageName)
                        end
                    end
                end
            end
        elseif excute == "helpDefence" and canSendTroop and not isReachEventLimit then
            local allMembers = alliance:GetAllMembers()
            local can_help_member = {}
            for k,v in pairs(allMembers) do
                if not alliance:CheckHelpDefenceMarchEventsHaveTarget(v:Id()) and v:Id() ~= User:Id() then
                    print("可协防玩家：",v:Name(),v:Id())
                    table.insert(can_help_member, v)
                end
            end
            if #can_help_member < 1 then
                return
            end
            -- 随机一个玩家去协防
            local player = can_help_member[math.random(#can_help_member)]
            local playerId = player:Id()

            if playerId and not User:IsHelpedToPlayer(playerId) then
                print("协防玩家城市:",player:Name())
                print("协防玩家城市,派出龙:",dragonType)
                dump(fight_soldiers,"协防玩家城市,派出士兵")
                return NetManager:getHelpAllianceMemberDefencePromise(dragonType, fight_soldiers, playerId)
            end
        elseif excute == "retreatHelped" then
            local allMembers = alliance:GetAllMembers()
            local can_retreat_member = {}
            for k,v in pairs(allMembers) do
                if User:IsHelpedToPlayer(v:Id()) and v:Id() ~= User:Id() then
                    table.insert(can_retreat_member, v)
                end
            end
            if #can_retreat_member > 0 then
                print("撤防！！！！！！！！！！！！")
                return NetManager:getRetreatFromHelpedAllianceMemberPromise(can_retreat_member[1]:Id())
            end
        end
    end
end
-- 加速自己所有行军事件
function  AllianceFightApi:SpeedUpMarchEvent()
    local alliance = Alliance_Manager:GetMyAlliance()
    if not alliance:IsDefault() then
        -- 有正在行军的则加速
        local marchEvents = alliance.marchEvents
        local my_events = {}
        for k,kindsOfEvents in pairs(marchEvents) do
            for i,event in ipairs(kindsOfEvents) do
                if event.attackPlayerData.id == User:Id() then
                    event.eventType = k
                    table.insert(my_events, event)
                end
            end
        end
        for k,march_event in pairs(my_events) do
            local left_time = march_event.arriveTime / 1000.0 - app.timer:GetServerTime()
            if left_time > 20 then
                print("加速行军事件",march_event.id,left_time)

                return NetManager:getBuyAndUseItemPromise("warSpeedupClass_2",{
                    ["warSpeedupClass_2"]={
                        eventType = march_event.eventType,
                        eventId = march_event.id
                    }
                })
            end
        end
    end
end


local function setRun()
    app:setRun()
end

--联盟战方法组
local function TreatSoldiers()
    local p = AllianceFightApi:TreatSoldiers()
    if p then
        p:always(setRun)
    else
        setRun()
    end
end
local function RecruitNormalSoldier()
    local p = AllianceFightApi:RecruitNormalSoldier()
    if p then
        p:always(setRun)
    else
        setRun()
    end
end
local function StartAllianceWar()
    local p = AllianceFightApi:StartAllianceWar()
    if p then
        p:always(setRun)
    else
        setRun()
    end
end
local function March()
    local p = AllianceFightApi:March()
    if p then
        p:always(setRun)
    else
        setRun()
    end
end
local function SpeedUpMarchEvent()
    local p = AllianceFightApi:SpeedUpMarchEvent()
    if p then
        p:always(setRun)
    else
        setRun()
    end
end
local function RecruitSpecialSoldier()
    local p = AllianceFightApi:RecruitSpecialSoldier()
    if p then
        p:always(setRun)
    else
        setRun()
    end
end


return {
    setRun,
    TreatSoldiers,
    RecruitNormalSoldier,
    RecruitSpecialSoldier,
    StartAllianceWar,
    March,
    SpeedUpMarchEvent,
}









































