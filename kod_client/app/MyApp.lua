require("app.utils.LuaUtils")
require("app.utils.GameUtils")
require("app.utils.DataUtils")
require("app.service.NetManager")
require("app.service.DataManager")
require("app.utils.UtilsForEvent")
require("app.utils.UtilsForTask")
require("app.utils.UtilsForItem")
require("app.utils.UtilsForTech")
require("app.utils.UtilsForSoldier")
require("app.utils.UtilsForBuilding")
require("app.utils.UtilsForShrine")
local BuildingRegister = import("app.entity.BuildingRegister")
local promise = import("app.utils.promise")
local GameDefautlt = import("app.utils.GameDefautlt")
local ChatManager = import("app.entity.ChatManager")
local Timer = import('.utils.Timer')
local CityBuildApi = import(".CityBuildApi")
local OtherApi = import(".OtherApi")
local DragonApi = import(".DragonApi")
local DaliyApi = import(".DaliyApi")
local AllianceApi = import(".AllianceApi")
local AllianceFightApi = import(".AllianceFightApi")

local intInit = GameDatas.PlayerInitData.intInit

BUFF_META = {}
function BUFF_META.__add(a, b)
    local t1, t2
    if getmetatable(a) == BUFF_META then
        t1, t2 = a, b
    elseif getmetatable(b) == BUFF_META then
        t1, t2 = b, a
    else
        assert(false)
    end
    local t = {}
    if type(t2) == "table" then
        for k,v in pairs(t1) do
            t[k] = v
        end
        for k,v in pairs(t2) do
            t[k] = v + (t[k] or 0)
        end
    elseif type(t2) == "number" then
        for k,v in pairs(t1) do
            t[k] = v + t2
        end
    end
    return setmetatable(t, BUFF_META)
end
function BUFF_META.__sub(a, b)
    local t = {}
    for k,v in pairs(a) do
        t[k] = v - (b[k] or 0)
    end
    return setmetatable(t, BUFF_META)
end
function BUFF_META.__mul(a, b)
    local t1, t2
    if getmetatable(a) == BUFF_META then
        t1, t2 = a, b
    elseif getmetatable(b) == BUFF_META then
        t1, t2 = b, a
    else
        assert(false)
    end
    local t = {}
    if type(t2) == "table" then
        for k,v in pairs(t1) do
            t[k] = v * (t2[k] or 1)
        end
    elseif type(t2) == "number" then
        for k,v in pairs(t1) do
            t[k] = v * t2
        end
    end
    return setmetatable(t, BUFF_META)
end
local AllianceManager_ = import(".entity.AllianceManager")
Alliance_Manager = AllianceManager_.new()

_ = function(...) return ... end
local MyApp = class("MyApp")
function MyApp:GetAudioManager()
    return {PlayeEffectSoundWithKey = function ( ... )
        end}
end

function MyApp:ctor()
    NetManager:init()
    self.GameDefautlt_ = GameDefautlt.new()
    self.ChatManager_  = ChatManager.new(self:GetGameDefautlt())
    self:GetUpdateFile()
    self.timer = Timer.new()
    app = self
    app.GetPushManager = function()
        return {
            CancelAll = function() end,
            CancelBuildPush = function ( ... ) end,
            UpdateBuildPush = function ( ... ) end,
            CancelWatchTowerPush = function ( ... ) end,
            UpdateSoldierPush = function ( ... ) end,
            CancelSoldierPush = function ( ... ) end,
            UpdateTechnologyPush = function ( ... ) end,
            CancelTechnologyPush = function ( ... ) end,
            UpdateToolEquipmentPush = function ( ... ) end,
            CancelToolEquipmentPush = function ( ... ) end,
            UpdateWatchTowerPush = function ( ... ) end,
            CancelWatchTowerPush = function ( ... ) end,
        }
    end
end
function MyApp:GetGameDefautlt()
    return self.GameDefautlt_
end
function MyApp:GetChatManager()
    return self.ChatManager_
end
function MyApp:GetUpdateFile()
    local t = io.popen("curl 192.168.0.30:3000/update/res/fileList.json")
    local msg = t:read("*all")
    t:close()
    local serverFileList = json.decode(msg)

    self.client_tag = serverFileList.tag
    --注意这里debug模式和mac上再次重写了ext.getAppVersion
    ext.getAppVersion = function()
        return serverFileList.appVersion
    end
end
function MyApp:run()
    local file = io.open("log", "a+")

    if file then
        file:write("login : "..device.getOpenUDID().."\n")
        io.close(file)
    end
    NetManager:getConnectGateServerPromise():next(function()
        return NetManager:getLogicServerInfoPromise()
    end)
    :next(function()
        return NetManager:getConnectLogicServerPromise()
    end)
    :next(function()
        return NetManager:getLoginPromise(device.getOpenUDID())
    end):next(function()
        if DataManager:getUserData().basicInfo.terrain == "__NONE__" then
            local terrains = {
                "grassLand",
                "desert",
                "iceField",
            }
            return NetManager:initPlayerData(terrains[math.random(#terrains)],"en")
        end
    end):next(function()
        return NetManager:getSendGlobalMsgPromise("resources gem 99999999999")
    end):next(function()
        return NetManager:getSendGlobalMsgPromise("dragonmaterial 99999999999")
    end):next(function()
        return NetManager:getSendGlobalMsgPromise("soldiermaterial 99999999999")
    end):next(function()
        return NetManager:getSendGlobalMsgPromise("buildinglevel 1 40")
    end):next(function()
        print("登录游戏成功!")
        return NetManager:getSendGlobalMsgPromise("buildinglevel 4 40")
    end):catch(function(err)
        dump(err:reason())
        -- local content, title = err:reason()
        -- local code = content.code
        -- if content.code == 684 then
        -- NetManager:disconnect()
        -- self:run()
        -- else
        -- threadExit()
        -- end
    end)
end

running = true
function MyApp:setRun()
    running = true
end
local function setRun()
    app:setRun()
end

func_map = {
    -- 基础城建方法组
    CityBuildApi,
    -- 散乱操作方法组
    OtherApi,
    -- 联盟方法组
    AllianceApi,
    -- 龙方法组
    DragonApi,
    -- 日常科技升级，任务方法组
    DaliyApi,
    -- 联盟战方法组
    AllianceFightApi,
}
api_group_index = 1
api_index = 1
function MyApp:RunAI()
    print("RunAI robot id:", device.getOpenUDID(),running)
    if running then
        running = false
        local group = func_map[api_group_index]
        print("run func index",api_group_index,api_index)
        group[api_index]()
        if (api_index + 1) > #group then
            api_group_index = math.random(#func_map)
            api_index = 1
        else
            api_index = api_index + 1
        end
    end
end

-- 辅助方法

-- 建筑是否解锁
function MyApp:IsBuildingUnLocked(location_id)
    local tile = City:GetTileByLocationId(location_id)
    local b_x,b_y =tile.x,tile.y
    -- 建筑是否已解锁
    return City:IsUnLockedAtIndex(b_x,b_y)
end

return MyApp













