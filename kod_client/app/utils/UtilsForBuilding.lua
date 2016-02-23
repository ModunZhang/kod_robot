UtilsForBuilding = {}

function UtilsForBuilding:GetHousesBy(userData, name, level)
    level = level or 0
    local t = {}
    for _,building in pairs(userData.buildings) do
        for _,house in pairs(building.houses) do
            if house.level >= level and (not name or house.type == name) then
                table.insert(t, house)
            end
        end
    end
    return t
end

function UtilsForBuilding:GetBuildingsBy(userData, nameOrLocation, level)
    level = level or 0
    local t = {}
    if type(nameOrLocation) ==  "string" then
        for _,building in pairs(userData.buildings) do
            if building.level >= level and building.type == nameOrLocation then
                table.insert(t, building)
            end
        end
    elseif type(nameOrLocation) == "number" then
        for _,building in pairs(userData.buildings) do
            if building.level >= level and building.location == nameOrLocation then
                table.insert(t, building)
                break
            end
        end
    end
    return t
end


function UtilsForBuilding:GetBuildingBy(userData, nameOrLocation)
    if type(nameOrLocation) == "string" then
        for k,v in pairs(userData.buildings) do
            if v.type == nameOrLocation then
                return v
            end
        end
    else
        for k,v in pairs(userData.buildings) do
            if v.location == nameOrLocation then
                return v
            end
        end
    end
end


function UtilsForBuilding:GetEfficiencyBy(userData, nameOrLocation, offset)
    return self:GetPropertyBy(userData, nameOrLocation, "efficiency", offset)
end
function UtilsForBuilding:GetPropertyBy(userData, nameOrLocation, property, offset)
    return self:GetFunctionConfigBy(userData, nameOrLocation, offset)[property]
end
function UtilsForBuilding:GetFunctionConfigBy(userData, nameOrLocationOrHouseOrBuilding, offset)
    offset = offset or 0
    local _type = type(nameOrLocationOrHouseOrBuilding)
    local houseOrBuilding
    if _type == "number" or _type == "string" then
        houseOrBuilding = self:GetBuildingBy(userData, nameOrLocationOrHouseOrBuilding)
    elseif _type == "table" then
        houseOrBuilding = nameOrLocationOrHouseOrBuilding
    end
    local configs = self:GetBuildingConfig(houseOrBuilding.type)
    local level = houseOrBuilding.level + offset
    level = level > #configs and #configs or level
    return configs[level]
end
function UtilsForBuilding:GetLevelUpConfigBy(userData, houseOrBuilding, offset)
    offset = offset or 0
    local configs = self:GetLevelUpConfig(houseOrBuilding.type)
    local level = houseOrBuilding.level + offset
    level = level > #configs and #configs or level
    return configs[level]
end


local HouseFunction = GameDatas.HouseFunction
local BuildingFunction = GameDatas.BuildingFunction
function UtilsForBuilding:GetBuildingConfig(houseOrBuildingName)
    return BuildingFunction[houseOrBuildingName] 
        or HouseFunction[houseOrBuildingName]
end
local HouseLevelUp = GameDatas.HouseLevelUp
local BuildingLevelUp = GameDatas.BuildingLevelUp
function UtilsForBuilding:GetLevelUpConfig(houseOrBuildingName)
    return BuildingLevelUp[houseOrBuildingName] 
        or HouseLevelUp[houseOrBuildingName]
end


