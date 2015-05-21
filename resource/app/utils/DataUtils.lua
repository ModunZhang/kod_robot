local BuildingLevelUp = GameDatas.BuildingLevelUp
local GemsPayment = GameDatas.GemsPayment
local HouseLevelUp = GameDatas.HouseLevelUp
local VipLevel = GameDatas.Vip.level
local items = GameDatas.Items
DataUtils = {}

--[[
  获取建筑升级时,需要的资源和道具
]]
function DataUtils:getBuildingUpgradeRequired(buildingType, buildingLevel)
    local temp = BuildingLevelUp[buildingType] or HouseLevelUp[buildingType]
    local config = temp[buildingLevel]
    local required = {
        resources={
            wood=config.wood,
            stone=config.stone,
            iron=config.iron,
            citizen=config.citizen
        },
        materials={
            blueprints=config.blueprints,
            tools=config.tools,
            tiles=config.tiles,
            pulley=config.pulley
        },
        buildTime=config.buildTime
    }
    return required
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
                local freeCitizenLimit = City:GetResourceManager():GetPopulationResource():GetValueLimit()
                while required > 0 do
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
            local attribute = self:getDragonEquipmentAttribute(body,config.maxStar,equipemt.star)
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
            local attribute = self:getDragonEquipmentAttribute(body,config.maxStar,equipemt.star)
            vitality = attribute and (vitality + attribute.vitality) or vitality
        end
    end
    return vitality
end

function DataUtils:getDragonSkillEffect(skillName,level)
    level = checkint(level)
    if config_dragonSkill[skillName] then
        return level * config_dragonSkill[skillName].effectPerLevel
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
            return self:getDragonSkillEffect(v.name,v.level)
        end
    end
    return 0
end

function DataUtils:__getDragonVitalityBuff(skills)
    for __,v in pairs(skills) do
        if v.name == 'dragonBlood' then
            return self:getDragonSkillEffect(v.name,v.level)
        end
    end
    return 0
end
--如果有道具加龙属性 这里就还未完成
function DataUtils:getDragonMaxHp(star,level,skills,equipments)
    local vitality = self:getTotalVitalityFromJson(star,level,skills,equipments)
    return vitality * 2
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
    local item_buff = ItemManager:GetAllSoldierBuffData()
    local military_technology_buff = City:GetSoldierManager():GetAllMilitaryBuffData()
    table.insertto(item_buff,military_technology_buff)
    local vip_buff = self:getAllSoldierVipBuffValue()
    table.insertto(item_buff,vip_buff)
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
    local attck_buff = User:GetVIPSoldierAttackPowerAdd()
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
    local defence_buff = User:GetVIPSoldierHpAdd()
    if defence_buff > 0 then
        table.insert(buff_table,{"*","hp",defence_buff})
    end
    --维护费用
    local consumeFood_buff = User:GetVIPSoldierConsumeSub()
    if consumeFood_buff > 0 then
        table.insert(buff_table,{"*","consumeFoodPerHour",consumeFood_buff})
    end
    --行军速度
    local march_buff = User:GetVIPMarchSpeedAdd()
    if march_buff > 0 then
        table.insert(buff_table,{"*","march",march_buff})
    end
    return buff_table
end

--获取建筑时间的buff
--buildingTime:升级或建造原来的时间
function DataUtils:getBuildingBuff(buildingTime)
    local tech = City:FindTechByName('crane')
    if tech and tech:Level() > 0 then
        return DataUtils:getBuffEfffectTime(buildingTime, tech:GetBuffEffectVal())
    else
        return 0
    end
end

local config_intInit = GameDatas.AllianceInitData.intInit
local AllianceMapSize = {
    width = config_intInit.allianceRegionMapWidth.value,
    height= config_intInit.allianceRegionMapHeight.value
}
local PlayerInitData = GameDatas.PlayerInitData
function DataUtils:getDistance(width,height)
    return math.ceil(math.sqrt(math.pow(width, 2) + math.pow(height, 2)))
end

