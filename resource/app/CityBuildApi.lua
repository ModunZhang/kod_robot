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
    local location_id = tile.location_id
    if building:IsAbleToUpgrade(true) == nil then
        if building:IsHouse() then
            local sub_location_id = tile:GetBuildingLocation(building)
            return NetManager:getInstantUpgradeHouseByLocationPromise(location_id, sub_location_id)
        elseif building:GetType() == "tower" then
            return NetManager:getInstantUpgradeTowerPromise()
        elseif building:GetType() == "wall" then
            return NetManager:getInstantUpgradeWallByLocationPromise()
        else
            return NetManager:getInstantUpgradeBuildingByLocationPromise(location_id)
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
        local citizen = City:GetResourceManager():GetPopulationResource():GetNoneAllocatedByTime(app.timer:GetServerTime())
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
}