local HouseLevelUp = GameDatas.HouseLevelUp
function UtilsForBuilding:GetCitizenMap(userData)
    local house_citizen = {
        miner = 0,
        farmer = 0,
        quarrier = 0,
        woodcutter = 0,
    }
    for _,building in pairs(userData.buildings) do
        for _,house in pairs(building.houses) do
            local value = house_citizen[house.type]
            if value then
                local citizen = house.level == 0 and 0 or HouseLevelUp[house.type][house.level].citizen
                house_citizen[house.type] = value + citizen
            end
        end
    end
    for _,event in pairs(userData.houseEvents) do
        local location_key = string.format("location_%d", event.buildingLocation)
        for _,house in pairs(userData.buildings[location_key].houses) do
            if house.location == event.houseLocation then
                local value = house_citizen[house.type]
                if value then
                    local config = HouseLevelUp[house.type]
                    local citizen = house.level == 0 and 0 or config[house.level].citizen
                    house_citizen[house.type] = value + config[house.level + 1].citizen - citizen
                end
                break
            end
        end
    end
    house_citizen.food = house_citizen.farmer
    house_citizen.wood = house_citizen.woodcutter
    house_citizen.iron = house_citizen.miner
    house_citizen.stone= house_citizen.quarrier

    house_citizen.total= house_citizen.miner
        + house_citizen.farmer
        + house_citizen.quarrier
        + house_citizen.woodcutter
    return house_citizen
end


local warehouse = GameDatas.BuildingFunction.warehouse
function UtilsForBuilding:GetWarehouseLimit(userData, offset)
    offset = offset or 0
    local limit = {
        maxWood = 0,
        maxFood = 0,
        maxIron = 0,
        maxStone= 0,
    }
    for _,building in ipairs(self:GetBuildingsBy(userData, "warehouse", 1)) do
        local level = building.level + offset
        level = level > #warehouse and #warehouse or level
        local config = warehouse[level]
        for k,v in pairs(limit) do
            limit[k] = v + config[k]
        end
    end
    return limit
end

local materialDepot = GameDatas.BuildingFunction.materialDepot
function UtilsForBuilding:GetMaterialDepotLimit(userData, offset)
    offset = offset or 0
    local limit = {
        dragonMaterials     = 0,
        soldierMaterials    = 0,
        buildingMaterials   = 0,
        technologyMaterials = 0,
    }
    for _,building in ipairs(self:GetBuildingsBy(userData, "materialDepot", 1)) do
        local level = building.level + offset
        level = level > #materialDepot and #materialDepot or level
        local config = materialDepot[level]
        for k,v in pairs(limit) do
            limit[k] = v + config[k]
        end
    end
    return limit
end


local intInit = GameDatas.PlayerInitData.intInit
local grassLandFoodAddPercent_value = intInit.grassLandFoodAddPercent.value/100
local grassLandWoodAddPercent_value = intInit.grassLandWoodAddPercent.value/100
local grassLandIronAddPercent_value = intInit.grassLandIronAddPercent.value/100
local grassLandStoneAddPercent_value = intInit.grassLandStoneAddPercent.value/100
function UtilsForBuilding:GetTerrainResourceBuff(userData)
    local buff = {
        food = 0,
        wood = 0,
        iron = 0,
        stone= 0,
        coin = 0,
        wallHp = 0,
        citizen= 0,
    }
    if userData.basicInfo.terrain == "grassLand" then
        buff.food = grassLandFoodAddPercent_value
        buff.wood = grassLandWoodAddPercent_value
        buff.iron = grassLandIronAddPercent_value
        buff.stone= grassLandStoneAddPercent_value
    end
    return setmetatable(buff, BUFF_META)
end


local production_map = {
    dwelling   = "coin",
    farmer     = "food",
    woodcutter = "wood",
    miner      = "iron",
    quarrier   = "stone",
}
local resource_buff_building = {
    mill       = "farmer",
    foundry    = "miner",
    lumbermill = "woodcutter",
    stoneMason = "quarrier",
    townHall   = "dwelling",
}
function UtilsForBuilding:GetBuildingsBuff(userData)
    local buff = {
        food = 0,
        wood = 0,
        iron = 0,
        stone= 0,
        coin = 0,
        wallHp = 0,
        citizen= 0,
    }
    local buildings = userData.buildings
    for location,building in pairs(buildings) do
        local house_type = resource_buff_building[building.type]
        if house_type and building.level > 0 then
            local _,index = unpack(string.split(location, "_"))
            index = tonumber(index)
            local neighbour_location = index == 15
                and string.format("location_%d", index - 1)
                or string.format("location_%d", index + 7)
            local count = 0
            for _,v in pairs(building.houses) do
                if v.type == house_type then
                    count = count + 1
                end
            end
            local houses = buildings[neighbour_location].houses
            for _,v in pairs(houses) do
                if v.type == house_type then
                    count = count + 1
                end
            end
            local res_type = production_map[house_type]
            buff[res_type] = buff[res_type] + (count >= 3 and 0.05 or 0)
            buff[res_type] = buff[res_type] + (count >= 6 and 0.05 or 0)
        end
    end
    return setmetatable(buff, BUFF_META)
