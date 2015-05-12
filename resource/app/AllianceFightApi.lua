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
        print("立即招募普通士兵",soldier_type)
        return NetManager:getInstantRecruitNormalSoldierPromise(soldier_type, 10)
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
        if not alliance:GetAllianceBelvedere():IsReachEventLimit() then
            -- 首先检查是否有条件攻打，龙，兵
            local dragonType
            local dragonWidget = 0
            for k,dragon in pairs(dragon_manager:GetDragons()) do
                if dragon:Status()=="free" and not dragon:IsDead() then
                    if dragon:GetWeight() > dragonWidget then
                        dragonWidget = dragon:GetWeight()
                        dragonType = k
                    end
                end
            end
            local fight_soldiers = {}
            for k,v in pairs(City:GetSoldierManager():GetSoldierMap()) do
                if v > 0 then
                    table.insert(fight_soldiers,{ name = k,count = math.random(v)})
                end
            end
            if #fight_soldiers < 1 or not dragonType then
                return
            end

            -- 可选的各种行军事件
            local march_types = {
                "attackCity", -- 攻打城市
                -- "village", -- 村落
                -- "shrine", -- 圣地
                -- "helpDefence", -- 协防
                -- "retreatHelped", -- 撤防
            }
            local excute = march_types[math.random(#march_types)]
            if excute == "attackCity" then
                -- 攻打城市
                if alliance:Status()=="fight" then
                    local allMembers = enemy_alliance:GetAllMembers()
                    local can_attack = {}
                    for k,v in pairs(allMembers) do
                        if not v:IsProtected() then
                            table.insert(can_attack, v)
                        end
                    end

                    if #can_attack > 0 then
                        local attack_target = can_attack[math.random(#can_attack)]
                        print("攻打敌方城市,敌方名字:",attack_target:Name())
                        print("攻打敌方城市,派出龙:",dragonType)
                        dump(fight_soldiers,"攻打敌方城市,派出士兵")
                        return NetManager:getAttackPlayerCityPromise(dragonType, fight_soldiers, attack_target:Id())
                    end
                end
            elseif excute == "village" then
                -- TODO 村落
                return
            elseif excute == "shrine" then
                -- TODO 圣地
                return
            elseif excute == "helpDefence" then
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
end
-- 加速自己所有行军事件
function  AllianceFightApi:SpeedUpMarchEvent()
    -- 有正在行军的则加速
    local my_events = Alliance_Manager:GetMyAlliance():GetAllianceBelvedere():GetMyEvents()
    for k,march_event in pairs(my_events) do
        if march_event:WithObject():GetTime() > 10 then
            print("加速行军事件",march_event:WithObject():Id(),march_event:GetEventServerType(),march_event:WithObject():GetTime())
            return NetManager:getBuyAndUseItemPromise("warSpeedupClass_2",{
                ["warSpeedupClass_2"]={
                    eventType = march_event:GetEventServerType(),
                    eventId=march_event:WithObject():Id()
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


return {
    setRun,
    TreatSoldiers,
    RecruitNormalSoldier,
    StartAllianceWar,
    March,
    SpeedUpMarchEvent,
}















