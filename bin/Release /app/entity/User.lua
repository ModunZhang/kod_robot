local Localize = import("..utils.Localize")
local property = import("..utils.property")
local Enum = import("..utils.Enum")
local MultiObserver = import(".MultiObserver")
local User = class("User", MultiObserver)


User.LISTEN_TYPE = Enum(
    "basicInfo",
    "countInfo",
    "resources",
    "growUpTasks",
    "deals",
    "allianceData",

    "helpedByTroops",
    "helpToTroops",

    "buildings",
    "houseEvents",
    "buildingEvents",

    "productionTechs",
    "productionTechEvents",

    "militaryTechs",
    "militaryTechEvents",

    "soldiers",
    "soldierEvents",

    "woundedSoldiers",
    "treatSoldierEvents",

    "soldierStars",
    "soldierStarEvents",

    "iapGifts",
    "allianceDonate",

    "dragons",
    "dragonEquipments",
    "dragonEquipmentEvents",

    "dragonMaterials",
    "soldierMaterials",
    "buildingMaterials",
    "technologyMaterials",
    "materialEvents",

    "vipEvents",

    "items",
    "itemEvents",

    "dailyTasks",
    "dailyQuests",
    "dailyQuestEvents")

property(User, "id", 0)
property(User, "soldierStars", {})
local staminaMax_value = GameDatas.PlayerInitData.intInit.staminaMax.value
local staminaRecoverPerHour_value = GameDatas.PlayerInitData.intInit.staminaRecoverPerHour.value
function User:ctor(p)
    User.super.ctor(self)
    self.resources_cache = {
        gem         = {limit =        math.huge, output = 0},
        blood       = {limit =        math.huge, output = 0},
        casinoToken = {limit =        math.huge, output = 0},
        stamina     = {limit = staminaMax_value, output = staminaRecoverPerHour_value},
        cart        = {limit =        math.huge, output = 0},
        wallHp      = {limit =        math.huge, output = 0},
        coin        = {limit =        math.huge, output = 0},
        wood        = {limit =        math.huge, output = 0},
        food        = {limit =        math.huge, output = 0},
        iron        = {limit =        math.huge, output = 0},
        stone       = {limit =        math.huge, output = 0},
        citizen     = {limit =        math.huge, output = 0},
    }
    if type(p) == "table" then
        self:SetId(p._id)
    else
        self:SetId(p)
    end
end
function User:ResetAllListeners()
    self:ClearAllListener()
end

--[[multiobserver override]]
function User:AddListenOnType(listener, listenerType)
    if type(listenerType) == "string" then
        listenerType = User.LISTEN_TYPE[listenerType]
    end
    User.super.AddListenOnType(self, listener, listenerType)
end
function User:RemoveListenerOnType(listener, listenerType)
    if type(listenerType) == "string" then
        listenerType = User.LISTEN_TYPE[listenerType]
    end
    User.super.RemoveListenerOnType(self, listener, listenerType)
end
--[[end]]

--[[pve相关方法 begin]]
local TOTAL_STAGES = 0
local tt = 0
local stages = GameDatas.PvE.stages
for k,v in pairs(stages) do
    tt = tt + 1
end
for i = 1, tt do
    if stages[string.format("%d_1", i)] then
        TOTAL_STAGES = TOTAL_STAGES + 1
    end
end

local sections = GameDatas.PvE.sections
local PVE_LENGTH = 0
local index = 1
while sections[string.format("1_%d", index)] do
    PVE_LENGTH = PVE_LENGTH + 1
    index = index + 1
end
function User:GetPveLeftCountByName(pve_name)
    return sections[pve_name].maxFightCount - self:GetFightCountByName(pve_name)
end
function User:GetFightCountByName(pve_name)
    for i,v in ipairs(self.pveFights) do
        if v.sectionName == pve_name then
            return v.count
        end
    end
    return 0
end
function User:IsPveBossPassed(pve_name)
    return self:GetPveSectionStarByName(pve_name) > 0
end
function User:IsPveBoss(pve_name)
    local index, s_index = unpack(string.split(pve_name, "_"))
    return tonumber(s_index) == PVE_LENGTH
end
function User:IsPveNameEnable(pve_name)
    local index, s_index = unpack(string.split(pve_name, "_"))
    return self:IsPveEnable(tonumber(index), tonumber(s_index))
end
function User:IsPveEnable(index, s_index)
    if self.pve[index] then
        if s_index == 1 then return true end
        if self:GetPveSectionStarByIndex(index, s_index - 1) > 0 then
            return true
        end
    else
        if self.pve[index-1] then
            return #self.pve[index-1].sections == 21 and s_index == 1
        else
            return s_index == 1
        end
    end
end
function User:GetPveRewardByIndex(index, s_index)
    local npcs = self.pve[index]
    if npcs then
        return npcs.rewarded[s_index]
    end
end
function User:GetPveSectionStarByName(pve_name)
    local index, s_index = unpack(string.split(pve_name, "_"))
    return self:GetPveSectionStarByIndex(tonumber(index), tonumber(s_index))
end
function User:GetPveSectionStarByIndex(index, s_index)
    local npcs = self.pve[index]
    if npcs then
        return npcs.sections[s_index] or 0
    end
    return 0
end
function User:GetStageStarByIndex(index)
    local total_stars = 0
    for i,v in ipairs(self:GetStageByIndex(index).sections or {}) do
        total_stars = total_stars + v
    end
    return total_stars - ((self:GetStageByIndex(index).sections or {})[PVE_LENGTH] or 0)
end
function User:IsStageRewardedByName(stage_name)
    local stage_index,index = unpack(string.split(stage_name, "_"))
    return self:IsStageRewarded(tonumber(stage_index), tonumber(index))
end
function User:IsStageRewarded(stage_index, index)
    for i,v in ipairs(self:GetStageByIndex(stage_index).rewarded or {}) do
        if v == index then
            return true
        end
    end
end
function User:IsStageEnabled(index)
    if index == 1 then return true end
    return self:IsStagePassed(index - 1)
end
function User:IsStagePassed(index)
    return #(self:GetStageByIndex(index).sections or {}) == PVE_LENGTH
end
function User:IsAllPassed()
    return self:IsStagePassed(TOTAL_STAGES)
end
function User:GetNextStageByPveName(pve_name)
    local stage_index,pve_index = unpack(string.split(pve_name, "_"))
    return tonumber(stage_index) + 1
end
function User:HasNextStageByPveName(pve_name)
    local stage_index,pve_index = unpack(string.split(pve_name, "_"))
    return tonumber(stage_index) < TOTAL_STAGES
end
function User:HasNextStageByIndex(index)
    return index < TOTAL_STAGES
end
function User:GetStageTotalStars()
    return (PVE_LENGTH-1) * 3
end
function User:GetStageByIndex(index)
    return self.pve[index] or {}
