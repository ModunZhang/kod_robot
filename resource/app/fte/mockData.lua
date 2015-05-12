local DiffFunction = import("..utils.DiffFunction")
local check = import(".check")
local mark = import(".mark")
local scheduler = require(cc.PACKAGE_NAME .. ".scheduler")
local BuildingLevelUp = GameDatas.BuildingLevelUp
local HouseLevelUp = GameDatas.HouseLevelUp
local locations = GameDatas.ClientInitGame.locations
local normal = GameDatas.Soldiers.normal

local function mock(t)
    local delta = DiffFunction(DataManager:getFteData(), t)
    LuaUtils:outputTable(t)
    LuaUtils:outputTable(delta) 
    DataManager:setFteUserDeltaData(delta)
end
local function remove_global_shceduler()
    if DataManager.handle__ then
        scheduler.unscheduleGlobal(DataManager.handle__)
        DataManager.handle__ = nil
    end
end

local function get_dragon_type()
    for k,v in pairs(DataManager:getUserData().dragons) do
        if v.star > 0 then
            return k
        end
    end
    assert(false)
end



local function HateDragon()
    local dragon_str = string.format("dragons.%s", get_dragon_type())
    mock{
        {dragon_str..".hpRefreshTime", NetManager:getServerTime()},
        {dragon_str..".star", 1},
        {dragon_str..".exp", 0},
        {dragon_str..".level", 1},
        {dragon_str..".hp", 60},
    }
    if not check("HateDragon") then
        mark("HateDragon")
    end
end
local function DefenceDragon()
    local dragon_str = string.format("dragons.%s", get_dragon_type())
    mock{
        {dragon_str..".status", "defence"},
    }
    if not check("DefenceDragon") then
        mark("DefenceDragon")
    end
end



local function FinishBuildHouseAt(building_location_id, level)
    remove_global_shceduler()
    mock{
        {"houseEvents.0", json.null},
        {string.format("buildings.location_%d.houses.1.level", building_location_id), level}
    }

    local key = string.format("FinishBuildHouseAt_%d_%d", building_location_id, level)
    if not check(key) then
        mark(key)
    end
end
local function BuildHouseAt(building_location_id, house_location_id, house_type)
    local start_time = NetManager:getServerTime()
    local buildTime = HouseLevelUp[house_type][1].buildTime 
    mock{
        {
            "houseEvents.0",
            {
                id  = 1,
                buildingLocation = building_location_id,
                houseLocation = house_location_id,
                startTime = start_time,
                finishTime = start_time + buildTime * 1000
            }
        },
        {
            string.format("buildings.location_%d.houses.1", building_location_id),
            {
                type = house_type,
                level = 0,
                location = house_location_id
            }
        }
    }

    DataManager.handle__ = scheduler.performWithDelayGlobal(function()
        if DataManager:getFteData() and 
            DataManager:getFteData().houseEvents and 
            #DataManager:getFteData().houseEvents > 0 then
            FinishBuildHouseAt(building_location_id, 1)
        end
    end, buildTime)

    local key = string.format("BuildHouseAt_%d_%d", building_location_id, house_location_id)
    if not check(key) then
        mark(key)
    end
end
local function UpgradeHouseTo(building_location_id, house_location_id, house_type, level)
    local start_time = NetManager:getServerTime()
    local buildTime = HouseLevelUp[house_type][level].buildTime
    mock{
        {
            "houseEvents.0",
            {
                id = 1,
                buildingLocation = building_location_id,
                houseLocation = house_location_id,
                startTime = start_time,
                finishTime = start_time + buildTime * 1000
            }
        }
    }

    DataManager.handle__ = scheduler.performWithDelayGlobal(function()
        if DataManager:getFteData() and 
            DataManager:getFteData().houseEvents and 
            #DataManager:getFteData().houseEvents > 0 then
            FinishBuildHouseAt(building_location_id, level)
        end
    end, buildTime)

    local key = string.format("UpgradeHouseTo_%d_%d_%d", building_location_id, house_location_id, level)
    if not check(key) then
        mark(key)
    end
end



