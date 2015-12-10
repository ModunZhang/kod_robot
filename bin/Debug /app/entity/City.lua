local intInit = GameDatas.PlayerInitData.intInit
local Localize = import("..utils.Localize")
local RecommendedMission = import(".RecommendedMission")
local BuildingRegister = import(".BuildingRegister")
local promise = import("..utils.promise")
local Enum = import("..utils.Enum")
local Orient = import(".Orient")
local Tile = import(".Tile")
local Building = import(".Building")
local GateEntity = import(".GateEntity")
local TowerEntity = import(".TowerEntity")
local TowerUpgradeBuilding = import(".TowerUpgradeBuilding")
local MultiObserver = import(".MultiObserver")
local property = import("..utils.property")
local City = class("City", MultiObserver)
local floor = math.floor
local ceil = math.ceil
local abs = math.abs
local max = math.max
local ipairs = ipairs
local pairs = pairs
local insert = table.insert
local format = string.format
City.LISTEN_TYPE = Enum(
    "LOCK_TILE",
    "UNLOCK_TILE",
    -- "UNLOCK_ROUND",
    "CREATE_DECORATOR",
    "OCCUPY_RUINS",
    "DESTROY_DECORATOR",
    "UPGRADE_BUILDING")
local only_one_buildings_map = {
    keep            = true,
    watchTower      = true,
    warehouse       = true,
    dragonEyrie     = true,
    barracks        = true,
    hospital        = true,
    academy         = true,
    materialDepot   = true,
    blackSmith      = true,
    tradeGuild      = true,
    townHall        = true,
    toolShop        = true,
    trainingGround  = true,
    hunterHall      = true,
    stable          = true,
    workshop        = true,
}
local illegal_map = {
    location_21 = true,
    location_22 = true
}
local function illegal_filter(key, func)
    if illegal_map[key] then return end
    func()
end
-- 初始化
function City:ctor(user)
    City.super.ctor(self)
    self.belong_user = user
    self.buildings = {}
    self.walls = {}
    self.gate = GateEntity.new({building_type = "wall", city = self}):AddUpgradeListener(self)
    self.tower = TowerEntity.new({building_type = "tower", city = self}):AddUpgradeListener(self)
    self.visible_towers = {}
    self.decorators = {}
    self.need_update_buildings = {}
    self.building_location_map = {}
    self:InitLocations()
    self:InitRuins()

    -- fte
    self.upgrading_building_callbacks = {}
    self.finish_upgrading_callbacks = {}
end
--------------------
function City:GetRecommendTask()
    -- 2015-8-13之后进入游戏的才有新推荐任务
    -- if self:GetUser().countInfo.registerTime > 1439476527805 then
    --     local task = self:GetBeginnersTask()
    --     if task then
    --         return task
    --     end
    -- end
    local building_map = self:GetHighestCanUpgradeBuildingMap()
    local tasks = UtilsForTask:GetAvailableTasksByCategory(
        self:GetUser().growUpTasks, UtilsForTask.TASK_CATEGORY.BUILD
    )
    local re_task
    for i,v in pairs(tasks.tasks) do
        if building_map[v:BuildingType()] then
            re_task = not re_task and v or (v.index < re_task.index and v or re_task)
        end
    end
    return re_task
end
function City:GetHighestCanUpgradeBuildingMap()
    local building_map = {}
    self:IteratorCanUpgradeBuildings(function(building)
        if building:IsUnlocked() then
            local highest = building_map[building:GetType()]
            building_map[building:GetType()] = not highest and
                building or
                (building:GetLevel() > highest:GetLevel() and
                building or
                highest)
        end
    end)
    for k,v in pairs(building_map) do
        if v:IsUpgrading() or not v:CanUpgrade() then
            building_map[k] = nil
        end
    end
    return building_map
end
---------
-- 领取奖励
local reward_meta = {}
reward_meta.__index = reward_meta
function reward_meta:Index()
    return self.index
end
function reward_meta:Title()
    return _("领取一次奖励")
end
function reward_meta:TaskType()
    return "reward"
end
-- 解锁建筑
local unlock_meta = {}
unlock_meta.__index = unlock_meta
function unlock_meta:Title()
    return string.format(_("解锁建筑%s"), Localize.building_name[self.name])
end
function unlock_meta:Location()
    return self.location_id
end
function unlock_meta:TaskType()
    return "unlock"
end
function unlock_meta:BuildingType()
    return self.name
end
-- 城市建设
local upgrade_meta = {}
upgrade_meta.__index = upgrade_meta
function upgrade_meta:Title()
    if self.level == 1 then
        return string.format(_("解锁建筑%s"), Localize.building_name[self.name])
    end
    return string.format(_("将%s升级到等级%d"), Localize.building_name[self.name], self.level)
end
function upgrade_meta:TaskType()
    return "cityBuild"
end
function upgrade_meta:BuildingType()
    return self.name
end
-- 科技研发
local tech_meta = {}
tech_meta.__index = tech_meta
function tech_meta:Title()
    return string.format(_("研发%s到等级%d"), Localize.productiontechnology_name[self.name], self.level)
end
function tech_meta:TaskType()
    return "productionTech"
end
-- 招募士兵
local recruit_meta = {}
recruit_meta.__index = recruit_meta
function recruit_meta:Index()
    return self.index
end
function recruit_meta:Title()
    return string.format(_("招募一次%s"), Localize.soldier_name[self.name])
end
function recruit_meta:TaskType()
    return "recruit"
end
-- 探索pve
local explore_meta = {}
explore_meta.__index = explore_meta
function explore_meta:Index()
    return self.index
end
function explore_meta:Title()
    return _("搭乘飞艇进行一次探险")
end
function explore_meta:TaskType()
    return "explore"
end
-- 建造小屋
local build_meta = {}
build_meta.__index = build_meta
function build_meta:Title()
    return string.format(_("建造一个%s"), Localize.building_name[self.name])
end
function build_meta:TaskType()
    return "build"
end
-- 领取新手冲级奖励
local encourage_meta = {}
encourage_meta.__index = encourage_meta
function encourage_meta:Title()
    return _("领取新手冲级奖励")
