local BuildingLevelUp = GameDatas.BuildingLevelUp
local GemsPayment = GameDatas.GemsPayment
local HouseLevelUp = GameDatas.HouseLevelUp
local VipLevel = GameDatas.Vip.level
local items = GameDatas.Items
local normal_soldier = GameDatas.Soldiers.normal
local special_soldier = GameDatas.Soldiers.special
local soldier_vs = GameDatas.ClientInitGame.soldier_vs
local buff = GameDatas.AllianceMap.buff
local Localize = import("..utils.Localize")

DataUtils = {}

local string = string
local pow = math.pow
local ceil = math.ceil
local sqrt = math.sqrt
local floor = math.floor
local modf = math.modf
local pairs = pairs
local ipairs = ipairs
local tonumber = tonumber
local round = function(v)
    return floor(v + 0.5)
end

--[[
坐标换算
]]
local intInit = GameDatas.AllianceInitData.intInit
local bigMapLength_value = intInit.bigMapLength.value
local MAP_LEGNTH_WIDTH = bigMapLength_value
local MAP_LEGNTH_HEIGHT = bigMapLength_value
local ALLIANCE_WIDTH, ALLIANCE_HEIGHT = intInit.allianceRegionMapWidth.value, intInit.allianceRegionMapHeight.value
function DataUtils:GetAbsolutePosition(mapIndex, x, y)
    local lx, ly = mapIndex % MAP_LEGNTH_WIDTH, math.floor(mapIndex / MAP_LEGNTH_WIDTH)
    return lx * ALLIANCE_WIDTH + x, ly * ALLIANCE_HEIGHT + y
end
function DataUtils:GetAlliancePosition(x, y)
    local mapIndex = math.floor(x / ALLIANCE_WIDTH) + math.floor(y / ALLIANCE_HEIGHT) * MAP_LEGNTH_WIDTH
    return mapIndex, x % ALLIANCE_WIDTH, y % ALLIANCE_HEIGHT
end
--[[
end
]]