local function FinishUpgradingBuilding(type, level)
    remove_global_shceduler()
    local location_id
    for i,v in ipairs(locations) do
        if v.building_type == type then
            location_id = v.index
            break
        end
    end
    assert(location_id)
    mock{
        {
            "buildingEvents.0", json.null
        },
        {
            string.format("buildings.location_%d.level", location_id), level
        }
    }

    local key = string.format("FinishUpgradingBuilding_%s_%d", type, level)
    if not check(key) then
        mark(key)
    end
end
local function UpgradeBuildingTo(type, level)
    local location_id
    for i,v in ipairs(locations) do
        if v.building_type == type then
            location_id = v.index
            break
        end
    end
    assert(location_id)
    local start_time = NetManager:getServerTime()
    local buildTime = BuildingLevelUp[type][level].buildTime
    mock{
        {"buildingEvents.0",
            {
                id = 1,
                startTime = start_time,
                finishTime = start_time + buildTime * 1000,
                location = location_id,
            }
        }
    }

    DataManager.handle__ = scheduler.performWithDelayGlobal(function()
        if DataManager:getFteData() and
            DataManager:getFteData().buildingEvents and 
            #DataManager:getFteData().buildingEvents > 0 then
            FinishUpgradingBuilding(type, level)
        end
    end, buildTime)

    local key = string.format("UpgradeBuildingTo_%s_%d", type, level)
    if not check(key) then
        mark(key)
    end
end


local function FinishRecruitSoldier()
    if DataManager.handle_soldier__ then
        scheduler.unscheduleGlobal(DataManager.handle_soldier__)
        DataManager.handle_soldier__ = nil
    end
    local soldierEvents = DataManager:getFteData().soldierEvents
    if soldierEvents and #soldierEvents > 0 then
        mock{
            {"soldierEvents.0", json.null},
            {"soldiers.name", soldierEvents.count}
        }
    end

    local key = string.format("FinishRecruitSoldier")
    if not check(key) then
        mark(key)
    end
end

local function RecruitSoldier(type_, count)
    local recruitTime = normal[type_.."_1"].recruitTime * count
    mock{
        {
            "soldierEvents.0",
            {
                id = 1,
                name = type_,
                count = count,
                startTime = NetManager:getServerTime(),
                finishTime = NetManager:getServerTime() + recruitTime * 1000
            }
        }
    }
    DataManager.handle_soldier__ = scheduler.performWithDelayGlobal(function()
        if DataManager:getFteData() and
            DataManager:getFteData().soldierEvents and 
            #DataManager:getFteData().soldierEvents > 0 then
            FinishRecruitSoldier()
        end
        DataManager.handle_soldier__ = nil
    end, recruitTime)

    local key = string.format("RecruitSoldier_%s_%d", type_, count)
    if not check(key) then
        mark(key)
    end
end



local function GetSoldier()
    mock{
        {"soldiers.swordsman", 100},
        {"soldiers.ranger", 100}
    }

    local key = string.format("GetSoldier")
    if not check(key) then
        mark(key)
    end
end

local function ActiveVip()
    local start_time = NetManager:getServerTime()
    mock{
        {
            "vipEvents.0",
            {
                id = 1,
                startTime = start_time,
                finishTime = start_time + 24 * 60 * 60 * 1000
            }
        }
    }

    local key = string.format("ActiveVip")
    if not check(key) then
        mark(key)
    end
end



local function FightWithNpc()
    mock{
        {"pve.floors.0",
            {
                level = 1,
                fogs = "0000000000000000000000000000000000m|10W|300|700{F00yV00u|00m|10W|300|700000000000000000000000000000000000",
                objects = "[[9,12,1]]"
            }
        }
    }

    local key = string.format("FightWithNpc")
    if not check(key) then
        mark(key)
    end
end





return {
    HateDragon = HateDragon,
    DefenceDragon = DefenceDragon,
    BuildHouseAt = BuildHouseAt,
    UpgradeHouseTo = UpgradeHouseTo,
    FinishBuildHouseAt = FinishBuildHouseAt,
    UpgradeBuildingTo = UpgradeBuildingTo,
    FinishUpgradingBuilding = FinishUpgradingBuilding,
    RecruitSoldier = RecruitSoldier,
    GetSoldier = GetSoldier,
    ActiveVip = ActiveVip,
    FightWithNpc = FightWithNpc,
}



