end
function encourage_meta:TaskType()
    return "encourage"
end
---

local default = {}
for i,v in ipairs(RecommendedMission) do
    default[i] = false
end
function City:GetBeginnersTask()
    local count = UtilsForTask:GetCompleteTaskCount(self:GetUser().growUpTasks)
    local key = string.format("recommend_tasks_%s", self:GetUser():Id())
    local flag = app:GetGameDefautlt():getTableForKey(key, default)
    for i,v in ipairs(RecommendedMission) do
        if v.type == "reward" and not flag[i] and count > 0 then
            return setmetatable({ index = i }, reward_meta)
        elseif v.type == "unlock" then
            if self:GetFirstBuildingByType("keep"):GetFreeUnlockPoint() > 0 then
                for i,lstr in ipairs(string.split(v.name, ",")) do
                    local location_id = tonumber(lstr)
                    local building = self:GetBuildingByLocationId(location_id)
                    if not building:IsUnlocked() and not building:IsUnlocking() then
                        return setmetatable({ name = building:GetType(), location_id = location_id }, unlock_meta)
                    end
                end
            end
        elseif v.type == "upgrade" then
            local building = self:GetHighestBuildingByType(v.name)
            if building then
                if building:GetLevel() < v.min then
                    if building:IsUpgrading() then
                        if building:GetNextLevel() < v.min then
                            return setmetatable({ name = v.name, level = building:GetNextLevel() + 1 }, upgrade_meta)
                        end
                    else
                        return setmetatable({ name = v.name, level = building:GetLevel() + 1 }, upgrade_meta)
                    end
                end
            end
        elseif v.type == "technology" then
            local event
            for i,t in ipairs(self:GetUser().productionTechEvents) do
                if v.name == t.name then
                    event = t
                end
            end
            local level = self:GetUser().productionTechs[v.name].level
            if level < v.min then
                if event then
                    if level + 1 < v.min then
                        return setmetatable({ name = v.name, level = level + 2 }, tech_meta)
                    end
                else
                    return setmetatable({ name = v.name, level = level + 1 }, tech_meta)
                end
            end
        elseif v.type == "recruit" and
            not flag[i] and
            self:GetUser().woundedSoldiers[v.name] == 0 then
            return setmetatable({ name = v.name, index = i }, recruit_meta)
        elseif v.type == "explore" and not flag[i] then
            return setmetatable({ index = i }, explore_meta)
        elseif v.type == "build" then
            if #self:GetDecoratorsByType(v.name) < v.min and self:GetLeftBuildingCountsByType(v.name) > 0 then
                return setmetatable({ name = v.name }, build_meta)
            end
        elseif v.type == "encourage" and self:GetUser():HavePlayerLevelUpReward() then
            return setmetatable({}, encourage_meta)
        end
    end
end
function City:SetBeginnersTaskFlag(index)
    local key = string.format("recommend_tasks_%s", self:GetUser():Id())
    local flag = app:GetGameDefautlt():getTableForKey(key, default)
    flag[index] = true
    app:GetGameDefautlt():setTableForKey(key, flag)
    app:GetGameDefautlt():flush()
end
--------------------
function City:GetUser()
    return self.belong_user
end
local function get_building_event_by_location(location_id, building_events)
    for k, v in pairs(building_events or {}) do
        if v.location == location_id then
            return v
        end
    end
end
local function get_house_event_by_location(building_location, sub_id, hosue_events)
    for _,v in pairs(hosue_events or {}) do
        if v.buildingLocation == building_location and
            v.houseLocation == sub_id then
            return v
        end
    end
end
function City:InitWithJsonData(userData)
    local init_buildings = {}
    local init_unlock_tiles = {{x = 1, y = 2}}

    local building_events = userData.buildingEvents
    table.foreach(userData.buildings, function(key, location)
        illegal_filter(key, function()
            local location_config = self:GetLocationById(location.location)
            local event = get_building_event_by_location(location.location, building_events)
            local finishTime = event == nil and 0 or event.finishTime / 1000
            insert(init_buildings,
                self:NewBuildingWithType(location.type,
                    location_config.x,
                    location_config.y,
                    location_config.w,
                    location_config.h,
                    location.level,
                    finishTime)
            )
            if location.level > 0 then
                insert(init_unlock_tiles, {x = location_config.tile_x, y = location_config.tile_y})
            end
        end)
    end)
    self:InitBuildings(init_buildings)

    -- table.insert(init_unlock_tiles, {x = 1, y = 3})
    -- table.insert(init_unlock_tiles, {x = 2, y = 3})
    -- table.insert(init_unlock_tiles, {x = 3, y = 3})
    -- table.insert(init_unlock_tiles, {x = 3, y = 2})
    -- table.insert(init_unlock_tiles, {x = 3, y = 1})

    -- table.insert(init_unlock_tiles, {x = 1, y = 4})
    -- table.insert(init_unlock_tiles, {x = 2, y = 4})
    -- table.insert(init_unlock_tiles, {x = 3, y = 4})
    -- table.insert(init_unlock_tiles, {x = 4, y = 4})
    -- table.insert(init_unlock_tiles, {x = 4, y = 3})
    -- table.insert(init_unlock_tiles, {x = 4, y = 2})
    -- table.insert(init_unlock_tiles, {x = 4, y = 1})

    -- table.insert(init_unlock_tiles, {x = 1, y = 5})
    -- table.insert(init_unlock_tiles, {x = 2, y = 5})
    -- table.insert(init_unlock_tiles, {x = 3, y = 5})
    -- table.insert(init_unlock_tiles, {x = 4, y = 5})
    self:InitTiles(5, 5, init_unlock_tiles)

    local hosue_events = userData.houseEvents
    local init_decorators = {}
    table.foreach(userData.buildings, function(key, location)
        illegal_filter(key, function()
            if #location.houses > 0 then
                table.foreach(location.houses, function(_, house)
                    local city_location = self:GetLocationById(location.location)
                    local tile_x = city_location.tile_x
                    local tile_y = city_location.tile_y
                    local tile = self:GetTileByIndex(tile_x, tile_y)
                    local absolute_x, absolute_y = tile:GetAbsolutePositionByLocation(house.location)
                    local event = get_house_event_by_location(location.location, house.location, hosue_events)
                    local finishTime = event == nil and 0 or event.finishTime / 1000
                    insert(init_decorators,
                        self:NewBuildingWithType(house.type,
                            absolute_x,
                            absolute_y,
                            3,
                            3,
                            house.level,
                            finishTime)
                    )
                end)
            end
        end)
    end)
    self:InitDecorators(init_decorators)
    self:GenerateWalls()



    for i,v in ipairs(self:GetAllBuildings()) do
        self.building_location_map[self:GetLocationIdByBuilding(v)] = v
    end
    self.building_location_map[21] = self:GetGate()
    self.building_location_map[22] = self:GetTower()
    return self
