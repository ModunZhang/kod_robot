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
    end
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
    getErrorCodeData = function() return {} end
}

device = { getOpenUDID = function() return GlobalDeviceId end,
platform = "mac" }


ext.gamecenter = {
        isGameCenterEnabled = _,
    }




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
function Run()
    if running and app then
        app.timer:OnTimer()
        app:RunAI()
    end
end












