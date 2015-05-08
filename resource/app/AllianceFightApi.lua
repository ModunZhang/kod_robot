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
-- 攻打敌方城市
function AllianceFightApi:AttackCity()
    if not Alliance_Manager:GetMyAlliance():IsDefault() then
        if Alliance_Manager:GetMyAlliance():Status()=="fight" then
            if not Alliance_Manager:GetMyAlliance():GetAllianceBelvedere():IsReachEventLimit() then
                local allMembers = Alliance_Manager:GetEnemyAlliance():GetAllMembers()
                local can_attack = {}
                for k,v in pairs(allMembers) do
                    if not v:IsProtected() then
                        table.insert(can_attack, v)
                    end
                end
                local dragon_manager = City:GetFirstBuildingByType("dragonEyrie"):GetDragonManager()
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
                if #fight_soldiers > 0 and dragonType and #can_attack > 0 then
                    local attack_target = can_attack[math.random(#can_attack)]
                    print("攻打敌方城市,敌方名字:",attack_target:Name())
                    print("攻打敌方城市,派出龙:",dragonType)
                    dump(fight_soldiers,"攻打敌方城市,派出士兵")
                    return NetManager:getAttackPlayerCityPromise(dragonType, fight_soldiers, attack_target:Id())
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
local function AttackCity()
    local p = AllianceFightApi:AttackCity()
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
    AttackCity,
    SpeedUpMarchEvent,
}