end
function City:ResetAllListeners()
    self.upgrading_building_callbacks = {}
    self.finish_upgrading_callbacks = {}

    self:ClearAllListener()
    self:IteratorCanUpgradeBuildings(function(building)
        building:ResetAllListeners()
        building:AddUpgradeListener(self)
    end)
end
function City:NewBuildingWithType(building_type, x, y, w, h, level, finish_time)
    return BuildingRegister[building_type].new{
        x = x,
        y = y,
        w = w,
        h = h,
        building_type = building_type,
        level = level,
        finishTime = finish_time,
        city = self,
    }
end
function City:InitRuins()
    self.ruins = {}
    for _,v in ipairs(GameDatas.ClientInitGame['ruins']) do
        insert(self.ruins,
            Building.new{
                building_type = v.building_type,
                x = v.x,
                y = v.y,
                w = v.w,
                h = v.h,
                city = self,
            }
        )
    end
end
function City:InitTiles(w, h, unlocked)
    self.tiles = {}
    for y = 1, h do
        insert(self.tiles, {})
        for x = 1, w do
            for location_id, location in pairs(self.locations) do
                if location.tile_x == x and location.tile_y == y then
                    self.tiles[y][x] = Tile.new({x = x, y = y, locked = true, location_id = location_id, city = self})
                end
            end
        end
    end
    if unlocked then
        for _, v in pairs(unlocked) do
            self.tiles[v.y][v.x].locked = false
        end
    end
end
function City:InitBuildings(buildings)
    self.buildings = buildings
    table.foreach(buildings, function(key, building)
        local type_ = building:GetType()
        if only_one_buildings_map[type_] then
            assert(not self[type_])
            self[type_] = building
        end
        building:AddUpgradeListener(self)
    end)
end
function City:InitLocations()
    self.locations = GameDatas.ClientInitGame.locations
    self.locations_decorators = {}
    table.foreach(self.locations, function(location_id, location)
        self.locations_decorators[location_id] = {}
    end)
end
function City:InitDecorators(decorators)
    self.decorators = decorators
    table.foreach(decorators, function(key, building)
        building:AddUpgradeListener(self)

        local tile = self:GetTileWhichBuildingBelongs(building)
        local sub_location = tile:GetBuildingLocation(building)
        assert(sub_location)
        self:GetDecoratorsByLocationId(tile.location_id)[sub_location] = building
    end)
    self:CheckIfDecoratorsIntersectWithRuins()
end
-- 取值函数
function City:PreconditionByBuildingType(preName)
    if preName == "tower" then
        return self:GetNearGateTower()
    elseif preName == "wall" then
        return self:GetVisibleGate()
    else
        return self:GetHighestBuildingByType(preName)
    end
end
function City:GetDragonEyrie()
    return self:GetFirstBuildingByType("dragonEyrie")
end
function City:GetHousesAroundFunctionBuildingByType(building, building_type, len)
    return self:GetHousesAroundFunctionBuildingWithFilter(building, len, function(house)
        return house:GetType() == building_type and house:IsUnlocked()
    end)
end
function City:GetHousesAroundFunctionBuildingWithFilter(building, len, filter)
    assert(self:IsFunctionBuilding(building))
    len = len or 2
    local r = {}
    self:IteratorDecoratorBuildingsByFunc(function(_,v)
        if building:IsNearByBuildingWithLength(v, len) and type(filter) == "function" and filter(v) then
            insert(r, v)
        end
    end)
    return r
end
function City:IsFunctionBuilding(building)
    if building:GetType() == "tower" then
        return true
    elseif building:GetType() == "wall" then
        return true
    end
    local location_id = self:GetLocationIdByBuilding(building)
    if location_id then
        return self:GetBuildingByLocationId(location_id):IsSamePositionWith(building)
    end
end
function City:IsHouse(building)
    return building:IsHouse()
end
function City:IsTower(building)
    return iskindof(building, "TowerEntity")
end
function City:IsGate(building)
    return iskindof(building, "GateEntity")
end
function City:GetAvailableBuildQueueCounts()
    return self:GetUser().basicInfo.buildQueue - #self:GetUpgradingBuildings()
end
function City:GetUpgradingBuildings(need_sort)
    local builds = {}
    self:IteratorCanUpgradeBuildings(function(building)
        if building:IsUpgrading() then
            insert(builds, building)
        end
    end)
    if need_sort then
        table.sort(builds, function(a, b)
            local a_index = self:GetLocationIdByBuildingType(a:GetType())
            local b_index = self:GetLocationIdByBuildingType(b:GetType())
            if a_index and b_index then
                return a_index < b_index
            elseif a_index == nil and b_index then
                return false
            elseif a_index and b_index == nil then
                return true
            else
                return a:GetType() == b:GetType() and a:IsAheadOfBuilding(b) or a:IsImportantThanBuilding(b)
            end
        end)
    end
    return builds
end
function City:GetUpgradingBuildingsWithOrder(current_time)
    local builds = {}
    self:IteratorCanUpgradeBuildings(function(building)
        if building:IsUpgrading() then
            insert(builds, building)
        end
    end)
    table.sort(builds, function(a, b)
        return a:GetUpgradingLeftTimeByCurrentTime(current_time) < b:GetUpgradingLeftTimeByCurrentTime(current_time)
    end)
    return builds