end
local HouseFunction = GameDatas.HouseFunction
function UtilsForBuilding:GetHouseProductions(userData)
    local production = {
        wood  = 0,
        food  = 0,
        iron  = 0,
        stone = 0,
        coin  = 0,
    }
    for _,building in pairs(userData.buildings) do
        for _,house in pairs(building.houses) do
            if house.level > 0 then
                local res_type = production_map[house.type]
                production[res_type] = production[res_type] + HouseFunction[house.type][house.level].production
            end
        end
    end
    return setmetatable(production, BUFF_META)
end

local dwelling = GameDatas.HouseFunction.dwelling
local initCitizen_value = GameDatas.PlayerInitData.intInit.initCitizen.value
function UtilsForBuilding:GetCitizenLimit(userData)
    local limit = 0
    for _,house in ipairs(self:GetHousesBy(userData, "dwelling", 1)) do
        limit = limit + dwelling[house.level].citizen
    end
    return limit + initCitizen_value
end



local tradeGuild = GameDatas.BuildingFunction.tradeGuild
function UtilsForBuilding:GetTradeGuildInfo(userData)
    local info = {
        maxCart      = 0,
        maxSellQueue = 0,
        cartRecovery = 0,
    }
    local building = self:GetBuildingBy(userData, "tradeGuild")
    if building.level > 0 then
        local tech = userData.productionTechs["logistics"]
        local effect = UtilsForTech:GetEffect("logistics", tech)
        info.maxCart = math.ceil(tradeGuild[building.level].maxCart * (1 + effect))
        info.maxSellQueue = tradeGuild[building.level].maxSellQueue
        info.cartRecovery = tradeGuild[building.level].cartRecovery
    end
    return info
end
local wall = GameDatas.BuildingFunction.wall
function UtilsForBuilding:GetWallInfo(userData)
    local info = {
        wallHp = 0,
        wallRecovery = 0,
    }
    local building = self:GetBuildingBy(userData, "wall")
    if building.level > 0 then
        local config = wall[building.level]
        info.wallHp = config.wallHp
        info.wallRecovery = config.wallRecovery
    end
    return info
end


--获取伤病最大上限
local hospital = GameDatas.BuildingFunction.hospital
function UtilsForBuilding:GetMaxCasualty(userData, offset)
    offset = offset or 0
    assert(offset >= 0)
    local value = 0
    local tech = userData.productionTechs["rescueTent"]
    local tech_effect = UtilsForTech:GetEffect("rescueTent", tech)
    for _,building in ipairs(self:GetBuildingsBy(userData, "hospital", 1)) do
        local level = building.level + offset
        level = level > #hospital and #hospital or level
        return math.floor(hospital[level].maxCitizen * (1 + tech_effect))
    end
    return value
end


-- 
local keep = GameDatas.BuildingFunction.keep
function UtilsForBuilding:GetFreeUnlockPoint(userData)
    local unlocked_count = 0
    for _,building in pairs(userData.buildings) do
        if building.level > 0 
        and building.type ~= "wall"
        and building.type ~= "tower" then
            unlocked_count = unlocked_count + 1
        end
    end
    for _,event in pairs(userData.buildingEvents) do
        local building = self:GetBuildingBy(userData, event.location)
        if building.level == 0 
        and building.type ~= "wall"
        and building.type ~= "tower" then
            unlocked_count = unlocked_count + 1
        end
    end
    return self:GetUnlockPoint(userData) - unlocked_count
end
function UtilsForBuilding:GetUnlockPoint(userData, offset)
    offset = offset or 0
    assert(offset >= 0)
    for _,building in ipairs(self:GetBuildingsBy(userData, "keep", 1)) do
        local level = building.level + offset
        level = level > #keep and #keep or level
        return keep[level].unlock
    end
    assert(false)
