--
-- Author: dannyhe
-- Date: 2014-08-21 20:49:46
--
--[[
    --适配相应平台的Lua接口文件

    --UITextView
        iOS模拟器和真机支持ccui.UITextView 
        函数名和参数同EditBox 构造函数不同
        player/android 暂不支持
        
        local textView = ccui.UITextView:create(cc.size(549,379),display.newScale9Sprite(""))
        textView:addTo(self):center()
        textView:setReturnType(cc.KEYBOARD_RETURNTYPE_SEND)    
        textView:setFont(UIKit:getFontFilePath(), 24)
        textView:registerScriptTextViewHandler(function(event,textView)

        end)
]]--
local PlatformAdapter = {}

function PlatformAdapter:android()
    device.getOpenUDID = ext.getOpenUDID
end


function PlatformAdapter:ios()
    device.getOpenUDID = ext.getOpenUDID
    if CONFIG_LOG_DEBUG_FILE then
        local print__ = print
         print = function ( ... )
            print__(...)
            local t = {}
            for i,v in ipairs({...}) do
                if not v then v = "nil" end
                table.insert(t,tostring(v))
            end
            ext.__logFile(table.concat(t,"\t") .. "\n")
        end
    end
    DEBUG_GET_ANIMATION_PATH = function(filePath)
        return filePath
    end

    if CONFIG_IS_DEBUG then -- debug 关闭sdk统计
        ext.market_sdk = {}
        setmetatable(ext.market_sdk,{
            __index= function(t,key)
                return function ( ... )
                    print("\nfunction: ext.market_sdk." .. key .. "\n","args: ",...)
                end
            end
        })
    end
end


function PlatformAdapter:mac()
    ccui.UITextView = {}
    setmetatable(ccui.UITextView,{
        __index= function( ... )
            assert(false,"\n--- ccui.UITextView not support for Player!\n")
        end
    })
    --search path
    --player 特殊处理
    local fileutils = cc.FileUtils:getInstance()
    fileutils:addSearchPath("dev/res/")
    fileutils:addSearchPath("dev/res/fonts/")
    fileutils:addSearchPath("dev/res/images/")
    fileutils:addSearchPath("dev/res/fonts/")
    fileutils:addSearchPath("dev/res/images/rgba444_single/")
    fileutils:addSearchPath("dev/res/images/_Compressed_mac/")
    fileutils:addSearchPath("dev/res/images/_CanCompress/")
    ext.getDeviceToken = function ()end
    ext.market_sdk = {}
    setmetatable(ext.market_sdk,{
        __index= function(t,key)
            return function ( ... )
                print("\nfunction: ext.market_sdk." .. key .. "\n","args: ",...)
            end
        end
    })
    ext.getAppVersion = function()
        return "Debug Version"
    end
    DEBUG_GET_ANIMATION_PATH = function(filePath)
        filePath = string.gsub(filePath,".pvr.ccz",".png")
        filePath = string.gsub(filePath,"animations/","animations_mac/")
        return filePath
    end
end


function PlatformAdapter:common()
    --打开文件搜索路径日志
    -- cc.FileUtils:getInstance():setPopupNotify(true)
    --拓展输入框键盘的类型
    cc.EDITBOX_INPUT_MODE_ASCII_CAPABLE = 7
    --修改Quick函数
    if CONFIG_LOG_DEBUG_FILE then
        local printError__ = printError
        printError = function(...)
            printError__(...)
            local errDesc =   debug.traceback("", 2)
            device.showAlert("☠Quick Framework错误☠",errDesc,"复制！",function()
                ext.copyText(errDesc)
            end)
        end
    end
    self:gameCenter()
end
-- 适配GameCenter Lua接口
function PlatformAdapter:gameCenter()
    if not ext.gamecenter then
        local ep_func = function(...)end
        ext.gamecenter = {
            isGameCenterEnabled = ep_func,
            authenticate = ep_func,
            showAchivevementController = ep_func,
            getPlayerNameAndId = ep_func,
            isAuthenticated = ep_func,
        }
    end
end

--------------------------------------------------------------------
if PlatformAdapter[device.platform] then
    PlatformAdapter[device.platform]()
end
PlatformAdapter:common()
