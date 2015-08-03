_ = function(...) return ... end
cc = {}
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
printLog = function ( ... )
end
printInfo = function ( ... )
end

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



require("app.MyApp").new():run()
running = false
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

    if running and app and run_count == 1 then
        -- if running and app then
        app.timer:OnTimer()
        app:RunAI()
    end
end