end
function City:GetLeftBuildingCountsByType(building_type)
    return self:GetMaxHouseCanBeBuilt(building_type) - #self:GetBuildingByType(building_type)
end
local function alignmeng_path(path)
    if #path <= 3 then
        return path
    end
    local index = 1
    while index <= #path - 2 do
        local start = path[index]
        local middle = path[index + 1]
        local ending = path[index + 2]
        local dx = ending.x - start.x
        local dy = ending.y - start.y
        if ((start.x == middle.x and middle.x == ending.x and
            abs((ending.y + start.y) * 0.5 - middle.y) < abs(ending.y - start.y))
            or (start.y == middle.y and middle.y == ending.y) and
            abs((ending.x + start.x) * 0.5 - middle.x) < abs(ending.x - start.x))
        then
            table.remove(path, index + 1)
        else
            index = index + 1
        end
    end
    return path
end
function City:FindAPointWayFromPosition(x, y)
    return self:FindAPointWayFromTileAt(self:GetTileByBuildingPosition(x, y), {x = x, y = y})
end
function City:FindAPointWayFromTile()
    return self:FindAPointWayFromTileAt()
end
function City:FindAPointWayFromTileAt(tile, point)
    local path_tiles = self:FindATileWayFromTile(tile)
    local path_point = LuaUtils:table_map(path_tiles, function(k, v)
        return k, v:GetCrossPoint()
    end)
    insert(path_point, 1, point or path_tiles[1]:RandomPoint())
    insert(path_point, #path_point + 1, path_tiles[#path_tiles]:RandomPoint())
    return alignmeng_path(path_point)
end
local function find_path_tile(connectedness, start_tile)
    if #connectedness == 0 then
        assert(start_tile)
        return {start_tile}
    end
    local r = {start_tile or table.remove(connectedness, math.random(#connectedness))}
    local index = 1
    local changed = true
    while changed do
        local cur_nearbys = {}
        for i, v in ipairs(connectedness) do
            local cur = r[index]
            if cur:IsNearBy(v) then
                insert(cur_nearbys, i)
            end
        end
        if #cur_nearbys > 0 then
            insert(r, table.remove(connectedness, cur_nearbys[math.random(#cur_nearbys)]))
            index = index + 1
            changed = true
        else
            changed = false
        end
    end
    return r
end
function City:FindATileWayFromTile(tile)
    local r = tile == nil and self:GetConnectedTiles() or tile:FindConnectedTilesFromThis()
    return find_path_tile(r, tile)
end
function City:GetConnectedTiles()
    local r = {}
    self:IteratorTilesByFunc(function(x, y, tile)
        if tile:IsConnected() then
            insert(r, tile)
        end
    end)
    return r
end
-- 取得小屋最大建造数量
local BUILDING_MAP = {
    dwelling = "townHall",
    woodcutter = "lumbermill",
    farmer = "mill",
    quarrier = "stoneMason",
    miner = "foundry",
}
function City:GetMaxHouseCanBeBuilt(house_type)
    --基础值
    local max = intInit.eachHouseInitCount.value
    for _, v in pairs(self:GetBuildingByType(BUILDING_MAP[house_type])) do
        max = max + v:GetMaxHouseNum()
    end
    return max
end
function City:GetFunctionBuildingsWithOrder()
    local r = {}
    for k,v in pairs(self.building_location_map) do
        insert(r, v)
    end
    table.sort(r, function(a, b)
        if a:IsUnlocked() and b:IsUnlocked() then
            if a:GetLevel() < b:GetLevel() then
                return true
            elseif a:GetLevel() > b:GetLevel() then
                return false
            end
            return a:IsImportantThanBuilding(b)
        elseif not a:IsUnlocked() and b:IsUnlocked() then
            return false
        elseif a:IsUnlocked() and not b:IsUnlocked() then
            return true
        elseif not a:IsUnlocked() and not b:IsUnlocked() then
            return a:IsImportantThanBuilding(b)
        end
    end)
    return r
end
function City:GetAllBuildings()
    return self.buildings
end
function City:GetHousesWhichIsBuilded()
    local r = {}
    for i, v in ipairs(self:GetAllDecorators()) do
        insert(r, v)
    end
    table.sort(r, function(a, b)
        local compare = b:GetLevel() - a:GetLevel()
        return compare == 0 and a:IsAheadOfBuilding(b) or (compare > 0 and true or false)
    end)
    return r
end
function City:GetAllDecorators()
    return self.decorators
end
function City:GetDecoratorsByLocationId(location_id)
    if not self.locations_decorators[location_id] then
        self.locations_decorators[location_id] = {}
        return
    end
    return self.locations_decorators[location_id]
end
function City:GetLocationIdByBuilding(building)
    return self:GetTileWhichBuildingBelongs(building).location_id
end
local config_buildings = GameDatas.Buildings.buildings
function City:GetLocationIdByBuildingType(building_type)
    for _, v in ipairs(config_buildings) do
        if building_type == v.name then
            return v.location
        end
    end
    return nil
end
function City:GetBuildingByLocationId(location_id)
    return self.building_location_map[location_id]
end
function City:GetFirstBuildingByType(type_)
    if only_one_buildings_map[type_] then
        return self[type_]
    end
    return self:GetBuildingByType(type_)[1]
end
function City:GetHighestBuildingByType(type_)
    local highest
    for _,v in ipairs(self:GetBuildingByType(type_)) do
        if not highest or highest:GetLevel() < v:GetLevel() then
            highest = v
        end
    end
    return highest
end
function City:GetLowestestBuildingByType(type_)
    local lowest
    for _,v in ipairs(self:GetBuildingByType(type_)) do
        if not lowest or lowest:GetLevel() > v:GetLevel() then
            lowest = v
        end
    end
    return lowest
end
function City:GetBuildingByType(type_)
    local find_buildings = {}
    local filter = function(_, building)
        if building:GetType() == type_ then
            insert(find_buildings, building)
        end
    end
    for _,v in pairs(self.building_location_map) do
        filter(nil, v)
    end
    self:IteratorDecoratorBuildingsByFunc(filter)
    return find_buildings
end
function City:GetDecoratorByPosition(x, y)
    local find_decorator = nil
    self:IteratorDecoratorBuildingsByFunc(function(key, building)
        if building:IsContainPoint(x, y) then
            find_decorator = building
            return true
        end
    end)
    return find_decorator
end
function City:GetTileWhichBuildingBelongs(building)
    if building:GetType() == "watchTower" then
        return self:GetTileByLocationId(2)
    end
    return self:GetTileByBuildingPosition(building.x, building.y)
end
function City:GetTileByBuildingPosition(x, y)
    return self:GetTileByIndex(floor(x / 10) + 1, floor(y / 10) + 1)
end
function City:GetTileByLocationId(location_id)
    local location_info = self:GetLocationById(location_id)
    return self:GetTileByIndex(location_info.tile_x, location_info.tile_y)
end
function City:GetLocationById(location_id)
    return self.locations[location_id]
end
function City:GetTileByIndex(x, y)
    return self.tiles[y] and self.tiles[y][x] or nil
end
function City:IsUnLockedAtIndex(x, y)
    return not self.tiles[y][x].locked
end
function City:IsTileCanbeUnlockAt(x, y)
    -- 没有第五圈
    if x == 5 then
        return false
    end
    -- 是否解锁
    if not self:GetTileByIndex(x, y) then
        return false
    end
    if not self:GetTileByIndex(x, y).locked then
        return false
    end
    -- 检查内圈
    local inner_round_number = self:GetAroundByPosition(x, y) - 1
    if not self:IsUnlockedInAroundNumber(inner_round_number) then
        return false
    end
    -- 检查临边
    for iy, row in ipairs(self.tiles) do
        for jx, col in ipairs(row) do
            if not col.locked and abs(x - jx) + abs(y - iy) <= 1 then
                return true
            end
        end
    end
    -- 临边未解锁
    return false
end
-- local t = {
--     [1] = 3,
--     [2] = 5,
--     [3] = 7,
--     [4] = 9,
--     [5] = 11,
-- }
-- function City:GetUnlockTowerLimit()
--     return t[self:GetUnlockAround()]
-- end
-- function City:GetUnlockAround()
--     local t = { 5, 4, 3, 2, 1 }
--     for _, round_number in ipairs(t) do
--         if self:IsUnlockedInAroundNumber(round_number) then
--             return round_number
--         end
--     end
--     assert(false)
-- end
function City:IsUnlockedInAroundNumber(roundNumber)
    if roundNumber <= 0 then
        return true
    end
    local tiles = self.tiles
    local h = #tiles
    local w = #tiles[1]
    assert(roundNumber <= h)
    assert(roundNumber <= w)
    for row = 1, roundNumber do
        for col = 1, roundNumber do
            if tiles[row][col].locked then
                return false
            end
        end
    end
    return true
end
function City:GetAroundByPosition(x, y)
    return max(x, y)
end
function City:GetWalls()
    return self.walls
end
function City:GetVisibleGate()
    return self.visible_gate
end
function City:GetGate()
    return self.gate
end
function City:GetTower()
    return self.tower
end
function City:GetVisibleTowers()
    return self.visible_towers
end
function City:GetNearGateTower()
    local gate = self:GetVisibleGate()
    for _,v in pairs(self:GetVisibleTowers()) do
        if v:IsNearByBuildingWithLength(gate, 5) then
            return v
        end
    end
    return self:GetVisibleTowers()[1]
end
-- function City:GetCanUpgradingTowers()
--     local visible_towers = {}
--     table.foreach(self.visible_towers, function(_, tower)
--         if tower:IsUnlocked() then
--             table.insert(visible_towers, tower)
--         end
--     end)
--     return visible_towers
-- end
-- 工具
function City:IteratorCanUpgradeBuildings(func)
    for _,v in pairs(self.building_location_map) do
        func(v)
    end
    self:IteratorDecoratorBuildingsByFunc(function(key, building)
        func(building)
    end)
end
function City:IteratorCanUpgradeBuildingsByUserData(user_data, current_time, deltaData)
    local is_fully_update = deltaData == nil
    local is_delta_update = not is_fully_update and (deltaData.buildings or deltaData.buildingEvents or deltaData.houseEvents)

    local need_delta_update_buildings = {}
    local building_events_map = {}
    for _,v in ipairs(user_data.buildingEvents or {}) do
        building_events_map[v.location] = v
        insert(need_delta_update_buildings, v.location)
    end

    local need_delta_update_houses_events = {}
    local house_events_map = {}
    for _,v in ipairs(user_data.houseEvents or {}) do
        local key = v.buildingLocation * 100 + v.houseLocation
        house_events_map[key] = v
        need_delta_update_houses_events[key] = v
    end

    local buildings = user_data.buildings
    if is_fully_update then
        for location_id,v in pairs(self.building_location_map) do
            local location_info = buildings["location_"..location_id]
            v:OnUserDataChanged(user_data, current_time, location_info, nil, deltaData, building_events_map[location_id])
            local houses = self:GetDecoratorsByLocationId(location_id)
            for _,house_info in pairs(location_info.houses) do
                local house_location = house_info.location
                houses[house_location]:OnUserDataChanged(user_data, current_time, nil, house_info, deltaData, house_events_map[location_id * 100 + house_location])
            end
        end
    elseif is_delta_update then
        local need_delta_update_houses = {}
        for k,location_info in pairs(deltaData.buildings or {}) do
            if location_info then
                local location_id = buildings[k].location
                if location_info.level or location_info.type then
                    insert(need_delta_update_buildings, location_id)
                end
                local houses = location_info.houses
                if houses then
                    for _,v in ipairs(houses.edit or {}) do
                        need_delta_update_houses[location_id * 100 + v.location] = v
                    end
                    for _,v in ipairs(houses.add or {}) do
                        need_delta_update_houses[location_id * 100 + v.location] = v
                    end
                end
            end
        end
        local building_location_map = self.building_location_map
        for i,location_id in ipairs(need_delta_update_buildings) do
            building_location_map[location_id]:OnUserDataChanged(user_data, current_time, buildings[format("location_%d", location_id)], nil, deltaData, building_events_map[location_id])
        end
        for k,v in pairs(need_delta_update_houses) do
            need_delta_update_houses_events[k] = nil
            self:GetDecoratorsByLocationId((k - v.location) / 100)[v.location]
                :OnUserDataChanged(
                    user_data,
                    current_time,
                    nil,
                    v,
                    deltaData,
                    house_events_map[k]
                )
        end
        for k,v in pairs(need_delta_update_houses_events) do
            local location_info = buildings[format("location_%d", v.buildingLocation)]
            local house_location_info
            for _,house in pairs(location_info.houses) do
                if house.location == v.houseLocation then
                    house_location_info = house
                    break
                end
            end
            self:GetDecoratorsByLocationId((k - v.houseLocation) / 100)[v.houseLocation]
                :OnUserDataChanged(
                    user_data,
                    current_time,
                    nil,
                    house_location_info,
                    deltaData,
                    house_events_map[k]
                )
        end
    else
        self:IteratorFunctionBuildingsByFunc(function(key, building)
            local tile = self:GetTileWhichBuildingBelongs(building)
            local location_info = buildings[format("location_%d", tile.location_id)]
            building:OnUserDataChanged(user_data, current_time, location_info, nil, deltaData, building_events_map[tile.location_id])
        end)
    end
end
function City:IteratorAllNeedTimerEntity(current_time)
    for _,v in ipairs(self.need_update_buildings) do
        v:OnTimer(current_time)
    end
end
-- 遍历顺序影响城墙的生成
function City:IteratorTilesByFunc(func)
    for iy, row in pairs(self.tiles) do
        for jx, col in pairs(row) do
            if func(jx, iy, col) then
                return
            end
        end
    end
    -- for iy, row in ipairs(self.tiles) do
    --     for ix = #row, 1, -1 do
    --         if func(jx, iy, row[ix]) then
    --             return
    --         end
    --     end
    -- end
end
-- function City:IteratorTowersByFunc(func)
--     table.foreach(self:GetCanUpgradingTowers(), func)
-- end
function City:IteratorFunctionBuildingsByFunc(func)
    table.foreach(self:GetAllBuildings(), func)
end
function City:IteratorDecoratorBuildingsByFunc(func)
    table.foreach(self:GetAllDecorators(), func)
end
function City:CheckIfDecoratorsIntersectWithRuins()
    local occupied_ruins = {}
    self:IteratorDecoratorBuildingsByFunc(function(key, building)
        for _, ruin in ipairs(self.ruins) do
            if building:IsIntersectWithOtherBuilding(ruin) and
                not ruin.has_been_occupied then
                ruin.has_been_occupied = true
                insert(occupied_ruins, ruin)
            end
        end
    end)
    self:NotifyListeneOnType(City.LISTEN_TYPE.OCCUPY_RUINS, function(listener)
        listener:OnOccupyRuins(occupied_ruins)
    end)
end
function City:GetNeighbourRuinWithSpecificRuin(ruin)
    local neighbours_position = {
        { x = ruin.x + 3, y = ruin.y },
        { x = ruin.x, y = ruin.y + 3 },
        { x = ruin.x - 3, y = ruin.y },
        { x = ruin.x, y = ruin.y - 3 },
    }
    local out_put_neighbours_position = {}
    local belong_tile = self:GetTileWhichBuildingBelongs(ruin)
    for k, v in pairs(neighbours_position) do
        local is_in_same_tile = self:GetTileByBuildingPosition(v.x, v.y) == belong_tile
        if is_in_same_tile then
            insert(out_put_neighbours_position, v)
        end
    end
    local neighbours = {}
    for _, position in pairs(out_put_neighbours_position) do
        for _, v in ipairs(self.ruins) do
            if not v.has_been_occupied and v.x == position.x and v.y == position.y then
                insert(neighbours, v)
                break
            end
        end
    end
    return neighbours
end
-- 功能函数
function City:OnTimer(time)
    self:IteratorAllNeedTimerEntity(time)
end
function City:CreateDecorator(current_time, decorator_building)
    insert(self.decorators, decorator_building)

    local tile = self:GetTileWhichBuildingBelongs(decorator_building)
    local sub_location = tile:GetBuildingLocation(decorator_building)
    assert(sub_location)
    assert(self:GetDecoratorsByLocationId(tile.location_id)[sub_location] == nil)
    self:GetDecoratorsByLocationId(tile.location_id)[sub_location] = decorator_building

    self:OnCreateDecorator(current_time, decorator_building)

    self:CheckIfDecoratorsIntersectWithRuins()
    self:NotifyListeneOnType(City.LISTEN_TYPE.CREATE_DECORATOR, function(listener)
        listener:OnCreateDecorator(decorator_building)
    end)

end
function City:GetRuinByLocationIdAndHouseLocationId(id, house_id)
    local x,y = self:GetTileByLocationId(id):GetAbsolutePositionByLocation(house_id)
    for k,v in pairs(self.ruins) do
        if v.x == x and v.y == y then
            return v
        end
    end
end
--获取没有被占用了的废墟
function City:GetRuinsNotBeenOccupied()
    local r = {}
    table.foreach(self.ruins, function(key, ruin)
        if not ruin.has_been_occupied  and
            not self:GetTileWhichBuildingBelongs(ruin).locked then
            insert(r,ruin)
        end
    end)
    return r
end
--根据type获取装饰物列表
function City:GetCitizenByType(building_type)
    local total_citizen = 0
    for k, v in pairs(self:GetDecoratorsByType(building_type)) do
        total_citizen = total_citizen + v:GetCitizen()
    end
    return total_citizen
end
function City:GetDecoratorsByType(building_type)
    local r = {}
    self:IteratorDecoratorBuildingsByFunc(function(key, building)
        if building:GetType() == building_type then
            insert(r, building)
        end
    end)
    return r
end
function City:DestoryDecorator(current_time, building)
    self:DestoryDecoratorByPosition(current_time, building.x, building.y)
end
function City:DestoryDecoratorByPosition(current_time, x, y)
    local destory_decorator = self:GetDecoratorByPosition(x, y)

    if destory_decorator then
        local release_ruins = {}
        for _, ruin in ipairs(self.ruins) do
            if ruin.has_been_occupied then
                if ruin:IsIntersectWithOtherBuilding(destory_decorator) and
                    ruin.has_been_occupied then
                    ruin.has_been_occupied = nil
                    insert(release_ruins, ruin)
                end
            end
        end

        table.foreachi(self:GetAllDecorators(), function(i, building)
            if building == destory_decorator then
                table.remove(self.decorators, i)
                return true
            end
        end)

        local tile = self:GetTileWhichBuildingBelongs(destory_decorator)
        table.foreach(self:GetDecoratorsByLocationId(tile.location_id), function(key, building)
            if building == destory_decorator then
                assert(self:GetDecoratorsByLocationId(tile.location_id)[key])
                self:GetDecoratorsByLocationId(tile.location_id)[key] = nil
                return true
            end
        end)

        self:OnDestoryDecorator(current_time, destory_decorator)

        self:NotifyListeneOnType(City.LISTEN_TYPE.DESTROY_DECORATOR, function(listener)
            listener:OnDestoryDecorator(destory_decorator, release_ruins)
        end)
        return true
    end
end
----------- 功能扩展点
function City:OnUserDataChanged(userData, current_time, deltaData)
    local _,is_unlock_any_tiles,unlock_table = self:OnHouseChanged(userData, current_time, deltaData)
    self:IteratorCanUpgradeBuildingsByUserData(userData, current_time, deltaData)
    if is_unlock_any_tiles then
        LuaUtils:outputTable("unlock_table", unlock_table)
        self:UnlockTilesByIndexArray(unlock_table)
    end
    local need_update_buildings = {}
    self:IteratorCanUpgradeBuildings(function(building)
        if building:IsNeedToUpdate() then
            insert(need_update_buildings, building)
        end
    end)
    self.need_update_buildings = need_update_buildings
    return self
end
local function find_building_info_by_location(houses, location_id)
    for _, v in pairs(houses) do
        if v.location == location_id then
            return v
        end
    end
end
function City:OnHouseChanged(userData, current_time, deltaData)
    local is_fully_update = deltaData == nil
    local is_delta_update = not is_fully_update and (deltaData.buildings ~= nil or deltaData.buildingEvents ~= nil)

    local buildings = {}
    if is_fully_update then
        buildings = userData.buildings
    elseif is_delta_update then
        local userDataBuildings = userData.buildings
        for k,v in pairs(deltaData.buildings or {}) do
            buildings[k] = userDataBuildings[k]
        end
    else
        return false
    end

    local unlock_table = {}
    local is_unlock_any_tiles = false
    for i,v in ipairs(userData.buildingEvents or {}) do
        if self:GetBuildingByLocationId(v.location):GetLevel() == 0 then
            is_unlock_any_tiles = true
            break
        end
    end

    table.foreach(buildings, function(_, location)
        local location_id = location.location
        illegal_filter(_, function()
            local building = self:GetBuildingByLocationId(location_id)
            local is_unlocked = building:GetLevel() == 0 and (location.level > 0)
            local tile = self:GetTileByLocationId(location_id)
            if is_unlocked and tile.locked then
                is_unlock_any_tiles = true
                insert(unlock_table, {x = tile.x, y = tile.y})
            end

            -- 拆除 or 交换
            local decorators = self:GetDecoratorsByLocationId(location_id)
            table.foreach(decorators, function(_, building)

                    -- 当前位置有小建筑并且推送的数据里面没有就认为是拆除
                    local house_location_id = tile:GetBuildingLocation(building)
                    local house_info = find_building_info_by_location(location.houses, house_location_id)

                    -- 没有找到，就是已经被拆除了
                    -- 如果类型不对也认为是删除
                    if not house_info or
                        (house_info.type ~= building:GetType()) then
                        self:DestoryDecorator(current_time, building)
                    end
            end)

            -- 新建的
            table.foreach(location.houses, function(_, house)
                -- 当前位置没有小建筑并且推送的数据里面有就认为新建小建筑
                if not decorators[house.location] then
                    local absolute_x, absolute_y = tile:GetAbsolutePositionByLocation(house.location)
                    self:CreateDecorator(current_time, BuildingRegister[house.type].new({
                        x = absolute_x,
                        y = absolute_y,
                        w = 3,
                        h = 3,
                        building_type = house.type,
                        level = house.level,
                        finishTime = 0,
                        city = self,
                    }))
                end
            end)
        end)
    end)
    return true, is_unlock_any_tiles, unlock_table
end
function City:OnCreateDecorator(current_time, building)
    building:AddUpgradeListener(self)
end
function City:OnDestoryDecorator(current_time, building)
    building:RemoveUpgradeListener(self)
end
function City:OnBuildingUpgradingBegin(building, current_time)
    self:CheckUpgradingBuildingPormise(building)
end
function City:OnBuildingUpgrading(building, current_time)
end
function City:OnBuildingUpgradeFinished(building)
    self:CheckFinishUpgradingBuildingPormise(building)
end
function City:LockTilesByIndexArray(index_array)
    table.foreach(index_array, function(_, index)
        self.tiles[index.y][index.x].locked = true
    end)
    self:GenerateWalls()
    local city = self
    self:NotifyListeneOnType(City.LISTEN_TYPE.LOCK_TILE, function(listener)
        listener:OnTileLocked(city)
    end)
end
function City:LockTilesByIndex(x, y)
    self.tiles[y][x].locked = true
    self:GenerateWalls()
    local city = self
    self:NotifyListeneOnType(City.LISTEN_TYPE.LOCK_TILE, function(listener)
        listener:OnTileLocked(city, x, y)
    end)
end
function City:UnlockTilesByIndexArray(index_array)
    table.foreach(index_array, function(_, index)
        self.tiles[index.y][index.x].locked = false
    end)
    self:GenerateWalls()
    local city = self
    self:NotifyListeneOnType(City.LISTEN_TYPE.UNLOCK_TILE, function(listener)
        listener:OnTileUnlocked(city)
    end)
end
function City:UnlockTilesByIndex(x, y)
    local success, ret_code = self:IsTileCanbeUnlockAt(x, y)
    if not success then
        return success, ret_code
    end
    self.tiles[y][x].locked = false
    self:GenerateWalls()
    local city = self
    self:NotifyListeneOnType(City.LISTEN_TYPE.UNLOCK_TILE, function(listener)
        listener:OnTileUnlocked(city, x, y)
    end)
    -- 检查是否解锁完一圈
    -- local round = self:GetAroundByPosition(x, y)
    -- if self:IsUnlockedInAroundNumber(round) then
    --     self:NotifyListeneOnType(City.LISTEN_TYPE.UNLOCK_ROUND, function(listener)
    --         listener:OnRoundUnlocked(round)
    --     end)
    -- end
    return success, ret_code
end
-- function City:OnInitBuilding(building)
--     building.city = self
--     building:AddUpgradeListener(self)
-- end
---------
local function find_beside_wall(walls, wall)
    for i, v in ipairs(walls) do
        if wall:IsEndJoinStartWithOtherWall(v) then
            return i
        end
    end
end
function City:GenerateWalls()
    local walls = {}
    self:IteratorTilesByFunc(function(x, y, tile)
        if tile:NeedWalls() then
            tile:IteratorWallsAroundSelf(function(_, wall)
                insert(walls, wall)
            end)
        end
    end)

    local count = #walls

    for ik, wall in pairs(walls) do
        for jk, other in pairs(walls) do
            if wall:IsDupWithOtherWall(other) then
                walls[ik] = nil
                walls[jk] = nil
            end
        end
    end

    local real_walls = {}
    for i = 1, count do
        local w = walls[i]
        if w then
            insert(real_walls, w)
        end
    end

    -- -- 边排序,首尾相连接
    local first = table.remove(real_walls, 1)
    local sort_walls = { first }
    while #real_walls > 0 do
        local index = find_beside_wall(real_walls, first)
        if index then
            local f = first
            first = table.remove(real_walls, index)
            insert(sort_walls, first)
        else
            break
        end
    end

    -- 重新生成城门的监听
    local t = {}
    for _, v in ipairs(sort_walls) do
        local x, y = v:GetLogicPosition()
        if (v:GetOrient() == Orient.X) or
            (v:GetOrient() == Orient.Y) or
            (x > 0 and y > 0) then
            insert(t, v)
            if v:IsGate() then
                self.visible_gate = v
            end
        end
    end

    self.walls = t

    -- 生成防御塔
    self:GenerateTowers(sort_walls)
end
function City:GenerateTowers(walls)
    local visible_towers = {}
    local p = walls[#walls]:IntersectWithOtherWall(walls[1])
    insert(visible_towers,
        TowerUpgradeBuilding.new({
            building_type = "tower",
            x = p.x,
            y = p.y,
            level = -1,
            orient = p.orient,
            sub_orient = p.sub_orient,
            city = self,
        })
    )

    for i, v in pairs(walls) do
        if i < #walls then
            local p = walls[i]:IntersectWithOtherWall(walls[i + 1])
            if p then
                insert(visible_towers,
                    TowerUpgradeBuilding.new({
                        building_type = "tower",
                        x = p.x,
                        y = p.y,
                        level = -1,
                        orient = p.orient,
                        sub_orient = p.sub_orient,
                        city = self,
                    })
                )
            end
        end
    end

    local visible_tower = {}
    for _, v in ipairs(visible_towers) do
        if v:IsVisible() then
            insert(visible_tower, v)
        end
    end

    self.visible_towers = visible_tower
end

-- promise
local function promiseOfBuilding(callbacks, building_type, level)
    assert(#callbacks == 0)
    local p = promise.new()
    insert(callbacks, function(building)
        if building_type == nil or (building:GetType() == building_type and (not level or level == building:GetLevel())) then
            return p:resolve(building)
        end
    end)
    return p
end
local function checkBuilding(callbacks, building)
    if #callbacks > 0 and callbacks[1](building) then
        table.remove(callbacks, 1)
    end
end
function City:PromiseOfUpgradingByLevel(building_type, level)
    return promiseOfBuilding(self.upgrading_building_callbacks, building_type, level)
end
function City:CheckUpgradingBuildingPormise(building)
    return checkBuilding(self.upgrading_building_callbacks, building)
end
function City:PromiseOfFinishUpgradingByLevel(building_type, level)
    return promiseOfBuilding(self.finish_upgrading_callbacks, building_type, level)
end
function City:CheckFinishUpgradingBuildingPormise(building)
    return checkBuilding(self.finish_upgrading_callbacks, building)
end
--
function City:PromiseOfRecruitSoldier(soldier_type)
    return self:GetFirstBuildingByType("barracks"):PromiseOfRecruitSoldier(soldier_type)
end
function City:PromiseOfFinishSoldier(soldier_type)
    return self:GetFirstBuildingByType("barracks"):PromiseOfFinishSoldier(soldier_type)
end
--
function City:PromiseOfTreatSoldier(soldier_type)
    return self:GetFirstBuildingByType("hospital"):PromiseOfTreatSoldier(soldier_type)
end
function City:PromiseOfFinishTreatSoldier(soldier_type)
    return self:GetFirstBuildingByType("hospital"):PromiseOfFinishTreatSoldier(soldier_type)
end
--
function City:PromiseOfFinishEquipementDragon()
    return self:GetDragonEyrie():GetDragonManager():PromiseOfFinishEquipementDragon()
end

function City:GetWatchTowerLevel()
    local watch_tower = self:GetFirstBuildingByType("watchTower")
    return watch_tower and watch_tower:GetLevel() or 0
end

function City:GeneralProductionLocalPush(productionTechnologyEvent)
    if ext and ext.localpush then
        local title = productionTechnologyEvent:GetBuffLocalizedDescComplete()
        app:GetPushManager():UpdateTechnologyPush(productionTechnologyEvent:FinishTime(),title,productionTechnologyEvent:Id())
    end
end
function City:CancelProductionLocalPush(Id)
    if ext and ext.localpush then
        app:GetPushManager():CancelTechnologyPush(Id)
    end
end





return City




