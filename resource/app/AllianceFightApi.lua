--
-- Author: Kenny Dai
-- Date: 2015-05-07 21:24:05
--
local AllianceFightApi = {}

-- 治疗士兵
function AllianceFightApi:TreatSoldiers()
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
        dump(unlock_soldiers)
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
            local soldier_config = City:GetSoldierManager():GetSoldierConfig(soldier_type)
            local count = 1 -- 招募一个
            local specialMaterials = string.split(soldier_config.specialMaterials,",")
            local is_enough = true
            for k,v in pairs(specialMaterials) do
                local temp = string.split(v, "_")
                local total = City:GetMaterialManager():GetMaterialsByType(City:GetMaterialManager().MATERIAL_TYPE.SOLDIER)[temp[1]]
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
-- 开启联盟战
function AllianceFightApi:StartAllianceWar()
    if not Alliance_Manager:GetMyAlliance():IsDefault() then
        if Alliance_Manager:GetMyAlliance():Status()~="peace" then
            return
        end
        local isEqualOrGreater = Alliance_Manager:GetMyAlliance():GetMemeberById(User:Id())
            :IsTitleEqualOrGreaterThan("general")
        if isEqualOrGreater then
            print("开启联盟战")
            return NetManager:getFindAllianceToFightPromose()
        end
    end