end
function UtilsForBuilding:GetBeHelpedCount(userData, offset)
    offset = offset or 0
    assert(offset >= 0)
    for _,building in ipairs(self:GetBuildingsBy(userData, "keep", 1)) do
        local level = building.level + offset
        level = level > #keep and #keep or level
        return keep[level].beHelpedCount
    end
    assert(false)
end



local barracks = GameDatas.BuildingFunction.barracks
function UtilsForBuilding:GetMaxRecruitSoldier(userData, offset)
    offset = offset or 0
    assert(offset >= 0)
    local max = 0
    for _,building in ipairs(self:GetBuildingsBy(userData, "barracks", 1)) do
        local level = building.level + offset
        level = level > #barracks and #barracks or level
        max = max + barracks[level].maxRecruit
    end
    return max
end



local needs = {"Wood", "Stone", "Iron", "time"}
local toolShop = GameDatas.BuildingFunction.toolShop
function UtilsForBuilding:GetToolShopNeedByCategory(userData, category)
    for _,building in ipairs(self:GetBuildingsBy(userData, "toolShop", 1)) do
        local need = {}
        local config = toolShop[building.level]
        local key = category == "buildingMaterials" and "Bm" or "Am"
        for _, v in ipairs(needs) do
            table.insert(need, config[string.format("product%s%s", key, v)])
        end
        return config["production"], unpack(need)
    end
    assert(false)
end


local tradeGuild = GameDatas.BuildingFunction.tradeGuild
function UtilsForBuilding:GetMaxCart(userData, offset)
    offset = offset or 0
    local effect = UtilsForTech:GetEffect("logistics", userData.productionTechs["logistics"])
    for _,building in ipairs(self:GetBuildingsBy(userData, "tradeGuild", 1)) do
        local level = building.level + offset
        level = level > #tradeGuild and #tradeGuild or level
        return math.ceil(tradeGuild[level].maxCart * (1 + effect))
    end
    return 0
end
function UtilsForBuilding:GetMaxSellQueue(userData, offset)
    offset = offset or 0
    for _,building in ipairs(self:GetBuildingsBy(userData, "tradeGuild", 1)) do
        local level = building.level + offset
        level = level > #tradeGuild and #tradeGuild or level
        return tradeGuild[level].maxSellQueue
    end
    return 0
end
function UtilsForBuilding:GetCartRecovery(userData, offset)
    offset = offset or 0
    for _,building in ipairs(self:GetBuildingsBy(userData, "tradeGuild", 1)) do
        local level = building.level + offset
        level = level > #tradeGuild and #tradeGuild or level
        return tradeGuild[level].cartRecovery
    end
    return 0
end
function UtilsForBuilding:GetUnlockSellQueueLevel(queueIndex)
    for k,v in pairs(tradeGuild) do
        if v.maxSellQueue == queueIndex then
            return k
        end
    end
end



local p_resource_building_to_house = {
    ["townHall"] = "dwelling",
    ["foundry"] = "miner",
    ["stoneMason"] = "quarrier",
    ["lumbermill"] = "woodcutter",
    ["mill"] = "farmer",
}
function UtilsForBuilding:GetHouseType(buildingName)
    return p_resource_building_to_house[buildingName]
end
function UtilsForBuilding:GetBuildingProtection(userData, buildingName, offset)
    offset = offset or 0
    local configs = UtilsForBuilding:GetBuildingConfig(buildingName)
    local protection = 0
    for _,building in ipairs(self:GetBuildingsBy(userData, buildingName, 1)) do
        local level = building.level + offset
        level = level > #configs and #configs or level
        protection = protection + configs[level].protection
    end
    return protection
end


function UtilsForBuilding:GetFreeBuildQueueCount(userData)
    return userData.basicInfo.buildQueue - self:GetBuildingEventsCount(userData)
end
function UtilsForBuilding:GetBuildingEventsCount(userData)
    return #userData.buildingEvents + #userData.houseEvents
