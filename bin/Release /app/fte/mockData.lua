local DiffFunction = import("..utils.DiffFunction")
local check = import(".check")
local mark = import(".mark")
local scheduler = require(cc.PACKAGE_NAME .. ".scheduler")
local BuildingFunction = GameDatas.BuildingFunction
local BuildingLevelUp = GameDatas.BuildingLevelUp
local HouseFunction = GameDatas.HouseFunction
local HouseLevelUp = GameDatas.HouseLevelUp
local locations = GameDatas.ClientInitGame.locations
local normal = GameDatas.Soldiers.normal
local special = GameDatas.Soldiers.special

local function mock(t)
    local delta = DiffFunction(DataManager:getFteData(), t)
    -- LuaUtils:outputTable(t)
    -- LuaUtils:outputTable(delta)
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
        ext.market_sdk.onPlayerEvent("孵化龙", "empty")
    end
end
local function DefenceDragon()
    local dragon_str = string.format("dragons.%s", get_dragon_type())
    mock{
        {dragon_str..".status", "defence"},
    }
    if not check("DefenceDragon") then
        mark("DefenceDragon")
        ext.market_sdk.onPlayerEvent("驻防龙", "empty")
    end
end



local function FinishBuildHouseAt(building_location_id, level)
    remove_global_shceduler()

    local house = DataManager:getFteData().buildings[string.format("location_%d", building_location_id)].houses[1]
    local config = HouseFunction[house.type]
    local before_power = level > 1 and config[level - 1].power or 0

    local modify = {
        {"basicInfo.power", DataManager:getFteData().basicInfo.power + config[level].power - before_power},
        {"houseEvents.0", json.null},
        {string.format("buildings.location_%d.houses.0.level", building_location_id), level}
    }
    if building_location_id == 5 and level > 1 then
        local newindex = #DataManager:getFteData().growUpTasks.cityBuild
        table.insert(
            modify, {
                string.format("growUpTasks.cityBuild.%d", newindex), {
                    id = 351,
                    index = 1,
                    name = "farmer",
                    rewarded = false
                }
            })
    end
    mock(modify)

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
            string.format("buildings.location_%d.houses.0", building_location_id),
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
        ext.market_sdk.onPlayerEvent("建造小屋:"..building_location_id.."_"..house_type, "empty")
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
    local config = BuildingFunction[type]
    local before_power = level > 1 and config[level - 1].power or 0
    
    assert(location_id)
    local modify = {
        {"basicInfo.power", DataManager:getFteData().basicInfo.power + config[level].power - before_power},
        {"buildingEvents.0", json.null},
        {string.format("buildings.location_%d.level", location_id), level}
    }
    if type == "keep" and level > 1 then
        local newindex = #DataManager:getFteData().growUpTasks.cityBuild
        table.insert(modify, {
            string.format("growUpTasks.cityBuild.%d", newindex), {
                id = level - 2,
                index = level - 1,
                name = "keep",
                rewarded = false
            }
        })
    end
    mock(modify)

    local key = string.format("FinishUpgradingBuilding_%s_%d", type, level)
    if not check(key) then
        mark(key)
        ext.market_sdk.onPlayerEvent("升级建筑完成:"..type.."_"..level, "empty")
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
                finishTime = start_time + (buildTime-5) * 1000,
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
        ext.market_sdk.onPlayerEvent("升级建筑:"..type.."_"..level, "empty")
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
        }
    end
end

