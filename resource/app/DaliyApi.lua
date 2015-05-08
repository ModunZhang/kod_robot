--
-- Author: Kenny Dai
-- Date: 2015-05-07 21:16:49
--

local DaliyApi = {}

-- 每日任务测试
function DaliyApi:DailyQuests()
    -- 市政厅是否已解锁
    if not app:IsBuildingUnLocked(15) then
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
-- 军事科技
function DaliyApi:MilitaryTech()
    local soldier_manager = City:GetSoldierManager()
    -- 训练场
    -- 猎手大厅
    -- 马厩
    -- 车间
    local building_tech_map = {
        {17 , "trainingGround"},
        {18 , "hunterHall"},
        {19 , "stable"},
        {20 , "workshop"},
    }
    local witch_building = math.random(17,20)
    for i,map in ipairs(building_tech_map) do
        if witch_building == i then
            local building_index,building_name = map[1] , map[2]
            if app:IsBuildingUnLocked(building_index) then
                -- 没有升级事件
                if not soldier_manager:IsUpgradingMilitaryTech(building_name) then
                    -- 随机晋升士兵星级或者升级科技
                    local upgrade_soldier = math.random(10) < 4
                    if upgrade_soldier then
                        local soldiers_star = soldier_manager:FindSoldierStarByBuildingType(building_name)
                        for soldier_type,v in pairs(soldiers_star) do
                            -- 最大三星
                            if v < soldier_manager:GetSoldierMaxStar() then
                                -- 科技点是否满足
                                local level_up_config =  GameDatas.Soldiers.normal[soldier_type.."_"..(soldier_manager:GetStarBySoldierType(soldier_type)+1)]
                                local tech_points = soldier_manager:GetTechPointsByType(building_name)
                                if tech_points<level_up_config.upgradeTechPointNeed then
                                    return
                                end
                                local isFinishNow = math.random(2) == 2
                                if isFinishNow then
                                    print("立即晋升士兵：",soldier_type)
                                    return NetManager:getInstantUpgradeSoldierStarPromise(soldier_type)
                                else
                                    print("晋升士兵：",soldier_type)
                                    return NetManager:getUpgradeSoldierStarPromise(soldier_type)
                                end
                                break
                            end
                        end
                    else
                        local techs = soldier_manager:FindMilitaryTechsByBuildingType(building_name)
                        local upgrade_tech = techs[math.random(#techs)]
                        local upgrade_tech_name = techs[math.random(#techs)]:Name()
                        if upgrade_tech:Level() < 15 then
                            -- 立即升级或者普通升级
                            local isFinishNow = math.random(2) == 2
                            if isFinishNow then
                                print("立即升级军事科技：",upgrade_tech_name)
                                return NetManager:getInstantUpgradeMilitaryTechPromise(upgrade_tech_name)
                            else
                                print("升级军事科技：",upgrade_tech_name)
                                return NetManager:getUpgradeMilitaryTechPromise(upgrade_tech_name)
                            end
                        end
                    end

                else
                    -- 加速军事科技升级
                    local upgrading_tech = soldier_manager:GetUpgradingMilitaryTech(building_name)
                    -- 随机使用事件加速道具
                    local speedUp_item_name = "speedup_"..math.random(8)
                    print("使用"..speedUp_item_name.."加速"..upgrading_tech:GetEventType().." ,id:",upgrading_tech:Id())
                    return NetManager:getBuyAndUseItemPromise(speedUp_item_name,{[speedUp_item_name] = {
                        eventType = upgrading_tech:GetEventType(),
                        eventId = upgrading_tech:Id()
                    }})
                end

            end
        end
    end
end

local function setRun()
    app:setRun()
end

local function DailyQuests()
    local p = DaliyApi:DailyQuests()
    if p then
        p:always(setRun)
    else
        setRun()
    end
end
local function MilitaryTech()
    local p = DaliyApi:MilitaryTech()
    if p then
        p:always(setRun)
    else
        setRun()
    end
end

return {
    setRun,
    DailyQuests,
    MilitaryTech,
}