end
function UtilsForBuilding:GetBuildingEventsBySeq(userData)
    local events = {}
    for i,v in ipairs(userData.houseEvents) do
        table.insert(events, v)
    end
    for i,v in ipairs(userData.buildingEvents) do
        table.insert(events, v)
    end
    table.sort(events, function(a, b) return a.finishTime < b.finishTime end)
    return events
end
function UtilsForBuilding:GetBuildingByEvent(userData, event)
    if event.location then
        return self:GetBuildingByLocation(userData, event.location)
    end
    return self:GetHouseByLocation(userData, event.buildingLocation, event.houseLocation)
end
function UtilsForBuilding:GetHouseByLocation(userData, buildingLocation, houseLocation)
    local building = self:GetBuildingByLocation(userData, buildingLocation)
    assert(building)
    for i,v in ipairs(building.houses) do
        if v.location == houseLocation then
            return v
        end
    end
end
function UtilsForBuilding:GetBuildingByLocation(userData, location)
    return userData.buildings[string.format("location_%d", location)]
end
function UtilsForBuilding:GetBuildingEventByLocation(userData, buildingLocation, houseLocation)
    if houseLocation then
        for _,v in ipairs(userData.houseEvents) do
            if v.buildingLocation == buildingLocation
                and v.houseLocation == houseLocation then
                return v
            end
        end
    else
        for _,v in ipairs(userData.buildingEvents) do
            if v.location == buildingLocation then
                return v
            end
        end
    end
end
-- 取得小屋最大建造数量
local house2building = {
    dwelling = "townHall",
    woodcutter = "lumbermill",
    farmer = "mill",
    quarrier = "stoneMason",
    miner = "foundry",
}
local eachHouseInitCount_value = GameDatas.PlayerInitData.intInit.eachHouseInitCount.value
function UtilsForBuilding:GetMaxBuildHouse(userData, houseType)
    local max = eachHouseInitCount_value
    for _,building in ipairs(self:GetBuildingsBy(userData, house2building[houseType], 1)) do
        max = max + self:GetPropertyBy(userData, building.location, "houseAdd")
    end
    return max
end


-- 第一项是主要产出
local res_map = {
    miner      = "iron",
    farmer     = "food",
    quarrier   = "stone",
    woodcutter = "wood",
    dwelling   = "coin,citizen",
}
function UtilsForBuilding:GetHouseResType(houseType)
    return res_map[houseType]
end
function UtilsForBuilding:GetUsedCitizen(userData, house, buildingLocation, offset)
    offset = offset or 0
    local configs = self:GetLevelUpConfig(house.type)
    local efficiency_level = house.level
    if buildingLocation then
        for _,event in pairs(userData.houseEvents) do
            if buildingLocation == event.buildingLocation
            and house.location == event.houseLocation then
                efficiency_level = house.level + 1
            end
        end
    end
    return configs[efficiency_level].citizen
end
function UtilsForBuilding:GetUpgradeNowGems(userData, houseOrBuilding)
    local config = DataUtils:getBuildingUpgradeRequired(houseOrBuilding.type, houseOrBuilding.level)
    local required_gems = 0
    required_gems = required_gems + DataUtils:buyResource(config.resources, {})
    required_gems = required_gems + DataUtils:buyMaterial(config.materials, {})
    required_gems = required_gems + DataUtils:getGemByTimeInterval(config.buildTime)
    return required_gems
end
function UtilsForBuilding:GetNextLevel(houseOrBuilding)
    local level = houseOrBuilding.level
    local configs = self:GetLevelUpConfig(houseOrBuilding.type)
    return (configs == level) and level or level + 1
end
-- function UtilsForBuilding:IsAbleToUpgrade(userData, houseOrBuilding)
--     if res_map[houseOrBuilding.type] then
--         local citizen = self:GetLevelUpConfigBy(userData, houseOrBuilding).citizen
--         local next_citizen = self:GetLevelUpConfigBy(userData, houseOrBuilding, 1).citizen
--         local free_citizen_limit = userData:GetResProduction("citizen").limit
--         if next_citizen - citizen > free_citizen_limit then
--             return self.NOT_ABLE_TO_UPGRADE.FREE_CITIZEN_ERROR
--         end
--     end
-- end