local staminaMax_value = GameDatas.PlayerInitData.intInit.staminaMax.value
local staminaRecoverPerHour_value = GameDatas.PlayerInitData.intInit.staminaRecoverPerHour.value
function getresoutput()
    return {
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
end
local playerCitizenRecoverFullNeedHours_value = GameDatas.
    PlayerInitData.
    intInit.
    playerCitizenRecoverFullNeedHours.value
function DataUtils:GetResOutput(userData)
    local reses = getresoutput()

    local production    = UtilsForBuilding:GetHouseProductions(userData)
    local buff_building = UtilsForBuilding:GetBuildingsBuff(userData)
    local buff_terrain  = UtilsForBuilding:GetTerrainResourceBuff(userData)
    local buff_tech     = UtilsForTech:GetBuff(userData)
    local buff_item     = UtilsForItem:GetBuff(userData)
    local buff_vip      = UtilsForVip:GetVipBuff(userData)

    local wall_info     = UtilsForBuilding:GetWallInfo(userData)
    production.wallHp   = wall_info.wallRecovery

    production = production * (1 + buff_building + buff_item + buff_tech + buff_vip + buff_terrain)

    local limits = UtilsForBuilding:GetWarehouseLimit(userData)
    local limits_map = setmetatable({
        coin = math.huge,
        wood = limits.maxWood,
        food = limits.maxFood,
        iron = limits.maxIron,
        stone= limits.maxStone,
        wallHp = wall_info.wallHp,
        citizen= UtilsForBuilding:GetCitizenLimit(userData),
    }, BUFF_META)
    local buff_limit = UtilsForTech:GetLimitBuff(userData)
    limits_map = limits_map * (1 + buff_limit)

    for k,v in pairs(limits_map) do
        local res = reses[k]
        if k == "citizen" then
            res.limit = v - UtilsForBuilding:GetCitizenMap(userData).total
        else
            res.limit = v
        end
    end
    
    for k,v in pairs(production) do
        local res = reses[k]
        if k == "food" then
            res.output = math.floor(v - UtilsForSoldier:GetSoldierUpkeep(userData))
        else
            res.output = math.floor(v)
        end
    end
    local citizen = reses.citizen
    citizen.output = math.floor(citizen.limit / playerCitizenRecoverFullNeedHours_value)
    local cart = reses.cart
    local tradeGuild_info = UtilsForBuilding:GetTradeGuildInfo(userData)
    cart.limit = tradeGuild_info.maxCart
    cart.output = tradeGuild_info.cartRecovery
    return reses
end

--[[
end
]]


--[[
  获取建筑升级时,需要的资源和道具
]]
function DataUtils:getBuildingUpgradeRequired(buildingType, buildingLevel)
    local house_configs = HouseLevelUp[buildingType]
    local building_configs = BuildingLevelUp[buildingType]
    if building_configs then
        local config = building_configs[buildingLevel]
        return {
            resources={
                wood=config.wood,
                stone=config.stone,
                iron=config.iron,
            },
            materials={
                blueprints=config.blueprints,
                tools=config.tools,
                tiles=config.tiles,
                pulley=config.pulley
            },
            buildTime=config.buildTime
        }
    elseif house_configs then
        local config = house_configs[buildingLevel]
        local next_level = buildingLevel + 1
        next_level = next_level > #house_configs and #house_configs or next_level
        local next_config = house_configs[next_level]
        return {
            resources={
                wood=config.wood,
                stone=config.stone,
                iron=config.iron,
                citizen=next_config.citizen - config.citizen
            },
            materials={
                blueprints=config.blueprints,
                tools=config.tools,
                tiles=config.tiles,
                pulley=config.pulley
            },
            buildTime=config.buildTime
        }
    else
        assert(false)
    end
end

--[[
  购买资源
  @param need
  @param has
]]
function DataUtils:buyResource(need, has)
    local gemUsed = 0
    local totalBuy = {}
    table.foreach(need,function( key,value )
        local config = GemsPayment[key]
        local required = value
        if type(has[key]) == "number" then required = required - has[key] end
        if config and required > 0 then
            local currentBuy = 0
            if key == "citizen" then
                local freeCitizenLimit = User:GetResProduction("citizen").limit
                assert(freeCitizenLimit ~= 0)
                while required > 0 and freeCitizenLimit ~= 0 do
                    local requiredPercent = required / freeCitizenLimit
                    for i=#config,1,-1 do
                        item = config[i]
                        if item.min < requiredPercent then
                            gemUsed = gemUsed + item.gem
                            local citizenBuyed = math.floor(item.resource * freeCitizenLimit)
                            required = required - citizenBuyed
                            currentBuy = currentBuy + citizenBuyed
                            break
                        end
                    end
                end
            else
                while required > 0 do
                    for i=#config,1,-1 do
                        item = config[i]
                        if item.min < required then
                            gemUsed = gemUsed + item.gem
                            required = required - item.resource
                            currentBuy = currentBuy + item.resource
                            break
                        end
                    end
                end
            end
            totalBuy[key] = currentBuy
        end
    end)
    return gemUsed, totalBuy
end

--[[
  购买材料
  @param need
  @param has
]]
function DataUtils:buyMaterial(need, has)
    local usedGem = 0
    table.foreach(need,function( key,value )
        local payment = GemsPayment.material[1]
        if has then
            if type(has[key]) == "number" then
                value = value - has[key]
            end
        end
        -- print(" 需要 购买 ",key,value)
        if value>0 then
            usedGem = usedGem+payment[key]*value
            -- print("买了",value,"花费",payment[key]*value)
        end
    end)
    return usedGem
end

--[[
  根据所缺时间换算成金龙币,并返回金龙币数量
  @param interval
  @returns {number}
]]
function DataUtils:getGemByTimeInterval(interval)
    local gem = 0
    local config = GemsPayment.time
    while interval > 0 do
        for i = #config,1,-1 do
            while config[i].min<interval do
                interval = interval - config[i].speedup
                gem = gem + config[i].gem
            end
        end
    end
    return gem
end
--龙相关计算
local config_dragonLevel = GameDatas.Dragons.dragonLevel
local config_dragonStar = GameDatas.Dragons.dragonStar
local config_dragonSkill = GameDatas.Dragons.dragonSkills
local config_equipments = GameDatas.DragonEquipments.equipments
local config_dragoneyrie = GameDatas.DragonEquipments

function DataUtils:getDragonTotalStrengthFromJson(star,level,skills,equipments)
    local strength,__ = self:getDragonBaseStrengthAndVitality(star,level)
    local buff = self:__getDragonStrengthBuff(skills)
    strength = strength + math.floor(strength * buff)
    for body,equipemt in pairs(equipments) do
        if equipemt.name ~= "" then
            local config = self:getDragonEquipmentConfig(equipemt.name)
            local attribute = self:getDragonEquipmentAttribute(equipemt.type,config.maxStar,equipemt.star)
            strength = attribute and (strength + attribute.strength) or strength
        end
    end
    return strength
end

function DataUtils:getTotalVitalityFromJson(star,level,skills,equipments)
    local __,vitality = self:getDragonBaseStrengthAndVitality(star,level)
    local buff = self:__getDragonVitalityBuff(skills)
    vitality = vitality + math.floor(vitality * buff)
    for body,equipemt in pairs(equipments) do
        if equipemt.name ~= "" then
            local config = self:getDragonEquipmentConfig(equipemt.name)
            local attribute = self:getDragonEquipmentAttribute(equipemt.type,config.maxStar,equipemt.star)
            vitality = attribute and (vitality + attribute.vitality) or vitality
        end
    end
    return vitality
end

function DataUtils:getDragonSkillEffect(level)
    level = checkint(level)
    if config_dragonSkill[level] then
        return config_dragonSkill[level].effect
    end
    return 0
end

function DataUtils:getDragonBaseStrengthAndVitality(star,level)
    star = checkint(star)
    level = checkint(level)
    return config_dragonLevel[level].strength + config_dragonStar[star].initStrength,
        config_dragonLevel[level].vitality + config_dragonStar[star].initVitality
end

function DataUtils:getDragonEquipmentAttribute(body,max_star,star)
    return config_dragoneyrie[body][max_star .. "_" .. star]
end

function DataUtils:getDragonEquipmentConfig(name)
    return config_equipments[name]
end

function DataUtils:__getDragonStrengthBuff(skills)
    for __,v in pairs(skills) do
        if v.name == 'dragonBreath' then
            return self:getDragonSkillEffect(v.level)
        end
    end
    return 0
end

function DataUtils:__getDragonVitalityBuff(skills)
    for __,v in pairs(skills) do
        if v.name == 'dragonBlood' then
            return self:getDragonSkillEffect(v.level)
        end
    end
    return 0
end
--如果有道具加龙属性 这里就还未完成
function DataUtils:getDragonMaxHp(star,level,skills,equipments)
    local vitality = self:getTotalVitalityFromJson(star,level,skills,equipments)
    return vitality * 4
end
-- 通过buff名获得士兵属性字段
function DataUtils:getSoldierBuffFieldFromKey(key)
    if key == 'hpAdd' then
        return 'hp'
    else
        return key
    end
end

-- 获取兵相关的buff信息
-- solider_config:兵详情的配置信息
function DataUtils:getAllSoldierBuffValue(solider_config)
    local result = {}
    local soldier_type = solider_config.type
    local item_buff = UtilsForItem:GetAllSoldierBuffData(User)
    local military_technology_buff = User:GetMilitaryBuff()
    table.insertto(item_buff,military_technology_buff)
    local vip_buff = self:getAllSoldierVipBuffValue()
    table.insertto(item_buff,vip_buff)
    local terrain_attack_buff = User:GetTerrainAttackBuff()
    table.insertto(item_buff,terrain_attack_buff)
    local terrain_defence_buff = User:GetTerrainDefenceBuff()
    table.insertto(item_buff,terrain_defence_buff)
    for __,v in ipairs(item_buff) do
        local effect_soldier,buff_field,buff_value = unpack(v)
        if effect_soldier == soldier_type or effect_soldier == '*' then
            buff_field = self:getSoldierBuffFieldFromKey(buff_field)
            local buff_realy_value = (solider_config[buff_field] or 0 ) * buff_value
            if result[buff_field] then
                result[buff_field] = result[buff_field] + buff_realy_value
            else
                result[buff_field] = buff_realy_value
            end
        end
    end
    return result
end


--获取vip等级对兵种的影响
function DataUtils:getAllSoldierVipBuffValue()
    local buff_table = {}
    --攻击力加成
    local attck_buff = UtilsForVip:GetVipBuffByName(User, "soldierAttackPowerAdd")
    if attck_buff > 0 then
        buff_table = {
            {"*","infantry",attck_buff},
            {"*","archer",attck_buff},
            {"*","cavalry",attck_buff},
            {"*","siege",attck_buff},
            {"*","wall",attck_buff},
        }
    end
    --防御
    local defence_buff = UtilsForVip:GetVipBuffByName(User, "soldierHpAdd")
    if defence_buff > 0 then
        table.insert(buff_table,{"*","hp",defence_buff})
    end
    --维护费用
    local consumeFood_buff = UtilsForVip:GetVipBuffByName(User, "soldierConsumeSub")
    if consumeFood_buff > 0 then
        table.insert(buff_table,{"*","consumeFoodPerHour",consumeFood_buff})
    end
    --行军速度
    local march_buff = UtilsForVip:GetVipBuffByName(User, "marchSpeedAdd")
    if march_buff > 0 then
        table.insert(buff_table,{"*","march",march_buff})
    end
    return buff_table
end

--获取建筑时间的buff
--buildingTime:升级或建造原来的时间
function DataUtils:getBuildingBuff(buildingTime)
    local tech_effect = UtilsForTech:GetEffect("crane", User.productionTechs["crane"])
    return DataUtils:getBuffEfffectTime(buildingTime, tech_effect)
end

local AllianceInitData = GameDatas.AllianceInitData
local AllianceMapSize = {
    width = AllianceInitData.intInit.allianceRegionMapWidth.value,
    height= AllianceInitData.intInit.allianceRegionMapHeight.value
}
local PlayerInitData = GameDatas.PlayerInitData
function DataUtils:getDistance(width,height)
    return math.ceil(math.sqrt(math.pow(width, 2) + math.pow(height, 2)))
end

function DataUtils:getAllianceLocationDistance(fromAllianceDoc, fromLocation, toAllianceDoc, toLocation)
    local getMapIndexLocation = function(mapIndex)
        return {
            x = mapIndex % bigMapLength_value,
            y = math.floor(mapIndex / bigMapLength_value)
        }
    end

    local fromMapIndexLocation = getMapIndexLocation(fromAllianceDoc.mapIndex)
    local toMapIndexLocation = getMapIndexLocation(toAllianceDoc.mapIndex)

    local fromLocation_change = {
        x = fromLocation.x + (fromMapIndexLocation.x * AllianceMapSize.width),
        y = fromLocation.y + (fromMapIndexLocation.y * AllianceMapSize.height)
    }
    local toLocation_change = {
        x = toLocation.x + (toMapIndexLocation.x * AllianceMapSize.width),
        y = toLocation.y + (toMapIndexLocation.y * AllianceMapSize.height)
    }

    local width = math.abs(fromLocation_change.x - toLocation_change.x)
    local height = math.abs(fromLocation_change.y - toLocation_change.y)

    return DataUtils:getDistance(width,height)

        -- local width,height = 0,0
        -- if fromAllianceDoc == toAllianceDoc then
        --     width = math.abs(fromLocation.x - toLocation.x)
        --     height =  math.abs(fromLocation.y - toLocation.y)
        --     return DataUtils:getDistance(width,height)
        -- end
        -- if fromAllianceDoc:GetAllianceFight()['attackAllianceId'] == fromAllianceDoc._id then
        --     local allianceMergeStyle = fromAllianceDoc:GetAllianceFight()['mergeStyle']
        --     if allianceMergeStyle == 'left' then
        --         width = AllianceMapSize.width - fromLocation.x + toLocation.x
        --         height= math.abs(fromLocation.y - toLocation.y)
        --         return DataUtils:getDistance(width,height)
        --     elseif allianceMergeStyle == 'right' then
        --         width = AllianceMapSize.width - toLocation.x + fromLocation.x
        --         height= math.abs(fromLocation.y - toLocation.y)
        --         return DataUtils:getDistance(width,height)
        --     elseif allianceMergeStyle == 'top' then
        --         width = math.abs(fromLocation.x - toLocation.x)
        --         height= AllianceMapSize.height - fromLocation.y + toLocation.y
        --         return DataUtils:getDistance(width,height)
        --     elseif allianceMergeStyle == 'bottom' then
        --         width = math.abs(fromLocation.x - toLocation.x)
        --         height= AllianceMapSize.height - toLocation.y + fromLocation.y
        --         return DataUtils:getDistance(width,height)
        --     else
        --         return 0
        --     end
        -- else
        --     local allianceMergeStyle = fromAllianceDoc:GetAllianceFight()['mergeStyle']
        --     if allianceMergeStyle == 'left' then
        --         width = AllianceMapSize.width - toLocation.x + fromLocation.x
        --         height = math.abs(fromLocation.y - toLocation.y)
        --         return DataUtils:getDistance(width,height)
        --     elseif allianceMergeStyle == 'right' then
        --         width = AllianceMapSize.width - fromLocation.x + toLocation.x
        --         height = math.abs(fromLocation.y - toLocation.y)
        --         return DataUtils:getDistance(width,height)
        --     elseif allianceMergeStyle == 'top' then
        --         width = math.abs(fromLocation.x - toLocation.x)
        --         height = AllianceMapSize.height - toLocation.y + fromLocation.y
        --         return DataUtils:getDistance(width,height)
        --     elseif allianceMergeStyle == 'bottom' then
        --         width = math.abs(fromLocation.x - toLocation.x)
        --         height = AllianceMapSize.height - fromLocation.y + toLocation.y
        --         return DataUtils:getDistance(width,height)
        --     else
        --         return 0
        --     end
        -- end
end
--[[
    -->
    math.ceil(DataUtils:getPlayerSoldiersMarchTime(...) * (1 - DataUtils:getPlayerMarchTimeBuffEffectValue()))
    ---> 行军的真实时间
]]--
--获取攻击行军总时间
function DataUtils:getPlayerSoldiersMarchTime(soldiers,fromAllianceDoc, fromLocation, toAllianceDoc, toLocation)
    local distance = DataUtils:getAllianceLocationDistance(fromAllianceDoc, fromLocation, toAllianceDoc, toLocation)
    local baseSpeed,totalSpeed,totalCitizen = 2000,0,0
    for __,soldier_info in ipairs(soldiers) do
        totalCitizen = totalCitizen + soldier_info.soldier_citizen
        totalSpeed = totalSpeed + baseSpeed / soldier_info.soldier_march * soldier_info.soldier_citizen
    end
    return totalCitizen == 0 and 0 or math.ceil(totalSpeed / totalCitizen * distance)
end

function DataUtils:getPlayerMarchTimeBuffEffectValue()
    local effect = 0
    if UtilsForItem:IsItemEventActive(User, "marchSpeedBonus") then
        effect = effect + UtilsForItem:GetItemBuff("marchSpeedBonus")
    end
    -- vip buffer
    effect = effect + UtilsForVip:GetVipBuffByName(User, "marchSpeedAdd")
    -- 联盟行军buff
    effect = effect + buff[self:getMapRoundByMapIndex(Alliance_Manager:GetMyAlliance().mapIndex)].marchSpeedAddPercent / 100
    return effect
end
--获取攻击行军的buff时间
function DataUtils:getPlayerMarchTimeBuffTime(fullTime)
    local buff_value = DataUtils:getPlayerMarchTimeBuffEffectValue()
    if buff_value > 0 then
        return DataUtils:getBuffEfffectTime(fullTime,buff_value)
    else
        return 0
    end
end
--获得龙的行军时间（突袭）不加入任何buffer
function DataUtils:getPlayerDragonMarchTime(fromAllianceDoc, fromLocation, toAllianceDoc, toLocation)
    local distance = DataUtils:getAllianceLocationDistance(fromAllianceDoc, fromLocation, toAllianceDoc, toLocation)
    local baseSpeed = 2000
    local marchSpeed = PlayerInitData.intInit.dragonMarchSpeed.value
    local time = math.ceil(baseSpeed / marchSpeed * distance)
    return time
end
--获取科技升级的buff时间
local config_academy = GameDatas.BuildingFunction.academy
function DataUtils:getTechnilogyUpgradeBuffTime(time)
    local academy = City:GetFirstBuildingByType("academy")
    local level = academy:GetLevel()
    local config = config_academy[level]
    local efficiency = config and config.efficiency or 0
    if efficiency > 0 then
        return DataUtils:getBuffEfffectTime(time,efficiency)
    else
        return 0
    end
end
--获取兵种招募的buff时间
local config_BuildingFunction = GameDatas.BuildingFunction
local soldier_type_map_building = {
    infantry = "trainingGround",
    cavalry = "stable",
    archer = "hunterHall",
    siege = "workshop"
}
function DataUtils:getSoldierRecruitBuffTime(soldier_type,time)
    local building_type = soldier_type_map_building[soldier_type]
    if time and building_type then
        local build = City:GetFirstBuildingByType(building_type)
        if build and build:IsUnlocked() then
            local config = config_BuildingFunction[building_type][build:GetLevel()]
            local efficiency = config.efficiency
            return efficiency > 0 and self:getBuffEfffectTime(time, efficiency) or 0
        end
    end
    return 0
end
function DataUtils:getBuffEfffectTime(time,decreasePercent)
    return time - math.floor(time / (1 + decreasePercent))
end
-- 各种升级事件免费加速门坎 单位：秒
function DataUtils:getFreeSpeedUpLimitTime()
    return UtilsForVip:GetVipFreeSpeedUpTime(User) * 60
end

local config_online = GameDatas.Activities.online
function DataUtils:GetPlayerNextOnlineTimePoint()
    local on_line_time = self:getPlayerOnlineTimeMinutes()
    for __,v in pairs(config_online) do
        if v.onLineMinutes > on_line_time then
            return v.timePoint
        end
    end
end

function DataUtils:getPlayerOnlineTimeSecondes()
    local countInfo = User.countInfo
    local onlineTime = countInfo.todayOnLineTime + (NetManager:getServerTime() - countInfo.lastLoginTime)
    return math.floor(onlineTime / 1000)
end

function DataUtils:getPlayerOnlineTimeMinutes()
    return math.floor(self:getPlayerOnlineTimeSecondes() / 60)
end
-- 根据vip exp获得vip等级,当前等级已升经验百分比
function DataUtils:getPlayerVIPLevel(exp)
    for i=#VipLevel,0,-1 do
        local config = VipLevel[i]
        if exp >= config.expFrom then
            local percent = math.floor((exp - config.expFrom)/(config.expTo-config.expFrom)*100)
            return config.level,percent,exp
        end
    end
end
--龙的生命值恢复buff
function DataUtils:GetDragonHpBuffTotal()
    local effect = 0
    if UtilsForItem:IsItemEventActive(User, "dragonHpBonus") then
        effect = effect + UtilsForItem:GetItemBuff("dragonHpBonus")
    end
    effect = effect + UtilsForVip:GetVipBuffByName(User, "dragonHpRecoveryAdd")
    return effect
end
--龙的生命值恢复buff
function DataUtils:GetItemPriceByItemName(itemName)
    for _,item_category in pairs(items) do
        for k,v in pairs(item_category) do
            if k==itemName then
                return v.price
            end
        end
    end
end
-- 计算道具组价格
local Items = GameDatas.Items
function DataUtils:getItemsPrice( items )
    local total_price = 0
    for k,v in pairs(items) do
        local tag_item = Items.buff[k] or Items.resource[k] or Items.special[k] or Items.speedup[k]
        total_price = total_price + tag_item.price * v
    end
    return total_price
end
local config_store = GameDatas.StoreItems.items
function DataUtils:getIapInfo(productId)
    for __,v in ipairs(config_store) do
        if productId == v.productId then
            return v
        end
    end
end
--联盟名称随机
local config_clientinitgame = GameDatas.ClientInitGame
function DataUtils:__getRandomAllianceNameAndTag()
    local __categore = math.random(1,5)
    local name = ""
    local tag = ""
    if __categore == 1 then
        name = config_clientinitgame.alliance_name_single_name[math.random(1,#config_clientinitgame.alliance_name_single_name)].value
        tag  = string.sub(name,1,3)
    elseif __categore == 2 then
        local config = config_clientinitgame.alliance_name_single_name
        local count = #config
        local fist_index = math.random(1,count)
        local second_index
        repeat
            second_index = math.random(1,count)
        until second_index ~= fist_index
        name = string.format("%s and %s",config[fist_index].value,config[second_index].value)
        tag  = string.format("%sn%s",string.sub(config[fist_index].value,1,1),string.sub(config[second_index].value,1,1))
    elseif __categore == 3 then
        local config_1 = config_clientinitgame.alliance_name_adj
        local config_2 = config_clientinitgame.alliance_name_single_name
        local fist_index,second_index = math.random(1,#config_1),math.random(1,#config_2)

        name = string.format("The %s %s",config_1[fist_index].value,config_2[second_index].value)
        tag  = string.format("T%s%s",string.sub(config_1[fist_index].value,1,1),string.sub(config_2[second_index].value,1,1))
    elseif __categore == 4 then
        local config_1 = config_clientinitgame.alliance_name_noun
        local config_2 = config_clientinitgame.alliance_name_single_name
        local fist_index,second_index = math.random(1,#config_1),math.random(1,#config_2)
        name = string.format("%s of %s",config_1[fist_index].value,config_2[second_index].value)
        tag  = string.format("%so%s",string.sub(config_1[fist_index].value,1,1),string.sub(config_2[second_index].value,1,1))
    elseif __categore == 5 then
        local config_1 = config_clientinitgame.alliance_name_fixed
        local index = math.random(1,#config_1)
        name = config_1[index].value
        local tags = string.split(name," ")
        local count = #tags
        if count == 2 then
            tag = string.format("%s%s",string.sub(tags[1],1,1),string.sub(tags[2],1,1))
        elseif count == 3 then
            if tags[2] == 'and' then
                tag = string.format("%sn%s",string.sub(tags[1],1,1),string.sub(tags[3],1,1))
            else
                tag = string.format("%s%s%s",string.sub(tags[1],1,1),string.sub(tags[2],1,1),string.sub(tags[3],1,1))
            end
        end
    end
    return name,tag
end
local randomed_alliance_name = {}
function DataUtils:randomAllianceNameTag()
    local name,tag
    repeat
        name,tag = self:__getRandomAllianceNameAndTag()
    until not randomed_alliance_name[name]
    randomed_alliance_name[name] = true
    return name,tag
end
-- 获取特殊兵种招募状态，返回true 招募进行中；返回时间，下次招募开始时间
function DataUtils:GetNextRecruitTime()
    -- local can_re_time = PlayerInitData.intInit.specialSoldierRecruitAbleDays.value..""
    -- local days = {}
    -- for i=1,string.len(can_re_time) do
    --     table.insert(days, tonumber(string.sub(can_re_time,i,i)))
    -- end
    -- -- local current_day = 3
    -- local current_day = tonumber(os.date("!%w", app.timer:GetServerTime()))
    -- local next_day = 7
    -- for i,v in ipairs(days) do
    --     v = v == 7 and 0 or v
    --     if v==current_day then
    --         return true
    --     else
    --         if current_day<v then
    --             next_day = math.min(next_day,v)
    --         end
    --     end
    -- end

    -- local year = os.date('!%Y', app.timer:GetServerTime())
    -- local month = os.date('!%m', app.timer:GetServerTime())
    -- local day = os.date('!%d', app.timer:GetServerTime())
    -- local hour = os.date('!%H', app.timer:GetServerTime())
    -- local min = os.date('!%M', app.timer:GetServerTime())
    -- local sec = os.date('!%S', app.timer:GetServerTime())

    -- local next_time = (next_day-current_day) * 24 * 60 * 60 - hour * 60 * 60 - min * 60 - sec
    -- return next_time
    return true
end
function DataUtils:GetDragonSkillUnLockStar(skillName)
    for __,v in ipairs(config_dragonStar) do
        local unlockSkills = string.split(v.skillsUnlocked,',')
        for __,skill_name in ipairs(unlockSkills) do
            if skill_name == skillName then
                return v.star
            end
        end
    end
end



----
function DataUtils:GetVSFromSoldierName(name1, name2)
    return soldier_vs[self:GetSoldierTypeByName(name1)][self:GetSoldierTypeByName(name2)]
end
function DataUtils:GetSoldierTypeByName(name)
    for k, v in pairs(normal_soldier) do
        if string.find(v.name,name) then
            return v.type
        end
    end
    for k, v in pairs(special_soldier) do
        if v.name == name then
            return v.type
        end
    end
    return name
end


local DragonFightBuffTerrain = {
    redDragon = "grassLand",
    blueDragon = "desert",
    greenDragon = "iceField"
}
local function getSoldiersConfig(soldier_name, soldier_star)
    local soldier_config = special_soldier[soldier_name]
    if not soldier_config then
        soldier_config = normal_soldier[string.format("%s_%d", soldier_name, soldier_star)]
    end
    assert(soldier_config)
    return soldier_config
end
-- 如果是pve得话就没有龙
local function getPlayerSoldierAtkBuff(soldierName, soldierStar, dragon, terrain, is_dragon_win)
    if not dragon then
        return 0
    end
    local itemBuff = 0
    local skillBuff = 0
    local equipmentBuff = 0
    local soldierType = getSoldiersConfig(soldierName, soldierStar).type

    local eventType = soldierType.."AtkBonus"
    if UtilsForItem:IsItemEventActive(User, eventType) then
        local effect1 = UtilsForItem:GetItemBuff(eventType)
        itemBuff = effect1
    end

    if DragonFightBuffTerrain[dragon:Type()] == terrain then
        local skill = dragon:GetSkillByName(soldierType.."Enhance")
        if skill then
            skillBuff = skill:GetEffect()
        end
    end

    local equipmentBuff_key = soldierType.."AtkAdd"
    for _,v in ipairs(dragon:GetAllEquipmentBuffEffect()) do
        local k,buff = unpack(v)
        if k == equipmentBuff_key then
            equipmentBuff = buff
            break
        end
    end

    return itemBuff + ((skillBuff + equipmentBuff) * (is_dragon_win and 1 or 0.5))
end
-- 如果是pve得话就没有龙
local function getPlayerSoldierHpBuff(soldierName, soldierStar, dragon, terrain, is_dragon_win)
    if not dragon then
        return 0
    end
    local itemBuff = 0
    local skillBuff = 0
    local equipmentBuff = 0

    if UtilsForItem:IsItemEventActive(User, "unitHpBonus") then
        local effect1 = UtilsForItem:GetItemBuff("unitHpBonus")
        itemBuff = effect1
    end

    local soldierType = getSoldiersConfig(soldierName, soldierStar).type

    if DragonFightBuffTerrain[dragon:Type()] == terrain then
        local skill = dragon:GetSkillByName(soldierType.."Enhance")
        if skill then
            skillBuff = skill:GetEffect()
        end
    end

    local equipmentBuff_key = soldierType.."HpAdd"
    for _,v in ipairs(dragon:GetAllEquipmentBuffEffect()) do
        local k,buff = unpack(v)
        if k == equipmentBuff_key then
            equipmentBuff = buff
            break
        end
    end
    return itemBuff + ((skillBuff + equipmentBuff) * (is_dragon_win and 1 or 0.5))
end
local function createPlayerSoldiersForFight(soldiers, dragon, terrain, is_dragon_win)
    return LuaUtils:table_map(soldiers, function(k, soldier)
        return k, {
            name = soldier.name,
            star = soldier.star,
            type = config.type,
            currentCount = soldier.count,
            totalCount = soldier.count,
            woundedCount = 0,
            power = config.power,
            hp = math.floor(config.hp * (1 + hpBuff + techBuffHpAdd + vipHpBuff)),
            morale = 100,
            round = 1,
            attackPower = {
                infantry = math.floor(config.infantry * (1 + atkBuff + techBuffToInfantry + vipAttackBuff)),
                archer = math.floor(config.archer * (1 + atkBuff + techBuffToArcher + vipAttackBuff)),
                cavalry = math.floor(config.cavalry * (1 + atkBuff + techBuffToCavalry + vipAttackBuff)),
                siege = math.floor(config.siege * (1 + atkBuff + techBuffToSiege + vipAttackBuff)),
            }
        }
    end)
end
local function getPlayerDragonExpAdd(dragon)
    local itemBuff = 0
    local vipBuff = UtilsForVip:GetVipBuffByName(User, "dragonExpAdd")
    if UtilsForItem:IsItemEventActive(User, "dragonExpBonus") then
        local effect1 = UtilsForItem:GetItemBuff("dragonExpBonus")
        itemBuff = effect1
    end
    return itemBuff + vipBuff
end
local function createDragonForFight(dragon, terrain)
    return {
        level = dragon:Level(),
        dragonType = dragon:Type(),
        currentHp = dragon:Hp(),
        totalHp = dragon:Hp(),
        hpMax = dragon:GetMaxHP(),
        strength = dragon:TotalStrength(terrain),
        vitality = dragon:TotalVitality(),
    }
end
local DAMAGE_FACTOR = 0.3
function DataUtils:SoldierSoldierBattle(attackSoldiers, attackWoundedSoldierPercent, attackSoldierMoraleDecreasedPercent, defenceSoldiers, defenceWoundedSoldierPercent, defenceSoldierMoraleDecreasedPercent)
    local attackResults = {}
    local defenceResults = {}
    while #attackSoldiers > 0 and #defenceSoldiers > 0 do
        local attackSoldier = attackSoldiers[1]
        local defenceSoldier = defenceSoldiers[1]
        local attackSoldierType = attackSoldier.type
        local defenceSoldierType = defenceSoldier.type
        local attackTotalPower = attackSoldier.attackPower[defenceSoldierType] * attackSoldier.currentCount
        local defenceTotalPower = defenceSoldier.attackPower[attackSoldierType] * defenceSoldier.currentCount
        local attackDamagedSoldierCount = nil
        local defenceDamagedSoldierCount = nil
        if attackTotalPower >= defenceTotalPower then
            attackDamagedSoldierCount = ceil(defenceTotalPower * DAMAGE_FACTOR / attackSoldier.hp)
            defenceDamagedSoldierCount = ceil(sqrt(attackTotalPower * defenceTotalPower) * 0.5 / defenceSoldier.hp)
        else
            attackDamagedSoldierCount = ceil(sqrt(attackTotalPower * defenceTotalPower) * DAMAGE_FACTOR / attackSoldier.hp)
            defenceDamagedSoldierCount = ceil(attackTotalPower * 0.5 / defenceSoldier.hp)
        end
        if (attackDamagedSoldierCount > attackSoldier.currentCount) then attackDamagedSoldierCount = attackSoldier.currentCount end
        if (defenceDamagedSoldierCount > defenceSoldier.currentCount) then defenceDamagedSoldierCount = defenceSoldier.currentCount end

        -- if (attackSoldier.currentCount >= 50 and attackDamagedSoldierCount > attackSoldier.currentCount * 0.7) then
        --     attackDamagedSoldierCount = ceil(attackSoldier.currentCount * 0.7)
        -- end
        -- if (defenceSoldier.currentCount >= 50 and defenceDamagedSoldierCount > defenceSoldier.currentCount * 0.7) then
        --     defenceDamagedSoldierCount = ceil(defenceSoldier.currentCount * 0.7)
        -- end
        --
        local attackWoundedSoldierCount = ceil(attackDamagedSoldierCount * attackWoundedSoldierPercent)
        local defenceWoundedSoldierCount = ceil(defenceDamagedSoldierCount * defenceWoundedSoldierPercent)
        local attackMoraleDecreased = ceil(attackDamagedSoldierCount * pow(2, attackSoldier.round - 1) / attackSoldier.totalCount * 100 * attackSoldierMoraleDecreasedPercent)
        local defenceMoraleDecreased = ceil(defenceDamagedSoldierCount * pow(2, defenceSoldier.round - 1) / defenceSoldier.totalCount * 100 * defenceSoldierMoraleDecreasedPercent)

        if attackMoraleDecreased > attackSoldier.morale then
            attackMoraleDecreased = attackSoldier.morale
        end
        if defenceMoraleDecreased > defenceSoldier.morale then
            defenceMoraleDecreased = defenceSoldier.morale
        end

        table.insert(attackResults, {
            soldierName = attackSoldier.name,
            soldierStar = attackSoldier.star,
            soldierCount = attackSoldier.currentCount,
            soldierDamagedCount = attackDamagedSoldierCount,
            soldierWoundedCount = attackWoundedSoldierCount,
            morale = attackSoldier.morale,
            moraleDecreased = attackMoraleDecreased > attackSoldier.morale and attackSoldier.morale or attackMoraleDecreased,
            isWin = attackTotalPower >= defenceTotalPower
        })
        table.insert(defenceResults, {
            soldierName = defenceSoldier.name,
            soldierStar = defenceSoldier.star,
            soldierCount = defenceSoldier.currentCount,
            soldierDamagedCount = defenceDamagedSoldierCount,
            soldierWoundedCount = defenceWoundedSoldierCount,
            morale = defenceSoldier.morale,
            moraleDecreased = defenceMoraleDecreased > defenceSoldier.morale and defenceSoldier.morale or defenceMoraleDecreased,
            isWin = attackTotalPower < defenceTotalPower
        })
        attackSoldier.round = attackSoldier.round + 1
        attackSoldier.currentCount = attackSoldier.currentCount - attackDamagedSoldierCount
        attackSoldier.woundedCount = attackSoldier.woundedCount + attackWoundedSoldierCount
        attackSoldier.morale = attackSoldier.morale - attackMoraleDecreased

        defenceSoldier.round = defenceSoldier.round + 1
        defenceSoldier.currentCount = defenceSoldier.currentCount - defenceDamagedSoldierCount
        defenceSoldier.woundedCount = defenceSoldier.woundedCount + defenceWoundedSoldierCount
        defenceSoldier.morale = defenceSoldier.morale - defenceMoraleDecreased


        if attackTotalPower < defenceTotalPower or attackSoldier.morale <= 20 or attackSoldier.currentCount == 0 then
            table.remove(attackSoldiers, 1)
        end
        if attackTotalPower >= defenceTotalPower or defenceSoldier.morale <= 20 or defenceSoldier.currentCount == 0 then
            table.remove(defenceSoldiers, 1)
        end
    end

    local fightResult = true
    if(#attackSoldiers > 0 or (#attackSoldiers == 0 and #defenceSoldiers== 0)) then
        fightResult = true
    else
        fightResult = false
    end

    return attackResults, defenceResults, fightResult
end

function DataUtils:DragonDragonBattle(attackDragon, defenceDragon, effect)
    assert(attackDragon.hpMax)
    assert(attackDragon.strength)
    assert(attackDragon.vitality)
    assert(attackDragon.totalHp)
    assert(attackDragon.currentHp)
    assert(defenceDragon.hpMax)
    assert(defenceDragon.strength)
    assert(defenceDragon.vitality)
    assert(defenceDragon.totalHp)
    assert(defenceDragon.currentHp)

    local attackDragonStrength = attackDragon.strength
    local attackDragonStrengthFixed = nil
    local defenceDragonStrength = defenceDragon.strength
    local defenceDragonStrengthFixed = nil
    if effect >= 0 then
        defenceDragonStrengthFixed = defenceDragonStrength * ( 1 - effect )
        attackDragonStrengthFixed = attackDragonStrength
    else
        attackDragonStrengthFixed = attackDragonStrength * ( 1 - (-effect) )
        defenceDragonStrengthFixed = defenceDragonStrength
    end
    local attackDragonHpDecreased
    local defenceDragonHpDecreased
    if attackDragonStrength >= defenceDragonStrength then
        attackDragonHpDecreased = floor(defenceDragonStrengthFixed * 0.5)
        defenceDragonHpDecreased = floor(sqrt(attackDragonStrengthFixed * defenceDragonStrengthFixed) * 0.5)
    else
        attackDragonHpDecreased = floor(sqrt(attackDragonStrengthFixed * defenceDragonStrengthFixed) * 0.5)
        defenceDragonHpDecreased = floor(attackDragonStrengthFixed * 0.5)
    end

    attackDragon.currentHp = attackDragonHpDecreased > attackDragon.currentHp and 0 or attackDragon.currentHp - attackDragonHpDecreased
    defenceDragon.currentHp = defenceDragonHpDecreased > defenceDragon.currentHp and 0 or defenceDragon.currentHp - defenceDragonHpDecreased
    attackDragon.isWin = attackDragonStrength >= defenceDragonStrength
    defenceDragon.isWin = attackDragonStrength < defenceDragonStrength

    return {
        type = attackDragon.dragonType,
        hp = attackDragon.totalHp,
        hpDecreased = attackDragon.totalHp - attackDragon.currentHp,
        hpMax = attackDragon.hpMax,
        isWin = attackDragonStrength >= defenceDragonStrength
    }, {
        type = defenceDragon.dragonType,
        hp = defenceDragon.totalHp,
        hpDecreased = defenceDragon.totalHp - defenceDragon.currentHp,
        hpMax = defenceDragon.hpMax,
        isWin = attackDragonStrength < defenceDragonStrength
    }
end

local function getSumPower(soldiersForFight)
    local power = 0
    for i,soldierForFight in ipairs(soldiersForFight) do
        power = power + soldierForFight.power * soldierForFight.totalCount
    end
    return power
end
local fightFix = GameDatas.Dragons.fightFix
local function getEffectPercent(multiple)
    local configs = fightFix
    for _,config in ipairs(configs) do
        if config.multipleMax > multiple then
            return config.effect
        end
    end
    return configs[#configs].effect
end
local function getDragonFightFixedEffect(attackSoldiersForFight, defenceSoldiersForFight)
    local attackSumPower = getSumPower(attackSoldiersForFight)
    local defenceSumPower = getSumPower(defenceSoldiersForFight)
    local effect = attackSumPower >= defenceSumPower and getEffectPercent(attackSumPower / defenceSumPower) or -getEffectPercent(defenceSumPower / attackSumPower)
    return effect
end
local function getPlayerTreatSoldierPercent(dragon)
    if true then return 1.0 end
    local basePercent = 0.3
    local skillBuff = 0
    local equipmentBuff = 0

    local skill = dragon:GetSkillByName("recover")
    if skill then
        skillBuff = skill:GetEffect()
    end

    for _,v in ipairs(dragon:GetAllEquipmentBuffEffect()) do
        local k,buff = unpack(v)
        if k == "recoverAdd" then
            equipmentBuff = buff
            break
        end
    end
    return basePercent + skillBuff + equipmentBuff
end
local function getPlayerSoldierMoraleDecreasedPercent(dragon)
    local basePercent = 1
    local skillBuff = 0

    local skill = dragon:GetSkillByName("insensitive")
    if skill then
        skillBuff = skill:GetEffect()
    end

    return basePercent - skillBuff
end

local function getEnemySoldierMoraleAddedPercent(dragon)
    local dragonSkillName = "frenzied"
    local skill = dragon:GetSkillByName(dragonSkillName)
    if skill then
        return skill:GetEffect()
    end
    return 0
end
function DataUtils:DoBattle(attacker, defencer, terrain, enemy_name)
    assert(terrain)
    assert(enemy_name)
    local clone_attacker_soldiers = clone(attacker.soldiers)
    local clone_defencer_soldiers = clone(defencer.soldiers)

    local attacker_dragon = createDragonForFight(attacker.dragon, terrain)
    local defencer_dragon = defencer.dragon

    local attacker_soldiers = createPlayerSoldiersForFight(attacker.soldiers, attacker.dragon, terrain, attacker_dragon.strength > defencer_dragon.strength)
    local defencer_soldiers = createPlayerSoldiersForFight(defencer.soldiers)

    local dragonFightFixedEffect = getDragonFightFixedEffect(attacker_soldiers, defencer_soldiers)
    local attack_dragon, defence_dragon = self:DragonDragonBattle(attacker_dragon, defencer_dragon, dragonFightFixedEffect)

    local attackWoundedSoldierPercent = getPlayerTreatSoldierPercent(attacker.dragon)
    local attackSoldierMoraleDecreasedPercent = getPlayerSoldierMoraleDecreasedPercent(attacker.dragon)
    local attackToEnemySoldierMoralDecreasedAddPercent = getEnemySoldierMoraleAddedPercent(attacker.dragon)
    local attack_soldier, defence_soldier, is_attack_win =
        self:SoldierSoldierBattle(
            attacker_soldiers, attackWoundedSoldierPercent, attackSoldierMoraleDecreasedPercent,
            defencer_soldiers, 0.4, 1 + attackToEnemySoldierMoralDecreasedAddPercent
        )
    local report = {}
    function report:GetAttackKDA()
        -- 龙战损
        local r = {}
        for _, v in ipairs(defence_soldier) do
            local key = v.soldierStar and string.format("%s_%d", v.soldierName, v.soldierStar) or v.soldierName
            r[key] = 0
        end
        for _, v in ipairs(defence_soldier) do
            local key = v.soldierStar and string.format("%s_%d", v.soldierName, v.soldierStar) or v.soldierName
            r[key] = r[key] + v.soldierDamagedCount
        end
        local killScore = 0
        for k, v in pairs(r) do
            local config = normal_soldier[k] or special_soldier[k]
            assert(config, "查无此类兵种。")
            killScore = killScore + v * config.killScore
        end
        assert(attacker.dragon:Type())
        local buff = getPlayerDragonExpAdd(attacker.dragon)
        local dragon = {
            type = attacker.dragon:Type(),
            hpDecreased = attack_dragon.hpDecreased,
            expAdd = floor(killScore / AllianceInitData.intInit.KilledCitizenPerDragonExp.value * ( 1 + buff ) )
        }
        -- 兵种战损
        local r = {}
        for _, v in ipairs(attack_soldier) do
            r[v.soldierName] = {damagedCount = 0, woundedCount = 0}
        end
        for _, v in ipairs(attack_soldier) do
            local soldier = r[v.soldierName]
            soldier.damagedCount = soldier.damagedCount + v.soldierDamagedCount
            soldier.woundedCount = soldier.woundedCount + v.soldierWoundedCount
        end
        local soldiers = {}
        for k, v in pairs(r) do
            if v.damagedCount > 0 then
                table.insert(soldiers, {name = k, damagedCount = v.damagedCount, woundedCount = v.woundedCount})
            end
        end
        return {dragon = dragon, soldiers = soldiers}
    end
    function report:GetDefenceKDA()
        -- 兵种战损
        local r = {}
        for _,v in ipairs(defence_soldier) do
            r[v.soldierName] = {damagedCount = 0, woundedCount = 0}
        end
        for _,v in ipairs(defence_soldier) do
            local soldier = r[v.soldierName]
            soldier.damagedCount = soldier.damagedCount + v.soldierDamagedCount
            soldier.woundedCount = soldier.woundedCount + v.soldierWoundedCount
        end
        local soldiers = {}
        for k,v in pairs(r) do
            if v.damagedCount > 0 then
                table.insert(soldiers, {name = k, damagedCount = v.damagedCount, woundedCount = v.woundedCount})
            end
        end
        return {soldiers = soldiers}
    end
    function report:IsPveBattle()
    end
    function report:GetFightAttackName()
        return User.basicInfo.name
    end
    function report:GetFightDefenceName()
        return enemy_name
    end
    function report:IsDragonFight()
        return true
    end
    function report:GetFightAttackDragonRoundData()
        return attack_dragon
    end
    function report:GetFightDefenceDragonRoundData()
        return defence_dragon
    end
    function report:GetFightAttackSoldierRoundData()
        return attack_soldier
    end
    function report:GetFightDefenceSoldierRoundData()
        return defence_soldier
    end
    function report:GetOrderedAttackSoldiers()
        return clone_attacker_soldiers
    end
    function report:GetOrderedDefenceSoldiers()
        return clone_defencer_soldiers
    end
    function report:IsFightWall()
        return false
    end
    function report:IsAttackWin()
        return is_attack_win
    end
    function report:IsAttackCamp()
        return true
    end
    function report:GetReportResult()
        return self:IsAttackWin()
    end
    function report:GetAttackDragonLevel()
        return attacker_dragon.level
    end
    function report:GetDefenceDragonLevel()
        return defencer_dragon.level
    end
    function report:GetAttackTargetTerrain()
        return terrain
    end
    return report
end
-- 获取资源保护百分比
local resourceBuildingMap = {
    wood = "lumbermill",
    stone = "stoneMason",
    iron = "foundry",
    food = "mill"
}
local function getBuildingBuffForResourceProtectPercent(resourceName)
    return UtilsForBuilding:GetBuildingProtection(User,
                resourceBuildingMap[resourceName]
            )
end
-- local function getPlayerItemBuffForResourceLootPercentSubtract()
--     local itemBuff = 0
--     if User:IsItemEventActive("masterOfDefender") then
--         itemBuff = items.buffTypes.masterOfDefender.effect2
--     end
--     return itemBuff
-- end
local function getPlayerVipForResourceLootPercentSubtract()
    local vipBuffAddPercent = 0
    if UtilsForVip:IsVipActived(User) then
        vipBuffAddPercent = VipLevel[User:GetVipLevel()].storageProtectAdd
    end
    return vipBuffAddPercent
end
function DataUtils:GetResourceProtectPercent( resource_name )
    local basePercent = PlayerInitData.intInit.playerResourceProtectPercent.value / 100
    local buildingBuffAddPercent = getBuildingBuffForResourceProtectPercent(resource_name)
    -- local itemBuffAddPercent = getPlayerItemBuffForResourceLootPercentSubtract(defencePlayerDoc)
    local vipBuffAddPercent = getPlayerVipForResourceLootPercentSubtract()
    local tech_effect = UtilsForTech:GetEffect("hideout", User.productionTechs["hideout"])
    local finalPercent = basePercent + buildingBuffAddPercent + vipBuffAddPercent + tech_effect
    finalPercent = finalPercent > 0.9 and 0.9 or finalPercent < basePercent/100 and basePercent/100 or finalPercent
    return finalPercent
end
--根据MapIndex获取MapRound
function DataUtils:getMapRoundByMapIndex( mapIndex )
    local bigMapLength = bigMapLength_value
    local roundMax = math.floor(bigMapLength / 2)
    local locationX = mapIndex % bigMapLength
    local locationY = math.floor(mapIndex / bigMapLength)
    local locations = {}
    for i=0,roundMax do
        local location = {}
        local width = bigMapLength - (i * 2);
        local height = bigMapLength - (i * 2);

        local x = i
        local y = i
        local from = {x = x, y =y}
        local to = {x = x + width - 1, y = y}
        table.insert(location, {from = from, to = to})

        x = i
        y = height - 1 + i
        if x ~= y then
            from = {x = x, y = y}
            to = {x = x + width - 1, y = y}
            table.insert(location, {from = from, to = to})
        end

        if i ~= roundMax then
            x = i
            y = i + 1
            from = {x = x, y = y}
            to = {x = x, y = y + height - 2 - 1}
            table.insert(location, {from = from, to = to})

            x = width - 1 + i
            y = i + 1
            if x ~= y then
                from = {x = x, y = y}
                to = {x = x, y = y + height - 2 - 1}
                table.insert(location, {from = from, to = to})
            end
        end
        table.insert(locations, location)
    end
    local theRound = nil
    for round,location in ipairs(locations) do
        for i,v in ipairs(location) do
            if v.from.x <= locationX and v.from.y <= locationY and v.to.x >= locationX and v.to.y >= locationY then
                theRound = round - 1
            end
        end
    end
    return theRound and (roundMax - theRound)
end
--根据MapIndex获取对应buff增益数量
function DataUtils:getMapBuffNumByMapIndex( mapIndex )
    local map_round = self:getMapRoundByMapIndex(mapIndex)
    local buff_1 = buff[map_round]
    local buff_num = 0
    for i,v in pairs(buff_1) do
        if i ~="monsterLevel" and i ~= "round" and v > 0 then
            buff_num = buff_num + 1
        end
    end
    return buff_num
end

function DataUtils:GetAllianceMapBuffByRound(round)
    local aliance_buff = buff[round]
    local buff_info = {}

    for i,v in ipairs({"monsterLevel","villageAddPercent","dragonExpAddPercent","bloodAddPercent","marchSpeedAddPercent","dragonStrengthAddPercent","loyaltyAddPercent","honourAddPercent"}) do
        if v =="monsterLevel" then
            local levels = string.split(aliance_buff[v],"_")
            table.insert(buff_info, {
                {Localize.alliance_buff[v],0x403c2f},
                {string.format("Lv%s~Lv%s",levels[1],levels[2]),0x288400}
            })
        else
            table.insert(buff_info, {
                {Localize.alliance_buff[v],0x403c2f},
                {(aliance_buff[v] > 0 and "+" or "")..aliance_buff[v].."%",aliance_buff[v] > 0 and 0x288400 or 0xe34724}
            })
        end
    end
    return buff_info
end

return DataUtils







