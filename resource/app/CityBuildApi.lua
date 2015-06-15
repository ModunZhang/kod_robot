--
-- Author: Kenny Dai
-- Date: 2015-05-07 20:37:42
--
local CityBuildApi = {}

local BuildingRegister = import("app.entity.BuildingRegister")
local buildings = GameDatas.Buildings.buildings

local function setRun()
    app:setRun()
end

-- 个人名字修改
function CityBuildApi:SetUserName()
    local name = "机器人"..device.getOpenUDID()
    if User:Name() ~= name then
        return NetManager:getBuyAndUseItemPromise("changePlayerName",{["changePlayerName"] = {
            ["playerName"] = name
        }})
    end
end

function CityBuildApi:UpgradingBuilding(building)
    local tile = City:GetTileWhichBuildingBelongs(building)
    if building:IsAbleToUpgrade(true) == nil then
        local finishNow = math.random(2) == 2
        if building:IsHouse() then
            local location_id = tile.location_id
            local sub_location_id = tile:GetBuildingLocation(building)
            if finishNow then
                return NetManager:getInstantUpgradeHouseByLocationPromise(location_id, sub_location_id)
            else
                return NetManager:getUpgradeHouseByLocationPromise(location_id, sub_location_id)
            end
        elseif building:GetType() == "tower" then
            if finishNow then
                return NetManager:getInstantUpgradeTowerPromise()
            else
                return NetManager:getUpgradeTowerPromise()
            end
        elseif building:GetType() == "wall" then
            if finishNow then
                return NetManager:getInstantUpgradeWallByLocationPromise()
            else
                return NetManager:getUpgradeWallByLocationPromise()
            end
        else
            local location_id = tile.location_id
            if finishNow then
                return NetManager:getInstantUpgradeBuildingByLocationPromise(location_id)
            else
                return NetManager:getUpgradeBuildingByLocationPromise(location_id)
            end
        end
    end
end

function CityBuildApi:Recommend()
    if #City:GetUpgradingBuildings() == 0 then
        return self:UpgradingBuilding(City:GetHighestBuildingByType(City:GetRecommendTask():BuildingType()))
    end
end


function CityBuildApi:UnlockBuilding()
    for i,v in ipairs(buildings) do
        if v.location<21 then
            local unlock_building = City:GetBuildingByLocationId(v.location)
            local tile = City:GetTileByLocationId(v.location)

            local b_x,b_y =tile.x,tile.y
            -- 建筑是否可解锁
            local canUnlock = City:IsTileCanbeUnlockAt(b_x,b_y)
            if canUnlock then
                return self:UpgradingBuilding(unlock_building)
            end
        end
    end
end

local house_type = {
    "dwelling",
    "woodcutter",
    "farmer",
    "quarrier",
    "miner",
    "miner",
    "miner",
    "miner",
}
function CityBuildApi:BuildHouseByType(type_)
    if City:GetLeftBuildingCountsByType(type_) > 0 then
        local need_citizen = BuildingRegister[type_].new({building_type = type_, level = 1, finishTime = 0}):GetCitizen()
        local citizen = City:GetResourceManager():GetCitizenResource():GetNoneAllocatedByTime(app.timer:GetServerTime())
        if need_citizen <= citizen then
            for i,v in ipairs(City:GetRuinsNotBeenOccupied()) do
                local tile = City:GetTileWhichBuildingBelongs(v)
                local location_id = tile.location_id
                local sub_location_id = tile:GetBuildingLocation(v)
                return NetManager:getCreateHouseByLocationPromise(location_id, sub_location_id, type_)
            end
        end
    end
end

function CityBuildApi:BuildRandomHouse()
    return self:BuildHouseByType(house_type[math.random(#house_type)]) or
        self:BuildHouseByType("dwelling")
end

function CityBuildApi:SpeedUpBuildingEvents()
    local can_upgrade = {}
    City:IteratorCanUpgradeBuildings(function (building )
        if building:UniqueUpgradingKey() then
            table.insert(can_upgrade, building)

        end
    end)
    if #can_upgrade > 0 then
        -- 加速建筑升级
        -- 随机找一个加速
        local u_building = can_upgrade[math.random(#can_upgrade)]
        local eventType = u_building:EventType()
        local eventId = u_building:UniqueUpgradingKey()
        -- 免费加速
        if u_building:IsAbleToFreeSpeedUpByTime(app.timer:GetServerTime()) and u_building:GetUpgradingLeftTimeByCurrentTime(app.timer:GetServerTime()) > 60 then
            print("免费加速",u_building:GetType())
            return NetManager:getFreeSpeedUpPromise(eventType,eventId)
        else
            -- 随机使用事件加速道具
            local speedUp_item_name = "speedup_"..math.random(8)
            print("使用"..speedUp_item_name.."加速"..u_building:GetType()..","..u_building:EventType().." ,id:",u_building:UniqueUpgradingKey())
            return NetManager:getBuyAndUseItemPromise(speedUp_item_name,{[speedUp_item_name] = {
                eventType = eventType,
                eventId = eventId
            }})
        end
    end
end

local function Recommend()
    local p = CityBuildApi:Recommend()
    if p then
        p:always(setRun)
    else
        setRun()
    end
end
local function BuildRandomHouse()
    local p = CityBuildApi:BuildRandomHouse()
    if p then
        p:always(setRun)
    else
        setRun()
    end
end
local function UnlockBuilding()
    local p = CityBuildApi:UnlockBuilding()
    if p then
        p:always(setRun)
    else
        setRun()
    end
end
local function SpeedUpBuildingEvents()
    local p = CityBuildApi:SpeedUpBuildingEvents()
    if p then
        p:always(setRun)
    else
        setRun()
    end
end

local function SetUserName()
    local p = CityBuildApi:SetUserName()
    if p then
        p:always(setRun)
    else
        setRun()
    end
end

return {
    setRun,
    SetUserName,
    BuildRandomHouse,
    UnlockBuilding,
    Recommend,
    SpeedUpBuildingEvents,
}