function DataUtils:getAllianceLocationDistance(fromAllianceDoc, fromLocation, toAllianceDoc, toLocation)
    local width,height = 0,0
    if fromAllianceDoc == toAllianceDoc then
        width = math.abs(fromLocation.x - toLocation.x)
        height =  math.abs(fromLocation.y - toLocation.y)
        return DataUtils:getDistance(width,height)
    end
    if fromAllianceDoc:GetAllianceFight()['attackAllianceId'] == fromAllianceDoc:Id() then
        local allianceMergeStyle = fromAllianceDoc:GetAllianceFight()['mergeStyle']
        if allianceMergeStyle == 'left' then
            width = AllianceMapSize.width - fromLocation.x + toLocation.x
            height= math.abs(fromLocation.y - toLocation.y)
            return DataUtils:getDistance(width,height)
        elseif allianceMergeStyle == 'right' then
            width = AllianceMapSize.width - toLocation.x + fromLocation.x
            height= math.abs(fromLocation.y - toLocation.y)
            return DataUtils:getDistance(width,height)
        elseif allianceMergeStyle == 'top' then
            width = math.abs(fromLocation.x - toLocation.x)
            height= AllianceMapSize.height - fromLocation.y + toLocation.y
            return DataUtils:getDistance(width,height)
        elseif allianceMergeStyle == 'bottom' then
            width = math.abs(fromLocation.x - toLocation.x)
            height= AllianceMapSize.height - toLocation.y + fromLocation.y
            return DataUtils:getDistance(width,height)
        else
            return 0
        end
    else
        local allianceMergeStyle = fromAllianceDoc:GetAllianceFight()['mergeStyle']
        if allianceMergeStyle == 'left' then
            width = AllianceMapSize.width - toLocation.x + fromLocation.x
            height = math.abs(fromLocation.y - toLocation.y)
            return DataUtils:getDistance(width,height)
        elseif allianceMergeStyle == 'right' then
            width = AllianceMapSize.width - fromLocation.x + toLocation.x
            height = math.abs(fromLocation.y - toLocation.y)
            return DataUtils:getDistance(width,height)
        elseif allianceMergeStyle == 'top' then
            width = math.abs(fromLocation.x - toLocation.x)
            height = AllianceMapSize.height - toLocation.y + fromLocation.y
            return DataUtils:getDistance(width,height)
        elseif allianceMergeStyle == 'bottom' then
            width = math.abs(fromLocation.x - toLocation.x)
            height = AllianceMapSize.height - fromLocation.y + toLocation.y
            return DataUtils:getDistance(width,height)
        else
            return 0
        end
    end
end
--[[
    -->
    math.ceil(DataUtils:getPlayerSoldiersMarchTime(...) * (1 - DataUtils:getPlayerMarchTimeBuffEffectValue()))
    ---> 行军的真实时间
]]--
--获取攻击行军总时间
function DataUtils:getPlayerSoldiersMarchTime(soldiers,fromAllianceDoc, fromLocation, toAllianceDoc, toLocation)
    local distance = DataUtils:getAllianceLocationDistance(fromAllianceDoc, fromLocation, toAllianceDoc, toLocation)
    local baseSpeed,totalSpeed,totalCitizen = 1200,0,0
    for __,soldier_info in ipairs(soldiers) do
        totalCitizen = totalCitizen + soldier_info.soldier_citizen
        totalSpeed = totalSpeed + baseSpeed / soldier_info.soldier_march * soldier_info.soldier_citizen
    end
    return totalCitizen == 0 and 0 or math.ceil(totalSpeed / totalCitizen * distance)
end

function DataUtils:getPlayerMarchTimeBuffEffectValue()
    local effect = 0
    if ItemManager:IsBuffActived("marchSpeedBonus") then
        effect = effect + ItemManager:GetBuffEffect("marchSpeedBonus")
    end
    --vip buffer
    effect = effect + User:GetVIPMarchSpeedAdd()
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
    local baseSpeed = 1200
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
    return User:GetVIPFreeSpeedUpTime() * 60
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
    local countInfo = User:GetCountInfo()
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
    if ItemManager:IsBuffActived("dragonHpBonus") then
        effect = effect + ItemManager:GetBuffEffect("dragonHpBonus")
    end
    effect = effect + User:GetVIPDragonHpRecoveryAdd()
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
        total_price = total_price + tag_item.price
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
    local can_re_time = PlayerInitData.intInit.specialSoldierRecruitAbleDays.value..""
    local days = {}
    for i=1,string.len(can_re_time) do
        table.insert(days, tonumber(string.sub(can_re_time,i,i)))
    end

    -- local current_day = 3
    local current_day = tonumber(os.date("%w", os.time()))
    local next_day = 7
    for i,v in ipairs(days) do
        v = v == 7 and 0 or v
        if v==current_day then
            return true
        else
            if current_day<v then
                next_day = math.min(next_day,v)
            end
        end
    end

    local dt1 = os.time{year=os.date("%Y", os.time()), month=os.date("%m", os.time()), day=os.date("%d", os.time())+next_day-current_day, hour=0,min=0,sec=0}

    return dt1
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

return DataUtils


