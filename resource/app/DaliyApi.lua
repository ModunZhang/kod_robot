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
    -- local soldier_manager = City:GetSoldierManager()
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
                if not User:HasMilitaryTechEventBy(building_name) then
                    -- 随机晋升士兵星级或者升级科技
                    local upgrade_soldier = math.random(10) < 4
                    if upgrade_soldier then
                        local soldiers_star = User:GetBuildingSoldiersInfo(building_name)
                        for soldier_type,v in pairs(soldiers_star) do
                            -- 最大三星
                            if v < GameDatas.PlayerInitData.intInit.soldierMaxStar.value then
                                -- 科技点是否满足
                                local level_up_config =  GameDatas.Soldiers.normal[soldier_type.."_"..(User:SoldierStarByName(soldier_type)+1)]
                                local tech_points = User:GetTechPoints(building_name)
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
                        local techs = User:GetMilitaryTechsByBuilding(building_name)
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
                    local upgrading_tech = User:GetMilitaryTechEventBy(building_name)
                    if math.random(2) == 1 then -- 宝石加速
                        return NetManager:getSpeedUpPromise(upgrading_tech:GetEventType(),upgrading_tech:Id())
                    else
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
end
-- 工具作坊
function DaliyApi:ToolShop()
    -- 工具作坊是否已解锁
    if not app:IsBuildingUnLocked(16) then
        return
    end
    if User:CanMakeMaterials() then
        if User:IsStoreMaterials("buildingMaterials") then
            return NetManager:getFetchMaterialsPromise(User:GetStoreMaterialsEvent("buildingMaterials").id)
        elseif not User:IsMakingMaterials("buildingMaterials") then
            return NetManager:getMakeBuildingMaterialPromise()
        end
        if User:IsStoreMaterials("technologyMaterials") then
            return NetManager:getFetchMaterialsPromise(User:GetStoreMaterialsEvent("technologyMaterials").id)
        elseif not User:IsMakingMaterials("technologyMaterials") then
            return NetManager:getMakeTechnologyMaterialPromise()
        end
    else
        local materialsEvent = User:GetMakingMaterialsEvent()
        if materialsEvent then
            if math.random(2) == 1 then -- 宝石加速
                return NetManager:getSpeedUpPromise("materialEvents",materialsEvent.id)
            else
                -- 随机使用事件加速道具
                local speedUp_item_name = "speedup_"..math.random(8)
                print("使用"..speedUp_item_name.."加速材料制造 ,id:",materialsEvent.id)
                return NetManager:getBuyAndUseItemPromise(speedUp_item_name,{[speedUp_item_name] = {
                    eventType = "materialEvents",
                    eventId = materialsEvent.id
                }})
            end
        end
    end