end
function User:GetLatestPveIndex()
    local index = 1
    if #self.pve == 0 then
        index = 1
    else
        if #self.pve == TOTAL_STAGES then
            index = TOTAL_STAGES
        else
            if self:IsStagePassed(#self.pve) then
                index = #self.pve + 1
            else
                index = #self.pve
            end
        end
    end
    return index
end
--[[end]]

--[[交易相关方法]]
function User:GetMyDeals()
    return self.deals
end
function User:GetSoldDealsCount()
    if not self.deals then
        return 0
    end
    local count = 0
    for k,v in pairs(self.deals) do
        if v.isSold then
            count = count + 1
        end
    end
    return count
end
function User:IsSoldOut()
    return self:GetSoldDealsCount() > 0
end
--[end]


--[[countinfo begin]]
-- 每日登陆奖励是否领取
function User:HaveEveryDayLoginReward()
    local countInfo = self.countInfo
    local flag = countInfo.day60 % 30 == 0 and 30 or countInfo.day60 % 30
    local geted = countInfo.day60RewardsCount % 30 == 0 and 30 or countInfo.day60RewardsCount % 30 -- <= geted
    return flag > geted or (geted == 30 and flag == 1)
end
-- 连续登陆奖励是否领取
local config_day14 = GameDatas.Activities.day14
function User:HaveContinutyReward()
    local countInfo = self.countInfo
    for i,v in ipairs(config_day14) do
        local config_rewards = string.split(v.rewards,",")
        if #config_rewards == 1 then
            local reward_type,item_key,count = unpack(string.split(v.rewards,":"))
            if v.day == countInfo.day14 and countInfo.day14 > countInfo.day14RewardsCount then
                return true
            end
        else
            for __,one_reward in ipairs(config_rewards) do
                local reward_type,item_key,count = unpack(string.split(one_reward,":"))
                if reward_type == 'soldiers' then
                    if v.day == countInfo.day14 and countInfo.day14 > countInfo.day14RewardsCount then
                        return true
                    end
                end
            end
        end
    end
end
-- 城堡冲级奖励是否领取
local config_levelup = GameDatas.Activities.levelup
local playerLevelupRewardsHours_value = GameDatas.PlayerInitData.intInit.playerLevelupRewardsHours.value
function User:HavePlayerLevelUpReward()
    local countInfo = self.countInfo
    local current_level = self.buildings.location_1.level
    for __,v in ipairs(config_levelup) do
        if not (app.timer:GetServerTime() > countInfo.registerTime/1000 + playerLevelupRewardsHours_value * 60 * 60) then
            if  v.level <= current_level then
                local l_flag = true
                for __,l in ipairs(countInfo.levelupRewards) do
                    if l == v.index then
                        l_flag = false
                    end
                end
                if l_flag then
                    return true
                end
            end
        end
    end
end
--[[end]]

--[[iap 相关方法]]
local giftExpireHours_value = GameDatas.PlayerInitData.intInit.giftExpireHours.value
function User:GetIapGiftTime(iapGift)
    return iapGift.time / 1000 + giftExpireHours_value * 60 * 60
end

--[[end]]


--[[items begin]]
function User:IsItemEventActive(type_)
    for k,v in pairs(self.itemEvents) do
        if v.type == type_ then
            local time = UtilsForItem:GetItemEventTime(v)
            return time > 0, time
        end
    end
    return false, 0
end
function User:IsAnyItmeEventActive()
    return next(self.itemEvents)
end
function User:IsItemVisible(item_name)
    return self:GetItemCount(item_name) >= 1 or
        UtilsForItem:GetItemInfoByName(item_name).isSell
end
local config_items_buff     = GameDatas.Items.buff
local config_items_resource = GameDatas.Items.resource
local config_items_speedup  = GameDatas.Items.speedup
local config_items_special  = GameDatas.Items.special
function User:GetRelationItemInfos(item_name)
    local configs
    if config_items_buff[item_name] then
        configs = config_items_buff
    elseif config_items_resource[item_name] then
        configs = config_items_resource
    elseif config_items_speedup[item_name] then
        configs = config_items_speedup
    elseif config_items_special[item_name] then
        configs = config_items_special
    end
    assert(configs)
    local same_items_info = {}
    local item_type, item_index = unpack(string.split(item_name, "_"))
    if item_index then
        for i = 1, math.huge do
            local same_item_info = configs[item_type.."_"..i]
            if same_item_info then
                if same_item_info.isSell or
                    self:GetItemCount(same_item_info.name) > 0 then
                    table.insert(same_items_info, same_item_info)
                end
            else
                break
            end
        end
    end
    return same_items_info
end
function User:CanOpenChest(item_name)
    local area_type = string.split(item_name, "_")
    if area_type[2] == 1 then return true end
    return User:GetItemCount("chestKey_"..area_type[2]) > 0
end
function User:GetItemCount(item_name)
    return UtilsForItem:GetItemCount(self.items, item_name)
end
--[[end]]

--[[gcId]]
function User:IsBindGameCenter()
    local gc = self.gc
    return gc and gc.type == "gamecenter" and gc.gcId ~= "" and gc.gcId ~= json.null
end
function User:IsBindFacebook()
    local gc = self.gc
    return gc and gc.type == "facebook" and gc.gcId ~= "" and gc.gcId ~= json.null
end
--[[end]]

function User:Loyalty()
    return self.allianceData.loyalty
end

--[[resources begin]]
function User:GetGemValue()
    return self:GetResValueByType("gem")
end
function User:HasAnyStamina(num)
    local res = self.resources_cache.stamina
    return self:GetResValueByType("stamina") >= (num or 1)
end
function User:GetResValueByType(type_)
    local res = self.resources_cache[type_]
    return GameUtils:GetCurrentProduction(
        self.resources[type_],
        self.resources.refreshTime / 1000,
        res.limit,
        res.output,
        app.timer:GetServerTime()
    )
end
function User:IsResOverLimit(type_)
    return self.resources[type_] > self.resources_cache[type_].limit
end
function User:GetResProduction(type_)
    return self.resources_cache[type_]
end
function User:GetFoodRealOutput()
    return self:GetSoldierUpkeep() + self.resources_cache.food.output
end
--[[end]]


-- [[ dailyQuests begin]]
function User:GetDailyQuests()
    if self:GetNextDailyQuestsRefreshTime() <= app.timer:GetServerTime() then
        -- 达成刷新每日任务条件
        NetManager:getDailyQuestsPromise()
    else
        local quests = {}
        for k,v in pairs(self.dailyQuestEvents) do
            table.insert(quests, v)
        end
        table.sort( quests, function( a,b )
            return a.finishTime < b.finishTime
        end )
        for k,v in pairs(self.dailyQuests.quests) do
            table.insert(quests, v)
        end
        return quests
    end
end
-- 判定是否完成所有任务
function User:IsFinishedAllDailyQuests()
    if self:GetNextDailyQuestsRefreshTime() <= app.timer:GetServerTime() then
        return false
    end
    return LuaUtils:table_empty(self.dailyQuests.quests)
end
-- 下次刷新任务时间
local dailyQuestsRefreshMinites_value = GameDatas.PlayerInitData.intInit.dailyQuestsRefreshMinites.value
function User:GetNextDailyQuestsRefreshTime()
    return dailyQuestsRefreshMinites_value * 60 + self:GetDailyQuestsRefreshTime()
end
function User:GetDailyQuestsRefreshTime()
    return self.dailyQuests.refreshTime / 1000 or 0
end
function User:IsQuestStarted(quest)
    return tolua.type(quest.finishTime) ~= "nil"
end
function User:IsQuestFinished(quest)
    return quest.finishTime == 0
end
-- 判定是否正在进行每日任务
function User:IsOnDailyQuestEvents()
    local t = self.dailyQuestEvents
    if LuaUtils:table_empty(t) then
        return false
    else
        for k,v in pairs(t) do
            if v.finishTime == 0 then
                return false
            end
        end
        return true
    end
end
-- 判定是否能领取每日任务奖励
function User:CouldGotDailyQuestReward()
    local t = self.dailyQuestEvents
    if LuaUtils:table_empty(t) then
        return false
    else
        for k,v in pairs(t) do
            if v.finishTime == 0 then
                return true
            end
        end
        return false
    end
end
--[[end]]

--[[dailyTasks begin]]
function User:GetDailyTasksFinishedCountByIndex(index)
    return self.dailyTasks[index] or 0
end
function User:GetAllDailyTasks()
    return self.dailyTasks or {}
end
--[[end]]


--[[vip function begin]]
-- 获取当天剩余普通免费gacha次数
local freeNormalGachaCountPerDay_value = GameDatas.PlayerInitData.intInit.freeNormalGachaCountPerDay.value
function User:GetOddFreeNormalGachaCount()
    return freeNormalGachaCountPerDay_value + self:GetVIPNormalGachaAdd() - self.countInfo.todayFreeNormalGachaCount
end
function User:GetVIPFreeSpeedUpTime()
    return self:GetCurrentVipConfig().freeSpeedup
end
function User:GetVIPWoodProductionAdd()
    return self:GetCurrentVipConfig().woodProductionAdd
end
local resource_buff = {
    wallHp  = "RecoveryAdd",
    food    = "ProductionAdd",
    wood    = "ProductionAdd",
    stone   = "ProductionAdd",
    coin    = "ProductionAdd",
    iron    = "ProductionAdd",
    citizen = "ProductionAdd",
}
function User:GetResourceBuff()
    local buff = {}
    local config = self:GetCurrentVipConfig()
    for res_type,suffix in pairs(resource_buff) do
        local value = config[string.format("%s%s", res_type, suffix)]
        buff[res_type] = value or 0
    end
    return buff
end
function User:GetVIPStoneProductionAdd()
    return self:GetCurrentVipConfig().stoneProductionAdd
end
function User:GetVIPIronProductionAdd()
    return self:GetCurrentVipConfig().ironProductionAdd
end
function User:GetVIPFoodProductionAdd()
    return self:GetCurrentVipConfig().foodProductionAdd
end
function User:GetVIPCitizenRecoveryAdd()
    return self:GetCurrentVipConfig().citizenRecoveryAdd
end
function User:GetVIPMarchSpeedAdd()
    return self:GetCurrentVipConfig().marchSpeedAdd
end
function User:GetVIPNormalGachaAdd()
    return self:GetCurrentVipConfig().normalGachaAdd
end
--暗仓保护上限提升
function User:GetVIPStorageProtectAdd()
    return self:GetCurrentVipConfig().storageProtectAdd
end
function User:GetVIPWallHpRecoveryAdd()
    return self:GetCurrentVipConfig().wallHpRecoveryAdd
end
function User:GetVIPDragonExpAdd()
    return self:GetCurrentVipConfig().dragonExpAdd
end
function User:GetVIPDragonHpRecoveryAdd()
    return self:GetCurrentVipConfig().dragonHpRecoveryAdd
end
function User:GetVIPSoldierAttackPowerAdd()
    return self:GetCurrentVipConfig().soldierAttackPowerAdd
end
function User:GetVIPSoldierHpAdd()
    return self:GetCurrentVipConfig().soldierHpAdd
end
function User:GetVIPDragonLeaderShipAdd()
    return self:GetCurrentVipConfig().dragonLeaderShipAdd
end
function User:GetVIPSoldierConsumeSub()
    return self:GetCurrentVipConfig().soldierConsumeSub
end
local vip_level = GameDatas.Vip.level
function User:GetSpecialVipLevelExp(level)
    local level = #vip_level >= level and level or #vip_level
    return vip_level[level].expFrom
end
function User:GetSpecialVipLevelExpTo(level)
    local level = #vip_level >= level and level or #vip_level
    return vip_level[level].expTo
end
function User:GetCurrentVipConfig(level)
    return self:IsVIPActived() and vip_level[self:GetVipLevel()] or vip_level[0]
end
function User:IsVIPActived()
    local vipEvent = self.vipEvents[1]
    if vipEvent then
        local left = vipEvent.finishTime / 1000 - app.timer:GetServerTime()
        local isactive = left > 0
        return isactive, isactive and left or 0
    end
    return false, 0
end
function User:GetVipBuff()
    return setmetatable({
        coin = 0,
        wood = self:GetVIPWoodProductionAdd(),
        food = self:GetVIPFoodProductionAdd(),
        iron = self:GetVIPIronProductionAdd(),
        stone= self:GetVIPStoneProductionAdd(),
        wallHp = self:GetVIPWallHpRecoveryAdd(),
        citizen= self:GetVIPCitizenRecoveryAdd(),
    }, BUFF_META)
end
--[[end]]



--[[basicinfo begin]]
function User:GetLevel()
    return self:GetPlayerLevelByExp(self.basicInfo.levelExp)
end
function User:GetVipLevel()
    return DataUtils:getPlayerVIPLevel(self.basicInfo.vipExp)
end
local intInit = GameDatas.PlayerInitData.intInit
local desertAttackAddPercent_value = intInit.desertAttackAddPercent.value/100
function User:GetTerrainAttackBuff(soldierName)
    if self.basicInfo.terrain == "desert" then
        return {
            {"*", "infantry", desertAttackAddPercent_value},
            {"*",   "archer", desertAttackAddPercent_value},
            {"*",  "cavalry", desertAttackAddPercent_value},
            {"*",    "siege", desertAttackAddPercent_value},
            {"*",     "wall", desertAttackAddPercent_value},
        }
    end
    return {}
end
local intInit = GameDatas.PlayerInitData.intInit
local iceFieldDefenceAddPercent_value = intInit.iceFieldDefenceAddPercent.value/100
function User:GetTerrainDefenceBuff()
    if self.basicInfo.terrain == "iceField" then
        return {
            {"*", "hp", iceFieldDefenceAddPercent_value},
        }
    end
    return {}
end
local intInit = GameDatas.PlayerInitData.intInit
local grassLandFoodAddPercent_value = intInit.grassLandFoodAddPercent.value/100
local grassLandWoodAddPercent_value = intInit.grassLandWoodAddPercent.value/100
local grassLandIronAddPercent_value = intInit.grassLandIronAddPercent.value/100
local grassLandStoneAddPercent_value = intInit.grassLandStoneAddPercent.value/100
function User:GetTerrainResourceBuff()
    local buff = {
        food = 0,
        wood = 0,
        iron = 0,
        stone= 0,
        coin = 0,
        wallHp = 0,
        citizen= 0,
    }
    if self.basicInfo.terrain == "grassLand" then
        buff.food = grassLandFoodAddPercent_value
        buff.wood = grassLandWoodAddPercent_value
        buff.iron = grassLandIronAddPercent_value
        buff.stone= grassLandStoneAddPercent_value
    end
    return setmetatable(buff, BUFF_META)
end

--[[end]]


local config_playerLevel = GameDatas.PlayerInitData.playerLevel
function User:GetPlayerLevelByExp(exp)
    exp = checkint(exp)
    for i=#config_playerLevel,1,-1 do
        local config_ = config_playerLevel[i]
        if exp >= config_.expFrom then return config_.level end
    end
    return 0
end
function User:GetCurrentLevelExp(level)
    return config_playerLevel[level].expFrom
end
function User:GetCurrentLevelMaxExp(level)
    local config = config_playerLevel[tonumber(level) + 1]
    if not config then
        return config_playerLevel[level].expTo
    else
        return config.expFrom
    end
end

-- [[material begin]]
-- 检查对应类型的材料是否有超过材料仓库上限
function User:IsMaterialOutOfRange(materials_name, materials_add_map)
    local limit = UtilsForBuilding:GetMaterialDepotLimit(self)[materials_name]
    for k,v in pairs(self[materials_name]) do
        if v >= limit then
            if not materials_add_map or materials_add_map[k] then
                return true
            end
        end
    end
end
local DragonEquipments_equipments = GameDatas.DragonEquipments.equipments
function User:IsAbleToMakeEquipment(equip_name)
    local equip_config = DragonEquipments_equipments[equip_name]
    local matrials = LuaUtils:table_map(string.split(equip_config.materials, ","), function(k, v)
        return k, string.split(v, ":")
    end)
    local dm = self.dragonMaterials
    for k,v in pairs(matrials) do
        local mk,mn = unpack(v)
        if dm[mk] < tonumber(mn) then
            return false
        end
    end
    return true
end
--[[end]]



--[[treat begin]]
function User:GetTreatTime(soldiers)
    local treat_time = 0
    for _,v in pairs(soldiers) do
        local config = self:GetSoldierConfig(v.name)
        total_iron = total_iron + config.treatTime * v.count
    end
    return treat_time
end
function User:GetTreatCoin(soldiers)
    local treatCoin = 0
    for _,v in pairs(soldiers) do
        local config = self:GetSoldierConfig(v.name)
        treatCoin = treatCoin + config.treatCoin * v.count
    end
    return treatCoin
end
function User:GetTreatAllTime()
    local total_time = 0
    for soldier_name,count in pairs(self.woundedSoldiers) do
        local config = self:GetSoldierConfig(soldier_name)
        total_time = total_time + config.treatTime * count
    end
    return total_time
end
function User:GetTreatCitizen()
    local total_citizen = 0
    for soldier_name,count in pairs(self.woundedSoldiers) do
        local config = self:GetSoldierConfig(soldier_name)
        total_citizen = total_citizen + config.citizen * count
    end
    return total_citizen
end
function User:CanTreat(soldiers)
    local resource_state = self:GetResValueByType("coin") < self:GetTreatCoin(soldiers)
    if #self.treatSoldierEvents > 0 and resource_state then
        return false, "treating_and_lack_resource"
    elseif #self.treatSoldierEvents > 0 then
        return false, "treating"
    elseif resource_state then
        return false, "lack_resource"
    end
    return true
end
function User:GetNormalTreatGems(soldiers)
    local total_coin = self:GetTreatCoin(soldiers)
    local value = self:GetResValueByType("coin")
    local resource_state = value < total_coin
    local need_gems = 0
    if resource_state then
        need_gems = DataUtils:buyResource({coin=total_coin},{coin = value})
    end
    if #self.treatSoldierEvents > 0 then
        local time = UtilsForEvent:GetEventInfo(self.treatSoldierEvents[1])
        need_gems = need_gems + DataUtils:getGemByTimeInterval(time)
    end
    return need_gems
end
--[[end]]


--[[soldier begin]]
function User:IsSoldierUnlocked(soldierName)
    return (self:GetSoldierConfig(soldierName).needBarracksLevel or math.huge) 
        <= self:GetBarracksLevel()
end
function User:GetSoldierEventsBySeq()
    local events = {}
    for _,v in ipairs(self.soldierEvents) do
        table.insert(events, v)
    end
    table.sort(events, function(a, b)
        return (a.finishTime - a.startTime) < (b.finishTime - b.startTime)
    end)
    return events
end
function User:GetBuildingSoldiersInfo(building)
    if building == "trainingGround" then
        return {
            { "swordsman_1", self:SoldierStarByName("swordsman_1") },
            { "swordsman_2", self:SoldierStarByName("swordsman_2") },
            { "swordsman_3", self:SoldierStarByName("swordsman_3") },
            {  "sentinel_1",  self:SoldierStarByName("sentinel_1") },
            {  "sentinel_2",  self:SoldierStarByName("sentinel_2") },
            {  "sentinel_3",  self:SoldierStarByName("sentinel_3") },
        }
    elseif building == "stable" then
        return {
            {      "lancer_1",      self:SoldierStarByName("lancer_1") },
            {      "lancer_2",      self:SoldierStarByName("lancer_2") },
            {      "lancer_3",      self:SoldierStarByName("lancer_3") },
            { "horseArcher_1", self:SoldierStarByName("horseArcher_1") },
            { "horseArcher_2", self:SoldierStarByName("horseArcher_2") },
            { "horseArcher_3", self:SoldierStarByName("horseArcher_3") },
        }
    elseif building == "hunterHall" then
        return {
            {      "ranger_1",      self:SoldierStarByName("ranger_1") },
            {      "ranger_2",      self:SoldierStarByName("ranger_2") },
            {      "ranger_3",      self:SoldierStarByName("ranger_3") },
            { "crossbowman_1", self:SoldierStarByName("crossbowman_1") },
            { "crossbowman_2", self:SoldierStarByName("crossbowman_2") },
            { "crossbowman_3", self:SoldierStarByName("crossbowman_3") },
        }
    elseif building == "workshop" then
        return {
            { "catapult_1", self:SoldierStarByName("catapult_1") },
            { "catapult_2", self:SoldierStarByName("catapult_2") },
            { "catapult_3", self:SoldierStarByName("catapult_3") },
            { "ballista_1", self:SoldierStarByName("ballista_1") },
            { "ballista_2", self:SoldierStarByName("ballista_2") },
            { "ballista_3", self:SoldierStarByName("ballista_3") },
        }
    end
    assert(false)
end
function User:GetSoldierUpkeep()
    local total = 0
    for soldier_name,count in pairs(self.soldiers) do
        total = total + self:GetSoldierConfig(soldier_name).consumeFoodPerHour * count
    end
    -- item效果
    if self:IsItemEventActive("quarterMaster") then
        total = math.ceil(total * (1 - UtilsForItem:GetItemBuff("quarterMaster")))
    end
    -- vip效果
    if self:IsVIPActived() then
        total = total * (1-self:GetVIPSoldierConsumeSub())
    end
    return total
end
local soldiers_normal = GameDatas.Soldiers.normal
local soldiers_special = GameDatas.Soldiers.special
function User:GetSoldierConfig(soldier_name)
    return  UtilsForSoldier:IsSpecial(soldier_name)
        and soldiers_special[soldier_name]
        or soldiers_normal[soldier_name.."_"..self:SoldierStarByName(soldier_name)]
end
function User:SoldierStarByName(soldier_name)
    return  UtilsForSoldier:IsSpecial(soldier_name)
        and soldiers_special[soldier_name].star
        or self.soldierStars[soldier_name] or 1
end
function User:HasAnyWoundedSoldiers()
    for _,count in pairs(self.woundedSoldiers) do
        if count > 0 then
            return true
        end
    end
end
function User:GetStarEventBy(building)
    for _,event in ipairs(self.soldierStarEvents) do
        if UtilsForSoldier:SoldierBelongBuilding(event.name) == building then
            return event
        end
    end
end
local seq_map = Enum("infantry", "archer", "cavalry", "siege", "hpAdd")
function User:GetMilitaryTechsByBuilding(building)
    local techs = {}
    for name, tech in pairs(self.militaryTechs) do
        if building == tech.building then
            local _,focus_field = unpack(string.split(name,"_"))
            local seq_index = seq_map[focus_field]
            assert(seq_index)
            techs[seq_index] = {name, tech}
        end
    end
    return techs
end
function User:HasAnyMilitaryTechEvent()
    return LuaUtils:table_size(self.militaryTechEvents) > 0
        or LuaUtils:table_size(self.soldierStarEvents) > 0
end
function User:GetTotalMilitaryTechEventsNumber()
    local count = LuaUtils:table_size(self.militaryTechEvents) + LuaUtils:table_size(self.soldierStarEvents)
    return count > 4 and 4 or count
end
function User:GetMilitaryTechEventsNumber(building)
    local count = 0
    for _,event in pairs(self.militaryTechEvents) do
        if self.militaryTechs[event.name].building == building then
            count = count + 1
        end
    end
    for _,event in pairs(self.soldierStarEvents) do
        if UtilsForSoldier:SoldierBelongBuilding(event.name) == building then
            count = count + 1
        end
    end
    return count
end
function User:GetMilitaryTechEventBy(building)
    for _,event in pairs(self.militaryTechEvents) do
        if self.militaryTechs[event.name].building == building then
            return event
        end
    end
end
function User:GetMilitaryTechLevel(tech_name)
    return self.militaryTechs[tech_name].level
end
function User:GetShortestTechEvent()
    local shortest_event
    local time = math.huge
    for _,event in ipairs(self.soldierStarEvents) do
        local l = event.finishTime - event.startTime
        if l < time then
            shortest_event = event
            time = l
        end
    end
    for _,event in ipairs(self.militaryTechEvents) do
        local l = event.finishTime - event.startTime
        if l < time then
            shortest_event = event
            time = l
        end
    end
    for _,event in ipairs(self.productionTechEvents) do
        local l = event.finishTime - event.startTime
        if l < time then
            shortest_event = event
            time = l
        end
    end
    return shortest_event
end
function User:GetShortestMilitaryTechEvent()
    local shortest_event
    local time = math.huge
    for _,event in ipairs(self.militaryTechEvents) do
        local l = event.finishTime - event.startTime
        if l < time then
            shortest_event = event
            time = l
        end
    end
    for _,event in ipairs(self.soldierStarEvents) do
        local l = event.finishTime - event.startTime
        if l < time then
            shortest_event = event
            time = l
        end
    end
    return shortest_event
end
function User:GetShortMilitaryTechEventBy(building)
    local event1 = self:GetMilitaryTechEventBy(building)
    local event2 = self:GetStarEventBy(building)
    return (event1 and event1.startTime or 0)
        > (event2 and event2.startTime or 0)
        and event1 or event2
end
function User:GetShortMilitaryTechEventTime(building)
    local event = self:GetShortMilitaryTechEventBy(building)
    if event then
        return event.finishTime/1000 - app.timer:GetServerTime()
    end
    return 0
end
function User:GetMilitaryBuff()
    local all_military_buff = {}
    for name,tech in pairs(self.militaryTechs) do
        if tech.level > 0 then
            local effect_soldier,buff_field = unpack(string.split(name,"_"))
            table.insert(all_military_buff,{
                effect_soldier,
                buff_field,
                UtilsForTech:GetEffect(name, tech)
            })
        end
    end
    return all_military_buff
end
local militaryTechs = GameDatas.MilitaryTechs.militaryTechs
function User:GetTechPoints(building)
    local tech_points = 0
    for k,v in pairs(self:GetMilitaryTechsByBuilding(building)) do
        local name, tech = unpack(v)
        tech_points = tech_points + militaryTechs[name].techPointPerLevel * tech.level
    end
    return tech_points
end
function User:HasMilitaryTechEventBy(building)
    for _,event in pairs(self.militaryTechEvents) do
        if militaryTechs[event.name].building == building then
            return true
        end
    end
    for _,event in pairs(self.soldierStarEvents) do
        if UtilsForSoldier:SoldierBelongBuilding(event.name) == building then
            return true
        end
    end
end
function User:GetPromotionName(building)
    local event = self:GetStarEventBy(building)
    if event then
        return event.name
    end
end
local MilitaryTechLevelUp = GameDatas.MilitaryTechLevelUp
function User:GetMilitaryTechUpgradeTime(tech_name, level)
    return MilitaryTechLevelUp[tech_name][level + 1].buildTime
end
function User:CanUpgradeNow(tech_name, tech)
    return self:GetInstantUpgradeMilitaryTechGems(tech_name, tech) >= self:GetGemValue()
end
function User:GetNormalUpgradeMilitaryTechGems(tech_name, tech)
    local config = MilitaryTechLevelUp[tech_name][tech.level+1]
    local required = {
        resources = {
            coin = config.coin,
        },
        materials = {
            trainingFigure = config.trainingFigure,
            bowTarget      = config.bowTarget,
            saddle         = config.saddle,
            ironPart       = config.ironPart
        },
    }
    local has_materials = self.technologyMaterials
    local has = {
        resources = {
            coin = self:GetResValueByType("coin"),
        },
        materials={
            trainingFigure = has_materials.trainingFigure,
            bowTarget      = has_materials.bowTarget,
            saddle         = has_materials.saddle,
            ironPart       = has_materials.ironPart
        },
    }
    -- 正在升级的军事科技剩余升级时间
    local left_time = self:GetShortMilitaryTechEventTime(tech.building)
    return DataUtils:buyResource(required.resources, has.resources) + DataUtils:buyMaterial(required.materials, has.materials) + DataUtils:getGemByTimeInterval(left_time)
end
function User:GetInstantUpgradeMilitaryTechGems(tech_name, tech)
    local config = MilitaryTechLevelUp[tech_name][tech.level+1]
    local required = {
        resources = {
            coin = config.coin,
        },
        materials = {
            trainingFigure = config.trainingFigure,
            bowTarget      = config.bowTarget,
            saddle         = config.saddle,
            ironPart       = config.ironPart
        },
        buildTime = config.buildTime
    }
    return DataUtils:buyResource(required.resources, {}) + DataUtils:buyMaterial(required.materials, {}) + DataUtils:getGemByTimeInterval(required.buildTime)
end
function User:CanUpgrade(tech_name, tech)
    local level_up_config = MilitaryTechLevelUp[tech_name][tech.level + 1]
    local has_materials = self.technologyMaterials
    local current_coin = self:GetResValueByType("coin")

    local results = {}
    if self:HasMilitaryTechEventBy(tech.building) then
        table.insert(results, _("升级军事科技队列被占用"))
    end
    if current_coin < level_up_config.coin then
        table.insert(results, string.format( _("银币不足 需要补充 %d"), level_up_config.coin - current_coin ) )
    end
    if has_materials.trainingFigure < level_up_config.trainingFigure then
        table.insert(results, string.format( _("木人桩 需要补充 %d"), level_up_config.trainingFigure - has_materials.trainingFigure ) )
    end
    if has_materials.bowTarget < level_up_config.bowTarget then
        table.insert(results, string.format( _("箭靶 需要补充 %d"), level_up_config.bowTarget - has_materials.bowTarget ) )
    end
    if has_materials.saddle < level_up_config.saddle then
        table.insert(results, string.format( _("马鞍 需要补充 %d"), level_up_config.saddle - has_materials.saddle ) )
    end
    if has_materials.ironPart < level_up_config.ironPart then
        table.insert(results, string.format( _("精铁零件 需要补充 %d"), level_up_config.ironPart - has_materials.ironPart ) )
    end

    return results
end
--[[end]]


--[[begin productionTechs]]
local productionTechs = GameDatas.ProductionTechs.productionTechs
function User:GetTechReduceTreatTime(time)
    return math.ceil(self.productionTechs["healingAgent"].level * productionTechs["healingAgent"].effectPerLevel * time)
end
function User:IsTechEnable(tech_name, tech)
    local config = UtilsForTech:GetProductionTechConfig(tech_name)
    local depend_tech_name, depend_tech = self:GetProductionTech(config.unlockBy)
    local config_depend = UtilsForTech:GetProductionTechConfig(depend_tech_name)
    return self:GetAcademyLevel() >= config.academyLevel
        and depend_tech.level >= config_depend.unlockLevel
end
function User:GetProductionTech(index)
    for tech_name,v in pairs(self.productionTechs) do
        if v.index == index then
            return tech_name, v
        end
    end
end
function User:GetProductionTechEff(index)
   local tech_name,v = self:GetProductionTech(index)
   return productionTechs[tech_name].effectPerLevel * v.level
end
function User:HasProductionTechEvent()
    return next(self.productionTechEvents)
end
--[[end]]


--[[buildings begin]]
function User:GetBarracksLevel()
    for k,v in pairs(self.buildings) do
        if v.type == "barracks" then
            return v.level
        end
    end
end
function User:GetAcademyLevel()
    for k,v in pairs(self.buildings) do
        if v.type == "academy" then
            return v.level
        end
    end
end
function User:IsBuildingUnlockedBy(name)
    return next(UtilsForBuilding:GetBuildingsBy(self, name, 1))
end
function User:GetUnlockBuildingsBy(name)
    return UtilsForBuilding:GetBuildingsBy(self, name, 1)
end
function User:GetBuildingByEvent(event)
    if event.location then
        return self:GetBuildingByLocation(event.location)
    end
    return self:GetHouseByLocation(event.buildingLocation, event.houseLocation)
end
function User:GetHouseByLocation(buildingLocation, houseLocation)
    local building = self:GetBuildingByLocation(buildingLocation)
    assert(building)
    for i,v in ipairs(building.houses) do
        if v.location == houseLocation then
            return v
        end
    end
end
function User:GetBuildingByLocation(location)
    return self.buildings[string.format("location_%d", location)]
end
function User:GetBuildingEventByLocation(buildingLocation, houseLocation)
    if houseLocation then
        for i,v in ipairs(self.houseEvents) do
            if v.buildingLocation == buildingLocation
                and v.houseLocation == houseLocation then
                return v
            end
        end
    else
        for i,v in ipairs(self.buildingEvents) do
            if v.location == buildingLocation then
                return v
            end
        end
    end
end
function User:GetBuildingEventsBySeq()
    local events = {}
    for i,v in ipairs(self.houseEvents) do
        table.insert(events, v)
    end
    for i,v in ipairs(self.buildingEvents) do
        table.insert(events, v)
    end
    table.sort(events, function(a, b)
        return (a.finishTime - a.startTime) < (b.finishTime - b.startTime)
    end)
    return events
end
-- local BuildingLevelUp = GameDatas.BuildingLevelUp
-- local HouseLevelUp = GameDatas.HouseLevelUp
-- function User:CanUpgrade(buildingLocation, houseLocation)
--     local building = self:GetHouseByLocation(buildingLocation)
--     if houseLocation then
--         building = self:GetBuildingByLocation(buildingLocation, houseLocation)
--     else
--         building = self:GetHouseByLocation(buildingLocation)
--     end
--     local level = building.level

--     --等级小于0级
--     if level < 0 then
--         return false
--     end
--     local event = self:GetBuildingEventByLocation(buildingLocation, houseLocation)
--     --建筑正在升级
--     if event then
--         return false
--     end
--     local level_up_config = BuildingLevelUp[building.type] or HouseLevelUp[building.type]
--     -- 满级
--     if #level_up_config == level then
--         return false
--     end
--     -- 是否已经解锁内圈
--     local tile = city:GetTileWhichBuildingBelongs(self)
--     if not city:IsUnlockedInAroundNumber(math.max(tile.x,tile.y) - 1) then
--         return UpgradeBuilding.NOT_ABLE_TO_UPGRADE.TILE_NOT_UNLOCKED
--     end
--     -- 是否达到建造上限
--     if city:GetFirstBuildingByType("keep"):GetFreeUnlockPoint() < 1 and self.level==0 then
--         return UpgradeBuilding.NOT_ABLE_TO_UPGRADE.IS_MAX_UNLOCK
--     end
--     local config
--     if self:IsHouse() then
--         config = GameDatas.Houses.houses[self:GetType()]
--     else
--         local location_id = city:GetLocationIdByBuildingType(self:GetType())
--         config = GameDatas.Buildings.buildings[location_id]
--     end
--     -- 等级大于5级时有升级前置条件
--     if self:GetLevel()>5 then
--         local configParams = string.split(config.preCondition,"_")
--         local preType = configParams[1]
--         local preName = configParams[2]
--         local preLevel = tonumber(configParams[3])
--         local limit
--         if preType == "building" then
--             local find_buildings = city:GetBuildingByType(preName)
--             for i,v in ipairs(find_buildings) do
--                 if v:GetLevel()>=self:GetLevel()+preLevel then
--                     limit = true
--                 end
--             end
--         else
--             city:IteratorDecoratorBuildingsByFunc(function (index,house)
--                 if house:GetType() == preName and house:GetLevel()>=self:GetLevel()+preLevel then
--                     limit = true
--                 end
--             end)
--         end
--         if not limit then
--             return UpgradeBuilding.NOT_ABLE_TO_UPGRADE.PRE_CONDITION
--         end
--     end
-- end
--[[end]]


--[[materialEvents begin]]
function User:GetMakingMaterialsEventsBySeq()
    local events = {}
    for i,v in ipairs(self.materialEvents) do
        if v.finishTime ~= 0 then
            table.insert(events, v)
        end
    end
    for i,v in ipairs(self.dragonEquipmentEvents) do
        table.insert(events, v)
    end
    table.sort(events, function(a, b)
        return (a.finishTime - a.startTime) < (b.finishTime - b.startTime)
    end)
    return events
end
function User:GetMakingMaterialsEventCount()
    local count = 0
    for i,v in ipairs(self.materialEvents) do
        if v.finishTime ~= 0 then
            count = count + 1
        end
    end
    return count
end
function User:GetMakingMaterialsEvent(type_)
    for i,v in ipairs(self.materialEvents) do
        if v.finishTime ~= 0 and
            (not type_ or v.type == type_) then
            return v
        end
    end
end
function User:GetStoreMaterialsEvent(type_)
    for i,v in ipairs(self.materialEvents) do
        if v.finishTime == 0 and
            (not type_ or v.type == type_) then
            return v
        end
    end
end
function User:IsStoreMaterials(type_)
    for i,v in ipairs(self.materialEvents) do
        if v.finishTime == 0 and
            (not type_ or v.type == type_) then
            return true
        end
    end
    return false
end
function User:CanMakeMaterials()
    if #self.materialEvents == 0 then
        return true
    end
    if #self.materialEvents == 2 then
        return false
    end
    if self.materialEvents[1].finishTime ~= 0 then
        return false
    end
    return true
end
function User:IsMakingMaterials(type_)
    for i,v in ipairs(self.materialEvents) do
        if v.finishTime ~= 0 and
            (not type_ or v.type == type_) then
            return true
        end
    end
    return false
end
--[[end]]



--[[event begin]]
function User:IsProductionTechEvent(event)
    for i,v in ipairs(self.productionTechEvents) do
        if v.id == event.id then
            return true
        end
    end
end
function User:IsSoldierStarEvent(event)
    for i,v in ipairs(self.soldierStarEvents) do
        if v.id == event.id then
            return true
        end
    end
end
function User:IsMilitaryTechEvent(event)
    for i,v in ipairs(self.militaryTechEvents) do
        if v.id == event.id then
            return true
        end
    end
end
local can_helped_event_key = {
    "buildingEvents",
    "houseEvents",
    "productionTechEvents",
    "militaryTechEvents",
    "soldierStarEvents",
}
function User:IsRequestHelped(id)
    local user_data = DataManager:getUserData()
    for _,event_key in ipairs(can_helped_event_key) do
        for _,event in ipairs(self[event_key]) do
            if event.id == id and event.helped then
                return true
            end
        end
    end
    return false
end
function User:GetEventById(id)
    for i,v in ipairs(self.militaryTechEvents) do
        if v.id == id then
            return v
        end
    end
    for i,v in ipairs(self.soldierEvents) do
        if v.id == id then
            return v
        end
    end
    for i,v in ipairs(self.soldierStarEvents) do
        if v.id == id then
            return v
        end
    end
    for i,v in ipairs(self.treatSoldierEvents) do
        if v.id == id then
            return v
        end
    end
    assert(false)
end
function User:EventType(event)
    for i,v in ipairs(self.militaryTechEvents) do
        if v.id == event.id then
            return "militaryTechEvents"
        end
    end
    for i,v in ipairs(self.soldierEvents) do
        if v.id == event.id then
            return "soldierEvents"
        end
    end
    for i,v in ipairs(self.soldierStarEvents) do
        if v.id == event.id then
            return "soldierStarEvents"
        end
    end
    for i,v in ipairs(self.treatSoldierEvents) do
        if v.id == event.id then
            return "treatSoldierEvents"
        end
    end
    assert(false)
end
--[[end]]

--[[helpToTroops begin]]
function User:IsHelpedToPlayer(id)
    for _,v in ipairs(self.helpToTroops) do
        if v.beHelpedPlayerData.id == id then
            return true
        end
    end
end
--[[end]]


--[[production begin]]
local playerCitizenRecoverFullNeedHours_value = GameDatas.
    PlayerInitData.
    intInit.
    playerCitizenRecoverFullNeedHours.value
function User:RefreshOutput()
    local wall_info = UtilsForBuilding:GetWallInfo(self)

    local production = UtilsForBuilding:GetHouseProductions(self)
    production.wallHp = wall_info.wallRecovery
    local buff_building = UtilsForBuilding:GetBuildingsBuff(self)
    local buff_tech     = UtilsForTech:GetBuff(self)
    local buff_item     = UtilsForItem:GetBuff(self)
    local buff_vip      = self:GetVipBuff()
    local buff_terrain  = self:GetTerrainResourceBuff()
    production = production * (1 + buff_building + buff_item + buff_tech + buff_vip + buff_terrain)

    local limits = UtilsForBuilding:GetWarehouseLimit(self)
    local limits_map = setmetatable({
        coin = math.huge,
        wood = limits.maxWood,
        food = limits.maxFood,
        iron = limits.maxIron,
        stone= limits.maxStone,
        wallHp = wall_info.wallHp,
        citizen= UtilsForBuilding:GetCitizenLimit(self),
    }, BUFF_META)
    local buff_limit = UtilsForTech:GetLimitBuff(self)
    limits_map = limits_map * (1 + buff_limit)

    for k,v in pairs(limits_map) do
        local res = self.resources_cache[k]
        if k == "citizen" then
            res.limit = v - UtilsForBuilding:GetCitizenMap(self).total
        else
            res.limit = v
        end
    end

    for k,v in pairs(production) do
        local res = self.resources_cache[k]
        if k == "food" then
            res.output = math.floor(v - self:GetSoldierUpkeep())
        else
            res.output = math.floor(v)
        end
    end
    local citizen = self:GetResProduction("citizen")
    citizen.output = math.floor(citizen.limit / playerCitizenRecoverFullNeedHours_value)
    local cart = self:GetResProduction("cart")
    local tradeGuild_info = UtilsForBuilding:GetTradeGuildInfo(self)
    cart.limit = tradeGuild_info.maxCart
    cart.output = tradeGuild_info.cartRecovery

    -- dump(self.resources, "self.user.resources_cache")
    -- dump(self.resources_cache, "self.user.resources_cache")
end
--[[end]]


--[[dragons begin]]
function User:GetDefenceDragonType()
    for k,v in pairs(self.dragons or {}) do
        if v.status == "defence" then
            return k
        end
    end
end
--[[end]]



local before_map = {
    basicInfo = function(userData, deltaData)
        local ok, value = deltaData("basicInfo.name")
        if ok then
            if Alliance_Manager and
                not Alliance_Manager:GetMyAlliance():IsDefault()
                and Alliance_Manager:GetMyAlliance():GetMemeberById(userData._id)
            then
                Alliance_Manager:GetMyAlliance():GetMemeberById(userData._id).name = value
            end
        end
    end,
    items = function()end,
    resources = function(userData, deltaData)
        userData:RefreshOutput()
    end,
    countInfo = function()end,
    deals = function()end,
    allianceData = function()end,
    iapGifts = function()end,
    growUpTasks = function()end,
    allianceDonate = function()end,
    dailyTasks = function()end,
    dailyQuests = function()end,
    itemEvents = function(userData, deltaData)
        userData:RefreshOutput()
    end,
    helpedByTroops = function()end,
    helpToTroops = function()end,


    buildings = function(userData, deltaData)
        userData:RefreshOutput()
    end,
    houseEvents = function(userData, deltaData)
        userData:RefreshOutput()

        local ok, value = deltaData("houseEvents.remove")
        if ok then
            for i,v in ipairs(value) do
                app:GetPushManager():CancelBuildPush(v.id)
                local house = userData:GetHouseByLocation(v.buildingLocation, v.houseLocation)
                GameGlobalUI:showTips(_("提示"),
                    string.format(_("建造%s至%d级完成"),
                        Localize.building_name[house.type], house.level))
            end
        end

        local ok, value = deltaData("houseEvents.edit")
        if ok then
            for i,v in ipairs(value) do
                userData:HouseLocalPush(v)
            end
        end
    end,
    buildingEvents = function(userData, deltaData)
        userData:RefreshOutput()

        local ok, value = deltaData("buildingEvents.remove")
        if ok then
            for i,v in ipairs(value) do
                app:GetPushManager():CancelBuildPush(v.id)
                local building = userData:GetBuildingByLocation(v.location)
                GameGlobalUI:showTips(_("提示"),
                    string.format(_("建造%s至%d级完成"),
                        Localize.building_name[building.type], building.level))
            end
        end

        local ok, value = deltaData("buildingEvents.edit")
        if ok then
            for i,v in ipairs(value) do
                userData:BuildingLocalPush(v)
            end
        end
    end,

    productionTechs = function(userData, deltaData)
        userData:RefreshOutput()
    end,
    productionTechEvents = function(userData, deltaData)
        userData:RefreshOutput()
        local ok, value = deltaData("productionTechEvents.remove")
        if ok then
            for i,v in ipairs(value) do
                app:GetPushManager():CancelTechnologyPush(v.id)
                GameGlobalUI:showTips(
                    _("生产科技升级完成"),
                    Localize.productiontechnology_name[v.name]
                    .."Lv"..userData.productionTechs[v.name].level)
            end
        end

        local ok, value = deltaData("productionTechEvents.edit")
        if ok then
            for i,v in ipairs(value) do
                userData:ProductTechLocalPush(v)
            end
        end

    end,

    militaryTechs = function(userData, deltaData)
        userData:RefreshOutput()
    end,
    militaryTechEvents = function(userData, deltaData)
        userData:RefreshOutput()

        local militaryTechs = userData.militaryTechs
        local ok, value = deltaData("militaryTechEvents.remove")
        if ok then
            for i,v in ipairs(value) do
                app:GetPushManager():CancelTechnologyPush(v.id)
                GameGlobalUI:showTips(_("军事科技升级完成"),
                    UtilsForTech:GetTechLocalize(v.name)
                    .."Lv"..militaryTechs[v.name].level)
            end
        end

        local ok, value = deltaData("militaryTechEvents.edit")
        if ok then
            for i,v in ipairs(value) do
                userData:MilitaryLocalPush(v)
            end
        end
    end,

    soldiers = function(userData, deltaData)
        userData:RefreshOutput()
    end,
    soldierEvents = function(userData, deltaData)
        local ok, value = deltaData("soldierEvents.remove")
        if ok then
            for i,v in ipairs(value) do
                app:GetPushManager():CancelSoldierPush(v.id)
                GameGlobalUI:showTips(_("招募士兵完成"),
                    Localize.soldier_name[v.name].."X"..v.count)
            end
        end

        local ok, value = deltaData("soldierEvents.edit")
        if ok then
            for i,v in ipairs(value) do
                userData:RecruitLocalPush(v)
            end
        end
    end,

    woundedSoldiers = function(userData, deltaData)
        userData:RefreshOutput()
    end,
    treatSoldierEvents = function(userData, deltaData)
        local ok, value = deltaData("treatSoldierEvents.remove")
        if ok then
            for i,v in ipairs(value) do
                app:GetPushManager():CancelSoldierPush(v.id)
                local soldiers_info = {}
                for i,soldier in ipairs(v.soldiers) do
                    table.insert(soldiers_info,
                        Localize.soldier_name[soldier.name]
                        .."X"..soldier.count)
                end
                GameGlobalUI:showTips(_("治愈士兵完成"),
                    table.concat(soldiers_info, ","))
            end
        end

        local ok, value = deltaData("treatSoldierEvents.edit")
        if ok then
            for i,v in ipairs(value) do
                userData:TreatLocalPush(v)
            end
        end
    end,

    soldierStars = function(userData, deltaData)
        userData:RefreshOutput()
    end,
    soldierStarEvents = function(userData, deltaData)
        local ok, value = deltaData("soldierStarEvents.remove")
        if ok then
            for i,v in ipairs(value) do
                app:GetPushManager():CancelSoldierPush(v.id)
                GameGlobalUI:showTips(
                    _("士兵晋级完成"),
                    string.format(
                        _("晋级%s至%d星完成"),
                        Localize.soldier_name[v.name],
                        userData.soldierStars[v.name]
                    )
                )
            end
        end

        local ok, value = deltaData("soldierStarEvents.edit")
        if ok then
            for i,v in ipairs(value) do
                userData:StarLocalPush(v)
            end
        end
    end,

    dragons = function()end,
    dragonEquipments = function()end,
    dragonEquipmentEvents = function(userData, deltaData)
        local ok, value = deltaData("dragonEquipmentEvents.remove")
        if ok then
            for k,v in ipairs(value) do
                app:GetPushManager():CancelToolEquipmentPush(v.id)
                GameGlobalUI:showTips(_("制造装备完成"),
                    Localize.equip[v.name].."X1")
            end
        end
        local ok, value = deltaData("dragonEquipmentEvents.edit")
        if ok then
            for i,v in ipairs(value) do
                userData:EquipLocalPush(v)
            end
        end
    end,

    dragonMaterials = function()end,
    soldierMaterials = function()end,
    buildingMaterials = function()end,
    technologyMaterials = function()end,
    materialEvents = function(userData, deltaData)
        local ok, value = deltaData("materialEvents.edit")
        if ok then
            for k,v in ipairs(value) do
                if v.finishTime == 0 then
                    app:GetPushManager():CancelToolEquipmentPush(v.id)
                    local material_info = {}
                    for i,m in ipairs(v.materials) do
                        table.insert(material_info,
                            Localize.materials[m.name].."X"..m.count)
                    end
                    GameGlobalUI:showTips(_("制造材料完成"),
                        table.concat(material_info, ","))
                else
                    userData:MaterialLocalPush(v)
                end
            end
        end
    end,

    dailyQuestEvents = function(userData, deltaData)
        local ok, value = deltaData("dailyQuestEvents.edit")
        if ok then
            for k,v in pairs(value) do
                if v.finishTime == 0 then
                    GameGlobalUI:showTips(_("提示"),
                        string.format(_("每日任务%s完成"),
                            Localize.daily_quests_name[v.index]))
                end
            end
        end
    end,
    vipEvents = function(userData, deltaData)
        userData:RefreshOutput()
    end,
}
local after_map = {
    growUpTasks = function(userData)
        if userData.reward_callback and
            UtilsForTask:IsGetAnyCityBuildRewards(userData.growUpTasks) then
            userData.reward_callback()
            userData.reward_callback = nil
        end
    end,
}
function User:OnUserDataChanged(userData, deltaData)
    for k,v in pairs(userData) do
        self[k] = v
    end
    return self
end
function User:OnDeltaDataChanged(deltaData)
    if deltaData then
        for i,k in ipairs(User.LISTEN_TYPE) do
            local before_func = before_map[k]
            if type(k) == "string" and before_func then
                if deltaData(k) then
                    before_func(self, deltaData)
                    local notify_function_name = string.format("OnUserDataChanged_%s", k)
                    self:NotifyListeneOnType(User.LISTEN_TYPE[k], function(listener)
                        local func = listener[notify_function_name]
                        if func then
                            func(listener, self, deltaData)
                        end
                    end)
                    local after_func = after_map[k]
                    if after_func then
                        after_func(self, deltaData)
                    end
                end
            end
        end
    end
end
function User:GeneralLocalPush()
    local push_man = app:GetPushManager()
    for id,func in pairs(self.local_push_map or {}) do
        func(push_man, id)
    end
    self.local_push_map = {}

    -- jianzhu
    for i,v in ipairs(self.houseEvents) do
        self:HouseLocalPush(v)
    end
    for i,v in ipairs(self.buildingEvents) do
        self:BuildingLocalPush(v)
    end

    -- shibing
    for i,v in ipairs(self.soldierEvents) do
        self:RecruitLocalPush(v)
    end
    for i,v in ipairs(self.soldierStarEvents) do
        self:StarLocalPush(v)
    end
    for i,v in ipairs(self.treatSoldierEvents) do
        self:TreatLocalPush(v)
    end

    -- keji
    for i,v in ipairs(self.militaryTechEvents) do
        self:MilitaryLocalPush(v)
    end
    for i,v in ipairs(self.productionTechs) do
        self:ProductTechLocalPush(v)
    end

    -- cailiao
    for i,v in ipairs(self.materialEvents) do
        self:MaterialLocalPush(v)
    end
    for i,v in ipairs(self.dragonEquipmentEvents) do
        self:EquipLocalPush(v)
    end
end
function User:HouseLocalPush(event)
    local push_man = app:GetPushManager()
    self.local_push_map = self.local_push_map or {}
    local building = self:GetBuildingByEvent(event)
    local title = string.format(_("修建%s到LV%d完成"),
        Localize.getLocaliedKeyByType(building.type),
        (building.level + 1))
    push_man:UpdateBuildPush(event.finishTime/1000, title, event.id)
    self.local_push_map[event.id] = push_man.CancelBuildPush
end
function User:BuildingLocalPush(event)
    local push_man = app:GetPushManager()
    self.local_push_map = self.local_push_map or {}
    local building = self:GetBuildingByEvent(event)
    local title = string.format(_("修建%s到LV%d完成"),
        Localize.getLocaliedKeyByType(building.type),
        (building.level + 1))
    push_man:UpdateBuildPush(event.finishTime/1000, title, event.id)
    self.local_push_map[event.id] = push_man.CancelBuildPush
end
function User:RecruitLocalPush(event)
    local push_man = app:GetPushManager()
    self.local_push_map = self.local_push_map or {}
    local title = string.format(_("招募%s X%d完成"),
        Localize.soldier_name[event.name],event.count)
    push_man:UpdateSoldierPush(event.finishTime/1000, title, event.id)
    self.local_push_map[event.id] = push_man.CancelSoldierPush
end
function User:StarLocalPush(event)
    local push_man = app:GetPushManager()
    self.local_push_map = self.local_push_map or {}
    local title = string.format(_("晋升%s的星级 star %d完成"),
        Localize.soldier_name[event.name],
        self.soldierStars[event.name])
    push_man:UpdateSoldierPush(event.finishTime/1000, title, event.id)
    self.local_push_map[event.id] = push_man.CancelSoldierPush
end
function User:TreatLocalPush(event)
    local push_man = app:GetPushManager()
    self.local_push_map = self.local_push_map or {}
    local soldiers_info = {}
    for i,v in ipairs(event.soldiers) do
        table.insert(soldiers_info,
            string.format(_("%s X %d "),
                Localize.soldier_name[v.name], v.count))
    end
    local title = string.format(_("治愈%s完成"), table.concat(soldiers_info, ","))
    push_man:UpdateSoldierPush(event.finishTime/1000, title, event.id)
    self.local_push_map[event.id] = push_man.CancelSoldierPush
end
function User:MilitaryLocalPush(event)
    local push_man = app:GetPushManager()
    self.local_push_map = self.local_push_map or {}
    local title = UtilsForEvent:GetMilitaryTechEventLocalize(event.name,
        self.militaryTechs[event.name].level)
    push_man:UpdateTechnologyPush(event.finishTime/1000, title, event.id)
    self.local_push_map[event.id] = push_man.CancelTechnologyPush
end
function User:ProductTechLocalPush(event)
    local push_man = app:GetPushManager()
    self.local_push_map = self.local_push_map or {}
    local title = Localize.productiontechnology_buffer_complete[event.name]
    push_man:UpdateTechnologyPush(event.finishTime/1000, title, event.id)
    self.local_push_map[event.id] = push_man.CancelTechnologyPush
end
function User:MaterialLocalPush(event)
    local push_man = app:GetPushManager()
    self.local_push_map = self.local_push_map or {}
    local count = 0
    for k,v in ipairs(event.materials) do
        count = count + v.count
    end
    local title = string.format(_("制造%d个材料完成"), count)
    push_man:UpdateToolEquipmentPush(event.finishTime/1000, title, event.id)
    self.local_push_map[event.id] = push_man.CancelToolEquipmentPush
end
function User:EquipLocalPush(event)
    local push_man = app:GetPushManager()
    self.local_push_map = self.local_push_map or {}
    local title = string.format(_("制造%s装备完成"), Localize.equip[event.name])
    push_man:UpdateToolEquipmentPush(event.finishTime/1000, title, event.id)
    self.local_push_map[event.id] = push_man.CancelToolEquipmentPush
end



function User:OnPropertyChange(property_name, old_value, new_value)
end



--
local promise = import("..utils.promise")
function User:PromiseOfGetCityBuildRewards()
    local p = promise.new()
    self.reward_callback = function()
        p:resolve()
    end
    return p
end

return User