end
-- 行军事件
function AllianceFightApi:March()
    local alliance = Alliance_Manager:GetMyAlliance()
    local enemy_alliance = Alliance_Manager:GetEnemyAlliance()
    local dragon_manager = City:GetFirstBuildingByType("dragonEyrie"):GetDragonManager()
    if not alliance:IsDefault() then
        -- 解锁第二条行军队列
        if alliance:GetAllianceBelvedere():GetMarchLimit() < 2 then
            return NetManager:getUnlockPlayerSecondMarchQueuePromise()
        end
        print("行军事件",alliance:GetAllianceBelvedere():IsReachEventLimit())
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
            if d:Status()=="free" and not d:IsDead() then
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
            for k,v in pairs(City:GetSoldierManager():GetSoldierMap()) do
                if v > 0 then
                    local count = math.random(v)
                    soldiers_citizen = soldiers_citizen+count*__getSoldierConfig(k,City:GetSoldierManager():GetStarBySoldierType(k)).citizen

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
            "strikeCity", -- 突袭城市
            "village", -- 采集自己的村落
            "retreatFromVillage", -- 从村落撤军
            "enemyVillage", -- 采集敌方的村落
            "shrine", -- 圣地
            "helpDefence", -- 协防
            "retreatHelped", -- 撤防
        }
        local excute = march_types[math.random(#march_types)]
        if excute == "attackCity" and not alliance:GetAllianceBelvedere():IsReachEventLimit() then
            -- 攻打城市
            if alliance:Status()=="fight" and #fight_soldiers > 0 and dragonType then
                local allMembers = enemy_alliance:GetAllMembers()
                local can_attack = {}
                for k,v in pairs(allMembers) do
                    if not v:IsProtected() then
                        table.insert(can_attack, v)
                    end
                end

                if #can_attack > 0 then
                    local attack_target = can_attack[math.random(#can_attack)]
                    -- 只攻打盟主联盟
                    local our_archon = alliance:GetAllianceArchon()
                    if string.find(our_archon.Name(),"800_") then
                        attack_target = enemy_alliance:GetAllianceArchon()
                    end
                    print("攻打敌方城市,敌方名字:",attack_target:Name())
                    print("攻打敌方城市,派出龙:",dragonType)
                    dump(fight_soldiers,"攻打敌方城市,派出士兵")
                    return NetManager:getAttackPlayerCityPromise(dragonType, fight_soldiers, attack_target:Id())
                end
            end
        elseif excute == "strikeCity" and not alliance:GetAllianceBelvedere():IsReachEventLimit() then
            if alliance:Status()=="fight" and dragonType then
                local allMembers = enemy_alliance:GetAllMembers()
                local can_attack = {}
                for k,v in pairs(allMembers) do
                    if not v:IsProtected() then
                        table.insert(can_attack, v)
                    end
                end

                if #can_attack > 0 then
                    local attack_target = can_attack[math.random(#can_attack)]
                    print("突袭敌方城市,敌方名字:",attack_target:Name())
                    print("突袭敌方城市,派出龙:",dragonType)
                    return NetManager:getStrikePlayerCityPromise(dragonType,attack_target:Id())
                end
            end
        elseif excute == "village" and not alliance:GetAllianceBelvedere():IsReachEventLimit() then
            if #fight_soldiers > 0 and dragonType then
                local villages = alliance:GetAllianceVillageInfos()
                local clone_villages = {}
                for k,v in pairs(villages) do
                    table.insert(clone_villages, v)
                end
                local attack_village = clone_villages[math.random(#clone_villages)]
                print("占领自己村落:",attack_village.name)
                print("占领自己村落,派出龙:",dragonType)
                dump(fight_soldiers,"占领自己村落,派出士兵")
                return NetManager:getAttackVillagePromise(dragonType,fight_soldiers,alliance:Id(),attack_village.id)
            end
        elseif excute == "retreatFromVillage" then
            local villages = alliance:GetAllianceVillageInfos()
            for k,v in pairs(villages) do
                local villageEvent = alliance:FindVillageEventByVillageId(v.id)
                if villageEvent and villageEvent:GetPlayerRole() == villageEvent.EVENT_PLAYER_ROLE.Me then --自己占领
                    print("从村落撤军")
                    return  NetManager:getRetreatFromVillagePromise(alliance:Id(),villageEvent:Id())
                end
            end
        elseif excute == "enemyVillage" and not alliance:GetAllianceBelvedere():IsReachEventLimit() then
            if alliance:Status()=="fight" and #fight_soldiers > 0 and dragonType then
                local villages = enemy_alliance:GetAllianceVillageInfos()
                local clone_villages = {}
                for k,v in pairs(villages) do
                    table.insert(clone_villages, v)
                end
                local attack_village = clone_villages[math.random(#clone_villages)]
                print("占领敌方村落:",attack_village.name)
                print("占领敌方村落,派出龙:",dragonType)
                dump(fight_soldiers,"占领敌方村落,派出士兵")
                return NetManager:getAttackVillagePromise(dragonType,fight_soldiers,enemy_alliance:Id(),attack_village.id)
            end
        elseif excute == "shrine" then
            -- 圣地
            -- 小几率执行获取圣地战历史记录api
            if math.random(100) < 5 then
                print("小几率执行获取圣地战历史记录api")
                return NetManager:getShrineReportsPromise()
            else
                local alliance_shirine = alliance:GetAllianceShrine()
                if alliance_shirine:HaveEvent() and alliance_shirine:CheckSelfCanDispathSoldiers() and #fight_soldiers > 0 and dragonType then
                    local shirineEvents = alliance_shirine:GetShrineEvents()
                    local fightEvent = shirineEvents[math.random(#shirineEvents)]
                    print("攻打圣地,派出龙:",dragonType)
                    dump(fight_soldiers,"攻打圣地,派出士兵")
                    return NetManager:getMarchToShrinePromose(fightEvent:Id(),dragonType,fight_soldiers)
                else
                    local member = alliance:GetSelf()
                    if member:CanActivateShirneEvent()  then
                        local alliance_stages = alliance_shirine:Stages()
                        local can_active_stage = {}
                        for k,stage in pairs(alliance_stages) do
                            if not stage:IsLocked() then
                                table.insert(can_active_stage, stage)
                            end
                        end
                        local to_active_stage = can_active_stage[math.random(#can_active_stage)]
                        if to_active_stage:NeedPerception() <= alliance_shirine:GetPerceptionResource():GetResourceValueByCurrentTime(app.timer:GetServerTime()) 
                            and not alliance_shirine:GetShrineEventByStageName(to_active_stage:StageName())
                            then
                            print("激活联盟圣地事件",to_active_stage:StageName())
                            return NetManager:getActivateAllianceShrineStagePromise(to_active_stage:StageName())
                        end
                    end
                end
            end
        elseif excute == "helpDefence" and #fight_soldiers > 0 and dragonType and not alliance:GetAllianceBelvedere():IsReachEventLimit() then
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

            if playerId then
                print("协防玩家城市:",player:Name())
                print("协防玩家城市,派出龙:",dragonType)
                dump(fight_soldiers,"协防玩家城市,派出士兵")
                return NetManager:getHelpAllianceMemberDefencePromise(dragonType, fight_soldiers, playerId)
            end
        elseif excute == "retreatHelped" then
            local allMembers = alliance:GetAllMembers()
            local can_retreat_member = {}
            for k,v in pairs(allMembers) do
                if City:IsHelpedToTroopsWithPlayerId(v:Id()) and v:Id() ~= User:Id() then
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
    -- 有正在行军的则加速
    local my_events = Alliance_Manager:GetMyAlliance():GetAllianceBelvedere():GetMyEvents()
    for k,march_event in pairs(my_events) do
        if march_event:WithObject().GetTime and march_event:WithObject():GetTime() > 10 then
            print("加速行军事件",march_event:WithObject():Id(),march_event:GetEventServerType(),march_event:WithObject():GetTime())
            if march_event:GetEventServerType() == "村落采集事件" or march_event:GetEventServerType() == "圣地事件" then
                return
            end
            return NetManager:getBuyAndUseItemPromise("warSpeedupClass_2",{
                ["warSpeedupClass_2"]={
                    eventType = march_event:GetEventServerType(),
                    eventId = march_event:WithObject():Id()
                }
            })
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






