end
-- 贸易行会
function DaliyApi:TradeGuild()
    -- 贸易行会是否已解锁
    if not app:IsBuildingUnLocked(14) then
        return
    end
    local city = City
    -- 检查是否有出售了的订单
    local my_deals = User:GetMyDeals()
    for k,v in pairs(my_deals) do
        if v.isSold then
            return NetManager:getGetMyItemSoldMoneyPromise(v.id)
        end
    end

    -- 随机是否下架商品
    local is_remove_item = math.random(10) == 2 and #my_deals > 0
    if is_remove_item then
        for k,v in pairs(my_deals) do
            dump(v,"下架贸易行会商品")
            return NetManager:getRemoveMySellItemPromise(v.id)
        end
    else
        local trade_guild = city:GetBuildingByLocationId(14)

        local is_sell = UtilsForBuilding:GetMaxSellQueue(User) > #my_deals
        local sell_sub_types = {
            resources =  {
                [1] = "wood",
                [2] = "stone",
                [3] = "iron",
                [4] = "food",
            },
            buildingMaterials = {
                [1] = "blueprints",
                [2] = "tools",
                [3] = "tiles",
                [4] = "pulley",
            },
            technologyMaterials = {
                [1] = "trainingFigure",
                [2] = "bowTarget",
                [3] = "saddle",
                [4] = "ironPart",
            }
        }
        if is_sell then
            -- 出售物品
            local current_time = app.timer:GetServerTime()
            local has_materials = User.buildingMaterials
            local has_technology_materials = User.technologyMaterials

            local can_sell_values = {
                resources =  {
                    [1] = math.floor(User:GetResValueByType("wood")/1000),
                    [2] = math.floor(User:GetResValueByType("stone")/1000),
                    [3] = math.floor(User:GetResValueByType("iron")/1000),
                    [4] = math.floor(User:GetResValueByType("food")/1000),
                },
                buildingMaterials =  {
                    [1] = has_materials.blueprints,
                    [2] = has_materials.tools,
                    [3] = has_materials.tiles,
                    [4] = has_materials.pulley,
                },
                technologyMaterials =  {
                    [1] = has_technology_materials.trainingFigure,
                    [2] = has_technology_materials.bowTarget,
                    [3] = has_technology_materials.saddle,
                    [4] = has_technology_materials.ironPart,
                }
            }

            -- 小车数量
            local cart_num = User:GetResValueByType("cart")

            local types = {
                "resources",
                "buildingMaterials",
                "technologyMaterials",
            }

            local sell_type = types[math.random(3)]
            local sub_index = math.random(4)
            local sell_sub_type = sell_sub_types[sell_type][sub_index]
            local sell_current_value = can_sell_values[sell_type][sub_index]
            print("cart_num=",cart_num,",sell_current_value,",sell_current_value,"sell_sub_type",sell_sub_type)

            -- 最大出售数量
            local max_sell = math.min(cart_num,sell_current_value)
            if max_sell < 1 then
                return
            end
            -- 随机出售数量
            local sell_count = math.random(max_sell)

            -- 资源，材料出售价格区间
            local PRICE_SCOPE = {
                resource = {
                    min = 100,
                    max = 1000
                },
                material = {
                    min = 3000,
                    max = 12000
                },
                martial_material = {
                    min = 6000,
                    max = 24000
                }
            }
            local sell_price
            if sell_type == "resources" then
                sell_price = math.random(100,1000)
            elseif sell_type == "buildingMaterials" then
                sell_price = math.random(3000,12000)
            else
                sell_price = math.random(6000,24000)
            end
            print("贸易行会出售：",sell_type,sell_sub_type,"数量：",sell_count,"价格：",sell_price)
            return NetManager:getSellItemPromise(sell_type,sell_sub_type,sell_count,sell_price)
        else
            -- 购买物品
            -- 获取商品列表
            local types = {
                "resources",
                "buildingMaterials",
                "technologyMaterials",
            }
            local sell_type = types[math.random(3)]
            local sub_index = math.random(4)
            local sell_sub_type = sell_sub_types[sell_type][sub_index]
            return NetManager:getGetSellItemsPromise(sell_type,sell_sub_type):done(function(response)
                local itemDocs = response.msg.itemDocs
                if #itemDocs > 0 then
                    -- 随机购买一个
                    local item = itemDocs[math.random(#itemDocs)]
                    if User:Id() ~= item.playerId then
                        dump(item,"随机购买一个商品")
                        NetManager:getBuySellItemPromise(item._id)
                    end
                end
            end)
        end
    end
end
-- 日常奖励领取
function DaliyApi:GetDaliyRewards()
    local countInfo = User.countInfo
    local real_index = countInfo.day60 % 30
    for index = 1,30 do
        if countInfo.day60 > countInfo.day60RewardsCount and real_index == index then
            print("领取getDay60RewardPromise奖励",countInfo.day60,countInfo.day60RewardsCount,real_index , index)
            return NetManager:getDay60RewardPromise()
        end
    end
    -- 在线奖励
    --flag 1.已领取 2.可以领取 3.还不能领取
    local config_online = GameDatas.Activities.online
    local on_line_time = DataUtils:getPlayerOnlineTimeMinutes()
    local r = {}
    for __,v in pairs(config_online) do
        local flag = 3
        if v.onLineMinutes <= on_line_time then
            local is_get = false
            for ___,todayOnLine in ipairs(countInfo.todayOnLineTimeRewards) do
                if todayOnLine == v.timePoint then
                    is_get = true
                end
            end
            if is_get then
                flag = 1
            else
                flag = 2
            end
        end
        if flag == 2 then
            print("领取在线奖励",v.timePoint)
            return NetManager:getOnlineRewardPromise(v.timePoint)
        end
    end


    -- 登陆14天奖励
    -- flag 1.已领取 2.可领取 3.明天领取 0 未来的
    local r = {}
    local config_day14 = GameDatas.Activities.day14
    for i,v in ipairs(config_day14) do
        local config_rewards = string.split(v.rewards,",")
        if #config_rewards == 1 then
            local reward_type,item_key,count = unpack(string.split(v.rewards,":"))
            local flag = 0
            if v.day <= countInfo.day14RewardsCount then
                flag = 1
            elseif v.day == countInfo.day14 and countInfo.day14 > countInfo.day14RewardsCount then
                flag = 2
            elseif v.day == countInfo.day14 + 1  then
                flag = 3
            end
            if flag == 2 then
                print("领取day14奖励")
                return NetManager:getDay14RewardPromise()
            end
        else
            for __,one_reward in ipairs(config_rewards) do
                local reward_type,item_key,count = unpack(string.split(one_reward,":"))
                if reward_type == 'soldiers' then
                    local flag = 0
                    if v.day <= countInfo.day14RewardsCount then
                        flag = 1
                    elseif v.day == countInfo.day14 and countInfo.day14 > countInfo.day14RewardsCount then
                        flag = 2
                    elseif v.day == countInfo.day14 + 1  then
                        flag = 3
                    end
                    if flag == 2 then
                        print("领取day14奖励")
                        return NetManager:getDay14RewardPromise()
                    end
                end
            end
        end
    end

    -- 成就奖励
    local tasks = UtilsForTask:GetFirstCompleteTasks(User.growUpTasks)
    local i1, i2, i3 = unpack(tasks)
    if i1 then
        print("领取成就任务奖励",i1:TaskType(), i1.id)
        return NetManager:getGrowUpTaskRewardsPromise(i1:TaskType(), i1.id)
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
local function ToolShop()
    local p = DaliyApi:ToolShop()
    if p then
        p:always(setRun)
    else
        setRun()
    end
end
local function TradeGuild()
    local p = DaliyApi:TradeGuild()
    if p then
        p:always(setRun)
    else
        setRun()
    end
end
local function GetDaliyRewards()
    local p = DaliyApi:GetDaliyRewards()
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
    ToolShop,
    TradeGuild,
    GetDaliyRewards,
}





























