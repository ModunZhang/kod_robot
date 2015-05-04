--
-- Author: dannyhe
-- Date: 2014-08-21 20:49:46
--
-- 适配相应平台的Lua接口
local PlatformAdapter = {}

function PlatformAdapter:android()
    --openudid
    if ext.getOpenUDID then
        device.getOpenUDID = function ()
            return ext.getOpenUDID()
        end
    end
end

--[[
    模拟器和真机支持ccui.UITextView 
    函数名和参数同EditBox 构造函数不同
    player/android 不支持
    
    local textView = ccui.UITextView:create(cc.size(549,379),display.newScale9Sprite(""))
    textView:addTo(self):center()
    textView:setReturnType(cc.KEYBOARD_RETURNTYPE_SEND)    
    textView:setFont(UIKit:getFontFilePath(), 24)
    textView:registerScriptTextViewHandler(function(event,textView)

 end)
]]--

function PlatformAdapter:ios()
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
end


function PlatformAdapter:mac()
    ccui.UITextView = {}
    setmetatable(ccui.UITextView,{
        __index= function( ... )
            assert(false,"\n--- ccui.UITextView not support for Player!\n")
        end
    })
    --search path
    local fileutils = cc.FileUtils:getInstance()
    fileutils:addSearchPath("dev/res/")
    fileutils:addSearchPath("dev/res/fonts/")
    fileutils:addSearchPath("dev/res/images/")
    fileutils:addSearchPath("dev/res/fonts/")
    fileutils:addSearchPath("dev/res/images/_Compressed/")
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
    --CCTableView
    cc.TABLEVIEW_FILL_TOPDOWN = 0
    cc.TABLEVIEW_FILL_BOTTOMUP = 1

    cc.SCROLLVIEW_SCRIPT_SCROLL = 0
    cc.SCROLLVIEW_SCRIPT_ZOOM   = 1
    cc.TABLECELL_TOUCHED        = 2
    cc.TABLECELL_HIGH_LIGHT     = 3
    cc.TABLECELL_UNHIGH_LIGHT   = 4
    cc.TABLECELL_WILL_RECYCLE   = 5
    cc.TABLECELL_SIZE_FOR_INDEX = 6
    cc.TABLECELL_SIZE_AT_INDEX  = 7
    cc.NUMBER_OF_CELLS_IN_TABLEVIEW = 8
    cc.SCROLLVIEW_BOUND_TOP = 9
    cc.SCROLLVIEW_BOUND_BOTTOM = 10

    cc.SCROLLVIEW_DIRECTION_NONE = -1
    cc.SCROLLVIEW_DIRECTION_HORIZONTAL = 0
    cc.SCROLLVIEW_DIRECTION_VERTICAL = 1
    cc.SCROLLVIEW_DIRECTION_BOTH  = 2
    --打开文件搜索路径
    -- cc.FileUtils:getInstance():setPopupNotify(true)
    local printError__ = printError
    printError = function(...)
        printError__(...)
        local errDesc =   debug.traceback("", 2)
        device.showAlert("☠Quick Framework错误☠",errDesc,"复制！",function()
            ext.copyText(errDesc)
        end)
    end
    self:gameCenter()
end

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