local function RecruitSoldier(name, count)
    local soldier_config = special[name] or normal[name.."_1"]
    local recruitTime = 30
    mock{
        {
            "soldierEvents.0",
            {
                id = 1,
                name = name,
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

    local key = string.format("RecruitSoldier_%s", name)
    if not check(key) then
        mark(key)
        ext.market_sdk.onPlayerEvent("招募士兵:"..name, "empty")
    end
end

local function InstantRecruitSoldier(name, count)
    local config = special[name] or normal[name.."_1"]
    mock{
        {"basicInfo.power", DataManager:getFteData().basicInfo.power + config.power * count},
        {string.format("soldiers.%s", name), count},
    }

    local key = string.format("InstantRecruitSoldier_%s", name)
    if not check(key) then
        mark(key)
        ext.market_sdk.onPlayerEvent("立即招募士兵:"..name, "empty")
    end
end



local function GetSoldier()
    mock{
        {"soldiers.swordsman_1", 100},
        {"soldiers.ranger_1", 100}
    }

    local key = string.format("GetSoldier")
    if not check(key) then
        mark(key)
        ext.market_sdk.onPlayerEvent("获得士兵", "empty")
    end
end

-- local function ActiveVip()
--     local start_time = NetManager:getServerTime()
--     mock{
--         {
--             "vipEvents.0",
--             {
--                 id = 1,
--                 startTime = start_time,
--                 finishTime = start_time + 24 * 60 * 60 * 1000
--             }
--         }
--     }

--     local key = string.format("ActiveVip")
--     if not check(key) then
--         mark(key)
--         ext.market_sdk.onPlayerEvent("激活vip", key)
--     end
-- end



local function FightWithNpc(pve_name)
    local dragon_str = string.format("dragons.%s", get_dragon_type())
    if pve_name == "1_1" then
        mock{
            {"items.3", {name = "foodClass_2", count = 1}},
            {"pve.0", {sections = {3}, rewarded = {}}},
            {"pveFights.0", {sectionName = pve_name, count = 1}},
            {dragon_str..".exp", 32},
        }
    elseif pve_name == "1_2" then
        mock{
            {"items.3", {name = "foodClass_2", count = 2}},
            {"pve.0.sections.1", 3},
            {"pveFights.1", {sectionName = pve_name, count = 1}},
            {dragon_str..".exp", 70},
        }
    elseif pve_name == "1_3" then
        mock{
            {"pve.0.sections.2", 3},
            {"pveFights.2", {sectionName = pve_name, count = 1}},
            {dragon_str..".exp", 42},
            {dragon_str..".level", 2},
        }
    else
        assert(false)
    end

    if pve_name == "1_3" then
        mock{
            {"soldierMaterials.magicBox", 1},
            {"soldierMaterials.deathHand", 1},
            {"soldierMaterials.soulStone", 1},
            {"soldierMaterials.heroBones", 2},
        }
    end

    local key = string.format("FightWithNpc%s", pve_name)
    if not check(key) then
        mark(key)
        ext.market_sdk.onPlayerEvent("探索pve:"..pve_name, "empty")
    end
end


local function FinishTreatSoldier()
    if DataManager.handle_treat__ then
        scheduler.unscheduleGlobal(DataManager.handle_treat__)
        DataManager.handle_treat__ = nil
    end

    local treatSoldierEvents = DataManager:getFteData().treatSoldierEvents
    if treatSoldierEvents and #treatSoldierEvents > 0 then
        mock{
            {"treatSoldierEvents.0", json.null},
        }
    end

    local key = string.format("FinishTreatSoldier")
    if not check(key) then
        mark(key)
        ext.market_sdk.onPlayerEvent("治疗士兵完成", "empty")
    end
end


local function TreatSoldier(name, count)
    local start_time = NetManager:getServerTime()
    local treatTime = normal[name.."_1"].treatTime * count
    mock{
        {string.format("woundedSoldiers.%s", name), 0},
        {
            "treatSoldierEvents.0",
            {
                id = 1,
                soldiers = {
                    {
                        name = name,
                        count = count
                    }
                },
                startTime = start_time,
                finishTime = start_time + treatTime * 1000,
            }
        }
    }

    DataManager.handle_treat__ = scheduler.performWithDelayGlobal(function()
        if DataManager:getFteData() and
            DataManager:getFteData().treatSoldierEvents and
            #DataManager:getFteData().treatSoldierEvents > 0 then
            FinishTreatSoldier()
        end
        DataManager.handle_treat__ = nil
    end, treatTime)

    local key = string.format("TreatSoldier")
    if not check(key) then
        mark(key)
        ext.market_sdk.onPlayerEvent("治疗士兵", "empty")
    end
end

local function FinishResearch()
    if DataManager.handle_tech__ then
        scheduler.unscheduleGlobal(DataManager.handle_tech__)
        DataManager.handle_tech__ = nil
    end
    mock{
        {"productionTechEvents.0", json.null}
    }

    local key = string.format("FinishResearch")
    if not check(key) then
        mark(key)
        ext.market_sdk.onPlayerEvent("研发科技完成", "empty")
    end
end



local function Research()
    local start_time = NetManager:getServerTime()
    local researchTime = 6 * 60
    mock{
        {
            "productionTechEvents.0",
            {
                id = 1,
                startTime = start_time,
                name = "forestation",
                finishTime = start_time + researchTime * 1000
            }
        }
    }
    DataManager.handle_tech__ = scheduler.performWithDelayGlobal(function()
        if DataManager:getFteData() and
            DataManager:getFteData().productionTechEvents and
            #DataManager:getFteData().productionTechEvents > 0 then
            FinishResearch()
        end
        DataManager.handle_tech__ = nil
    end, researchTime)

    local key = string.format("Research")
    if not check(key) then
        mark(key)
        ext.market_sdk.onPlayerEvent("研发科技", "empty")
    end
end


local function CheckMaterials()
    local key = string.format("CheckMaterials")
    if not check(key) then
        mark(key)
        ext.market_sdk.onPlayerEvent("查看材料", "empty")
    end
end


local function Skip()
    local key = "BuildHouseAt_8_3"
    if not check(key) then
        mark(key)
        ext.market_sdk.onPlayerEvent("跳过引导", "empty")
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
    InstantRecruitSoldier = InstantRecruitSoldier,
    RecruitSoldier = RecruitSoldier,
    FinishRecruitSoldier = FinishRecruitSoldier,
    TreatSoldier = TreatSoldier,
    Research = Research,
    GetSoldier = GetSoldier,
    ActiveVip = ActiveVip,
    FightWithNpc = FightWithNpc,
    CheckMaterials = CheckMaterials,
    Skip = Skip,
}




























