_ = function(...) return ... end
cc = cc or {}
cc.PACKAGE_NAME = "app.cc"
cc.UserDefault = {
    getInstance = function()
        return {
            getStringForKey = function()
                return ""
            end,
            setStringForKey = _,
            flush = _
        }
    end
}
cc.TMXTiledMap = {
    create = function()
        return {
            getLayer = function()
                return {
                    getTileGIDAt = function()
                        return -1
                    end,
                    getLayerSize = function()
                        return {width = 1, height = 1}
                    end,
                    removeFromParent = _
                }
            end
        }
    end
}
cc.p = function(x, y)
    return {x = x, y = y}
end
display = {
    getRunningScene = function()
        return {
            WaitForNet = _,
            NoWaitForNet = _,
        }
    end,
    width = 0,
    left = 0,
    right = 0,
    top = 0,
    bottom = 0,
    height = 0,
}

local m = {
    __index = function() return function() end end
}
GameGlobalUI = {}
setmetatable(GameGlobalUI, m)

UI = {
    setLocalZOrder = function(self)
        return self
    end,
    addToCurrentScene = function(self)
        return self
    end,
    removeFromParent = function(self)
        return self
    end
}
UIKit = {
    newGameUI = function()
        return UI
    end,
    WaitForNet = function()
    end,
    NoWaitForNet = function()
    end,
    getErrorCodeData = function() return {} end,
    showMessageDialog = function ()
    end,
    createUIClass = function ()
        return {}
    end,
    showKeyMessageDialog = function() return {} end,
    closeAllUI = function() return {} end,
    showMessageDialogWithParams = function() return {} end,
}
device = { getOpenUDID = function() return GlobalDeviceId end,
    platform = "mac" }


ext.gamecenter = {
    isGameCenterEnabled = _,
}
ext.market_sdk = {
    onPlayerBuyGameItems = function ( ... )
    end,
    onPlayerUseGameItems = function ( ... )
    end
}
ext.getAppVersion = function()
    return "Debug Version"
end
ext.getDeviceLanguage = function()
    return "zh-Hans"
end
ext.getInternetConnectionStatus = function()
    return nil
end
ext.getBatteryLevel = function()
    return 1
end
ext.isLowMemoryDevice = function()
    return false
end
ext.getAppMemoryUsage = function()
    return 0
end
printLog = function ( ... )
end
printInfo = function ( ... )
end
cc.FileUtils = {
    getInstance = function()
        return {
            fullPathForFilename = function()
                return ""
            end,
            isFileExist = _,
            setStringForKey = _
        }
    end
}
cc.HelperFunc = {
    getFileData = function()
        return ""
    end,
}
-- for websocket
cc.WEBSOCKET_OPEN     = 0
cc.WEBSOCKET_MESSAGE  = 1
cc.WEBSOCKET_CLOSE    = 2
cc.WEBSOCKET_ERROR    = 3

cc.WEBSOCKET_STATE_CONNECTING = 0
cc.WEBSOCKET_STATE_OPEN       = 1
cc.WEBSOCKET_STATE_CLOSING    = 2
cc.WEBSOCKET_STATE_CLOSED     = 3

cc.XMLHTTPREQUEST_RESPONSE_STRING       = 0
cc.XMLHTTPREQUEST_RESPONSE_ARRAY_BUFFER = 1
cc.XMLHTTPREQUEST_RESPONSE_BLOB         = 2
cc.XMLHTTPREQUEST_RESPONSE_DOCUMENT     = 3
cc.XMLHTTPREQUEST_RESPONSE_JSON         = 4
--websocket end
require("config")
require("functions")
require("json")
require("app.datas.GameDatas")
local cocos_promise = require("app.utils.cocos_promise")
cocos_promise.promiseWithTimeOut = function(p) return p end
cocos_promise.promiseFilterNetError = function(p) return p end
require("app.ui.GameGlobalUIUtils")
local GameGlobalUIUtils = GameGlobalUI

function GameGlobalUIUtils:showTips()
end
function GameGlobalUIUtils:showNotice()
end


require("app.MyApp").new():run()
-- running = false
local run_count = 0
-- 随机种子设置
local d_id = string.split(device.getOpenUDID(), "_")
local number = tonumber(d_id[1]) * 10 + tonumber(d_id[2])
math.randomseed(tostring(os.time() * number):reverse():sub(1, 6))

local count_limit = 1
-- local count_limit = math.random(5,15)
function Run()
    run_count = (run_count + 1) > count_limit and 1 or (run_count + 1)
    -- print("main run id =",device.getOpenUDID(),"run_count=",run_count,"count_limit",count_limit)
    print("··running·",running)
    if running and app and run_count == 1 then
        -- if running and app then
        app.timer:OnTimer()
        app:RunAI()
    end
end


-- test websoket
-------------------------------------

-- local sendFlag,closeFlag = false,false
-- function Run()
--     if not websocket then return end
--     if(websocket:getReadyState() == cc.WEBSOCKET_STATE_OPEN and not closeFlag and sendFlag) then
--         closeFlag = true
--         websocket:close()
--     end
--     if websocket:getReadyState() == cc.WEBSOCKET_STATE_OPEN and not sendFlag then
--             sendFlag = true
--             websocket:sendString("Hello Websocket")
--     end
-- end



-- function _checkEnv()
--     print("LuaBitOp:",type(LuaBitOp))
--     print("cc2:",type(cc))
--     print("cc.WebSocket:",type(cc.WebSocket))
--     print("cc.WEBSOCKET_OPEN:",cc.WEBSOCKET_OPEN)
--     print("dhcrypt:",type(dhcrypt))
--     for k,v in pairs(dhcrypt) do
--         print(k,v)
--     end
--     for k,v in pairs(cc) do
--         print(k,v)
--     end
-- end
-- _checkEnv()

-- function onOpen()
--     print("[WebSockets]:open")
-- end

-- function onMessage(message)
--     print("[WebSockets]:onMessage",message)
-- end

-- function onClose()
--    print("[WebSockets]:onClose") 
-- end

-- function onError()
--    print("[WebSockets]:onError") 
-- end

-- function TestWS()
--     websocket = cc.WebSocket:create("ws://echo.websocket.org")
--     websocket:registerScriptHandler(onOpen, cc.WEBSOCKET_OPEN)
--     websocket:registerScriptHandler(onMessage,cc.WEBSOCKET_MESSAGE)
--     websocket:registerScriptHandler(onClose,cc.WEBSOCKET_CLOSE)
--     websocket:registerScriptHandler(onError,cc.WEBSOCKET_ERROR)
-- end
-- TestWS()