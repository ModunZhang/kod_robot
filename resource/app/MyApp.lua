require("app.utils.LuaUtils")
require("app.utils.GameUtils")
require("app.utils.DataUtils")
require("app.service.NetManager")
require("app.service.DataManager")
local BuildingRegister = import("app.entity.BuildingRegister")
local Flag = import("app.entity.Flag")
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
    end):next(function()
        print("登录游戏成功!")
        return NetManager:getSendGlobalMsgPromise("buildinglevel 1 40")
    end):catch(function(err)
        dump(err:reason())
        threadExit()
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
    print("RunAI robot id:", device.getOpenUDID())
    if running then
        running = false
        local group = func_map[api_group_index]
        group[api_index]()
        print("run func index",api_group_index,api_index)
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