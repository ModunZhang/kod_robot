require("app.utils.LuaUtils")
require("app.utils.GameUtils")
require("app.utils.DataUtils")
require("app.service.NetManager")
require("app.service.DataManager")
local BuildingRegister = import("app.entity.BuildingRegister")
local promise = import("app.utils.promise")
local GameDefautlt = import("app.utils.GameDefautlt")
local ChatManager = import("app.entity.ChatManager")
local Timer = import('.utils.Timer')

_ = function(...) return ... end
local MyApp = class("MyApp")

function MyApp:ctor()
    NetManager:init()
    self.GameDefautlt_ = GameDefautlt.new()
    self.ChatManager_  = ChatManager.new(self:GetGameDefautlt())
    self.timer = Timer.new()
    app = self
    app.GetPushManager = function()
        return {
            CancelAll = function() end
        }
    end
end
function MyApp:GetGameDefautlt()
    return self.GameDefautlt_
end
function MyApp:GetChatManager()
    return self.ChatManager_
end

function MyApp:run()
    local file = io.open("log", "a+")
    if file then
        file:write("login : "..device.getOpenUDID().."\n")
        io.close(file)
    end
    NetManager:getConnectGateServerPromise():next(function()
        return NetManager:getLogicServerInfoPromise()
    end):next(function()
        return NetManager:getConnectLogicServerPromise()
    end):next(function()
        return NetManager:getLoginPromise(device.getOpenUDID())
    end):next(function()
        print("登录游戏成功!")
        return NetManager:getSendGlobalMsgPromise("resources gem 99999999999")
    end):catch(function(err)
        dump(err:reason())
        threadExit()
    end)
end

running = true
local function setRun()
    running = true
end
local function JoinAlliance()
    NetManager:getFetchCanDirectJoinAlliancesPromise():done(function(response)
        if not response.msg or not response.msg.allianceDatas then return end
        local id
        if response.msg.allianceDatas then
            id = response.msg.allianceDatas[math.random(#response.msg.allianceDatas)].id
        end
        local p = app:JoinAlliance(id)
        if p then
            p:always(setRun)
        else
            setRun()
        end
    end)
end
local function getQuitAlliancePromise()
    local p = app:getQuitAlliancePromise()
    if p then
        p:always(setRun)
    else
        setRun()
    end
end
local function Recommend()
    local p = app:Recommend()
    if p then
        p:always(setRun)
    else
        setRun()
    end
end
local function BuildRandomHouse()
    local p = app:BuildRandomHouse()
    if p then
        p:always(setRun)
    else
        setRun()
    end
end
local function UnlockBuilding()
    local p = app:UnlockBuilding()
    if p then
        p:always(setRun)
    else
        setRun()
    end
end
local function idle()
    setRun()
end
func_map = {
    idle,
    getQuitAlliancePromise,
    JoinAlliance,
    BuildRandomHouse,
    UnlockBuilding,
    Recommend,
}
api_index = 1
function MyApp:RunAI()
    print("RunAI robot id:", device.getOpenUDID())
    running = false
    func_map[api_index]()
    api_index = (api_index + 1) > #func_map and 1 or (api_index + 1)
end


function MyApp:Recommend()
    if #City:GetUpgradingBuildings() == 0 then
        return self:UpgradingBuilding(City:GetHighestBuildingByType(City:GetRecommendTask():BuildingType()))
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
function MyApp:JoinAlliance(id)
    if not id then return end
    if Alliance_Manager:GetMyAlliance():IsDefault() then
        return NetManager:getJoinAllianceDirectlyPromise(id)
    end
end
function MyApp:getQuitAlliancePromise()
    if not Alliance_Manager:GetMyAlliance():IsDefault() and
        Alliance_Manager:GetMyAlliance():Status() ~= "prepare" and
        Alliance_Manager:GetMyAlliance():Status() ~= "fight" then
        return NetManager:getQuitAlliancePromise()
    end
end


function MyApp:UnlockBuilding()
    for i,v in ipairs(GameDatas.Buildings.buildings) do
        if v.location<21 then
            local unlock_building = City:GetBuildingByLocationId(v.location)
            local tile = City:GetTileByLocationId(v.location)

            local b_x,b_y =tile.x,tile.y
            -- 建筑是否可解锁
            local canUnlock = City:IsTileCanbeUnlockAt(b_x,b_y)
            if canUnlock then
                return app:UpgradingBuilding(unlock_building)
            end
        end
    end
end

function MyApp:UpgradingBuilding(building)
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

function MyApp:BuildRandomHouse()
    return self:BuildHouseByType(house_type[math.random(#house_type)]) or
        self:BuildHouseByType("dwelling")
end

function MyApp:BuildHouseByType(type_)
    if City:GetLeftBuildingCountsByType(type_) > 0 then
        local need_citizen = BuildingRegister[type_].new({building_type = type_, level = 1, finishTime = 0}):GetCitizen()
        local citizen = City:GetResourceManager():GetPopulationResource():GetNoneAllocatedByTime(self.timer:GetServerTime())
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





return MyApp
























