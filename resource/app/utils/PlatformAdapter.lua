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
-- 更新CONFIG_IS_DEBUG变量(version:1.1.1)
if type(ext.isAppAdHoc) == 'function' and type(ext.isAppAdHoc()) == 'boolean' then
    CONFIG_IS_DEBUG = ext.isAppAdHoc()
end
print("- CONFIG_IS_DEBUG :",CONFIG_IS_DEBUG)
function PlatformAdapter:android()
    device.getOpenUDID = ext.getOpenUDID
    
    DEBUG_GET_ANIMATION_PATH = function(filePath)
        filePath = string.gsub(filePath,".pvr.ccz",".png")
        return filePath
    end

    if CONFIG_LOG_DEBUG_FILE then
        local print__ = print
        print = function ( ... )
            print__(...)
            local t = {}
            for i,v in ipairs({...}) do
                if type(v) == 'nil' then v = "nil" end
                if type(v) == 'userdata' then v = "userdata" end
                table.insert(t,tostring(v))
            end
            ext.__logFile(table.concat(t,"\t") .. "\n")
        end
    end

    local fileutils = cc.FileUtils:getInstance()
    fileutils:addSearchPath("res/animations")
end


function PlatformAdapter:ios()
    device.getOpenUDID = ext.getOpenUDID
    if CONFIG_LOG_DEBUG_FILE then
        local print__ = print
         print = function ( ... )
            print__(...)
            local t = {}
            for i,v in ipairs({...}) do
                if type(v) == 'nil' then v = "nil" end
                if type(v) == 'userdata' then v = "userdata" end
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


function PlatformAdapter:winrt()
    device.getOpenUDID = ext.getOpenUDID
   
    audio = require("app.utils.audio-WP")

    DEBUG_GET_ANIMATION_PATH = function(filePath)
        filePath = string.gsub(filePath,".pvr.ccz",".png")
        return filePath
    end

    if true then -- 暂时未实现
        ext.market_sdk = {}
        setmetatable(ext.market_sdk,{
            __index= function(t,key)
                return function ( ... )
                    print("\nfunction: ext.market_sdk." .. key .. "\n","args: ",...)
                end
            end
        })
    end
    -- some functions
    device.openURL = ext.openURL

    -- device.showAlert(title, message, buttonLabels, listener)
    device.showAlert = function( title, message, buttonLabels, listener )
        ext.showAlert(title or "",message or "",buttonLabels[1] or "",listener)
    end

    if CONFIG_LOG_DEBUG_FILE then
        local print__ = print
        print = function ( ... )
            print__(...)
            local t = {}
            for i,v in ipairs({...}) do
                if type(v) == 'nil' then v = "nil" end
                if type(v) == 'userdata' then v = "userdata" end
                table.insert(t,tostring(v))
            end
            ext.__logFile(table.concat(t,"\t") .. "\n")
        end
    end

    ext.getDeviceLanguage = function()
        return cc.Application:getInstance():getCurrentLanguageCode()
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

    DEBUG_GET_ANIMATION_PATH = function(filePath)
        filePath = string.gsub(filePath,".pvr.ccz",".png")
        filePath = string.gsub(filePath,"animations/","animations_mac/")
        return filePath
    end



    local path = device.writablePath.."tmp"
    local function ensureTmpDir()
        os.execute(string.format('\nif [ ! -d "%s" ]; then\nmkdir %s\nfi\n', path, path))
    end
    local function getPid()
        os.execute(string.format('echo $PPID > %s', path.."/p.d"))
        local f = io.open(path.."/p.d", "r")
        if not f then return {} end
        local pids = f:read("*all")
        f:close()
        os.execute(string.format('rm -f %s', path.."/p.d"))
        local r = {}
        for i,v in ipairs(string.split(pids, "\n")) do
            if #string.trim(v) > 0 then
                table.insert(r, tonumber(v))
            end
        end
        return r[1]
    end
    local function getKodPids()
        os.execute(string.format("ps -e|grep player3|grep kod|grep -v 'grep'|awk '{print $1}' > %s", path.."/player3.d"))
        local f = io.open(path.."/player3.d", "r")
        if not f then return {} end
        local pids = f:read("*all")
        f:close()
        os.execute(string.format('rm -f %s', path.."/player3.d"))
        local r = {}
        for i,v in ipairs(string.split(pids, "\n")) do
            if #string.trim(v) > 0 then
                r[tonumber(v)] = true
            end
        end
        return r
    end
    local function getPidMap()
        os.execute(string.format("touch %s", path.."/map.d"))
        local f = io.open(path.."/map.d", "rw+")
        local pid_map = f:read("*all")
        local r = {}
        for i,v in ipairs(string.split(pid_map, "\n")) do
            if #string.trim(v) > 0  then
                local spid,sindex = unpack(string.split(string.trim(v), ","))
                r[tonumber(spid)] = tonumber(sindex)
            end
        end
        f:close()
        return r
    end
    local function sourcePidMap(map)
        os.execute(string.format("touch %s", path.."/map.d"))
        local f = io.open(path.."/map.d", "w")
        for k,v in pairs(map) do
            f:write(string.format("%s,%s\n", k,v))
        end
        f:close()
    end


    ensureTmpDir()
    local kod_pids_map = getKodPids()
    -- dump(kod_pids_map)
    local run_pids_map = getPidMap()
    -- dump(run_pids_map)
    local indexes = {}
    for k,v in pairs(run_pids_map) do
        if not kod_pids_map[k] then
            run_pids_map[k] = nil
        else
            table.insert(indexes, v)
        end
    end
    table.sort(indexes, function(a,b) return a < b end)
    -- dump(indexes)
    local pid_array = {}
    for i,v in ipairs(indexes) do
        pid_array[v] = true
    end
    local pid = getPid()
    run_pids_map[pid] = #pid_array + 1
    -- dump(run_pids_map)
    sourcePidMap(run_pids_map)


    local getOpenUDID = device.getOpenUDID
    device.getOpenUDID = function()
        return getOpenUDID().."_"..run_pids_map[pid]
        -- return "0a0608b995423eec21bc4d6e00e0467404a69dfb"
    end
end

function PlatformAdapter:windows()
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
    ext.getDeviceLanguage = function()
        return "zh-Hans"
    end
    ext.getInternetConnectionStatus = function()
        return nil
    end
    ext.getBatteryLevel = function()
        return 1
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
            if device.platform ~= 'winrt' then
                local errDesc =   debug.traceback("", 2)
                device.showAlert("☠Quick Framework错误☠",errDesc,{"复制！"},function()
                    ext.copyText(errDesc)
                end)
            end
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
