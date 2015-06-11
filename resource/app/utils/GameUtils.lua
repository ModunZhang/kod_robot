GameUtils = {

    }
local string = string
local pow = math.pow
local ceil = math.ceil
local sqrt = math.sqrt
local floor = math.floor
local modf = math.modf
local pairs = pairs
local ipairs = ipairs
local tonumber = tonumber
local round = function(v)
    return floor(v + 0.5)
end
function GameUtils:formatTimeStyle1(time)
    local seconds = floor(time) % 60
    time = time / 60
    local minutes = floor(time)% 60
    time = time / 60
    local hours = floor(time)
    return string.format("%02d:%02d:%02d", hours, minutes, seconds)
end

function GameUtils:formatTimeStyle2(time)
    return os.date("%Y-%m-%d %H:%M:%S",time)
end

function GameUtils:formatTimeStyle3(time)
    return os.date("%Y/%m/%d/ %H:%M:%S",time)
end

function GameUtils:formatTimeStyle4(time)
    return os.date("%y-%m-%d %H:%M",time)
end
function GameUtils:formatTimeStyle5(time)
    time = time / 60
    local minutes = floor(time)% 60
    time = time / 60
    local hours = floor(time)
    return string.format("%02d:%02d", hours, minutes)
end

function GameUtils:formatNumber(number)
    local num = tonumber(number)
    local r = 0
    local format = "%d"
    if num >= 1000000000--[[math.pow(10,9)]] then
        r = num/1000000000--[[math.pow(10,9)]]
        local _,decimals = modf(r)
        if decimals ~= 0 then
            format = "%.2fB"
        else
            format = "%dB"
        end
    elseif num >= 1000000--[[math.pow(10,6)]] then
        r = num/1000000--[[math.pow(10,6)]]
        local _,decimals = modf(r)
        if decimals ~= 0 then
            format = "%.2fM"
        else
            format = "%dM"
        end
    elseif num >= 1000--[[math.pow(10,3)]] then
        r = num/1000--[[math.pow(10,3)]]
        local _,decimals = modf(r)
        if decimals ~= 0 then
            format = "%.2fK"
        else
            format = "%dK"
        end
    else
        r = num
    end
    return string.format(format,r)
end

function GameUtils:formatTimeAsTimeAgoStyle( time )
    local timeText = nil
    if(time <= 0) then
        timeText = _("刚刚")
    elseif(time == 1) then
        timeText = string.format(_("%d秒前"), 1)
    elseif(time < 60) then
        timeText = string.format(_("%d秒前"), time)
    elseif(time == 60) then
        timeText = string.format(_("%d分钟前"), 1)
    elseif(time < 3600) then
        time = math.ceil(time / 60)
        timeText = string.format(_("%d分钟前"), time)
    elseif(time == 3600) then
        timeText = string.format(_("%d小时前"), 1)
    elseif(time < 86400) then
        time = math.ceil(time / 3600)
        timeText = string.format(_("%d小时前"), time)
    elseif(time == 86400) then
        timeText = string.format(_("%d天前"), 1)
    else
        time = math.ceil(time / 86400)
        timeText = string.format(_("%d天前"), time)
    end

    return timeText
end

function GameUtils:getUpdatePath(  )
    return device.writablePath .. "update/" .. ext.getAppVersion() .. "/"
end

---------------------------------------------------------- Google Translator
-- text :将要翻译的文本
-- cb :回调函数,有两个参数 function(result,errText) 如果翻译成功 result将返回翻译后的结果errText为nil，如果失败result为nil，errText为错误描述
-- 设置vpn测试！
function GameUtils:Google_Translate(text,cb)
    local params = {
        client="p",
        sl="auto",
        tl=self:ConvertLocaleToGoogleCode(),
        ie="UTF-8",
        oe="UTF-8",
        q=text
    }
    local request = network.createHTTPRequest(function(event)
        local request = event.request
        local eventName = event.name
        if eventName == "completed" then
            if request:getResponseStatusCode() ~= 200 then
                cb(nil,request:getResponseString())
                return
            end
            local content = json.decode(request:getResponseData())
            local r = ""
            if content.sentences and type(content.sentences) == 'table' then
                for _,v in ipairs(content.sentences) do
                    r = r .. v.trans
                end
                print("Google Translator::::::-------------------------------------->",r)
                cb(r,nil)
            else
                cb(nil,"")
            end
        elseif eventName == "progress" then
        else
            cb(nil,eventName)
        end
    end, "http://translate.google.com/translate_a/t", "POST")
    for k,v in pairs(params) do
        local val = string.urlencode(v)
        request:addPOSTValue(k, val)
    end
    request:start()
end

-- https://sites.google.com/site/tomihasa/google-language-codes
function GameUtils:ConvertLocaleToGoogleCode()
    local locale = self:getCurrentLanguage()
    if  locale == 'en' then
        return "en"
    elseif locale == 'cn' then
        return "zh-CN"
    elseif locale == 'pt' then
        return "pt-BR"
    elseif locale == 'tw' then
        return "zh-TW"
    else
        return locale
    end
end

-----------------------
-- get method
function GameUtils:Baidu_Translate(text,cb)
    local params = {
        from="auto",
        to='zh',
        client_id='FTxAZwkrHChliZjT3g2ZYpHr',
        q=text
    }
    local str = ""
    for k,v in pairs(params) do
        local  val = string.urlencode(v)
        str = str .. k .. "=" .. val .. "&"
    end
    local request = network.createHTTPRequest(function(event)
        local request = event.request
        local eventName = event.name
        if eventName == "completed" then
            if request:getResponseStatusCode() ~= 200 then
                print("Baidu Translator::::::-------------------------------------->StatusCode error!")
                cb(nil,request:getResponseString())
                return
            end
            local content = json.decode(request:getResponseData())
            local r = ""
            if content.trans_result and type(content.trans_result) == 'table' then
                for _,v in ipairs(content.trans_result) do
                    r = r .. v.dst
                end
                print("Baidu Translator::::::-------------------------------------->",r)
                cb(r,nil)
            else
                print("Baidu Translator::::::-------------------------------------->format error!")
                cb(nil,"")
            end
        elseif eventName == "progress" then
        else
            cb(nil,eventName)
        end
    end, "http://openapi.baidu.com/public/2.0/bmt/translate?" .. str, "GET")
    request:setTimeout(10)
    request:start()
end

function GameUtils:ConvertLocaleToBaiduCode()
    --[[
    中文  zh  英语  en
    日语  jp  韩语  kor
    西班牙语    spa 法语  fra
    泰语  th  阿拉伯语    ara
    俄罗斯语    ru  葡萄牙语    pt
    粤语  yue 文言文 wyw
    白话文 zh  自动检测    auto
    德语  de  意大利语    it
    ]]--

    local localCode  = self:getCurrentLanguage()
    if localCode == 'en' then
        localCode = 'en'
    elseif localCode == 'cn' or localCode == 'tw' then
        localCode = 'zh'
    elseif localCode == 'fr' then
        localCode = 'fra'
    elseif localCode == 'es' then
        localCode = 'spa'
    elseif localCode == 'ko' then
        localCode = 'kor'
    elseif localCode == 'ja' then
        localCode = 'jp'
    elseif localCode == 'ar' then
        localCode = 'ara'
    end
    return localCode

end

-- Translate Main
function GameUtils:Translate(text,cb)
    if text == "" then
        cb(" ")
        return
    end
    local language = self:getCurrentLanguage()
    if language == 'en' or language == 'tw' then
        self:Baidu_Translate(text,cb)
    else
        if type(self.reachableGoogle)  == nil then
            if network.isHostNameReachable("www.google.com") then
                self.reachableGoogle = true
                self:Google_Translate(text,cb)
            else
                self.reachableGoogle = false
                self:Baidu_Translate(text,cb)
            end
        elseif self.reachableGoogle then
            self:Google_Translate(text,cb)
        else
            self:Baidu_Translate(text,cb)
        end
    end
end


--ver 2.2.4
--TODO:return po文件对应的语言代码！
function GameUtils:getCurrentLanguage()
    local mapping = {
        "en",
        "cn",
        "fr",
        "it",
        "de",
        "es",
        "nl", -- dutch
        "ru",
        "ko",
        "ja",
        "hu",
        "pt",
        "ar",
        "tw"
    }
    return mapping[cc.Application:getInstance():getCurrentLanguage() + 1]
end

function GameUtils:GetAppleLanguageCode()
    local code = ext.getDeviceLanguage()
    if 'zh-Hans' == code then
        return 'cn'
    elseif 'zh-Hant' == code then
        return 'tw'
    else
        return 'tw'
    end
end

function GameUtils:GetPoFileLanguageCode(language_code)
    local currentLanguage = language_code or self:getCurrentLanguage()
    if language_code == 'cn' then
        return "zh_CN",'cn'
    elseif language_code == 'tw' then
        return "zh_TW",'tw'
    else
        return "zh_TW",'tw'
    end
end

function GameUtils:Event_Handler_Func(events,add_func,edit_func,remove_func)
    local not_hanler = function(...)end
    add_func = add_func or not_hanler
    remove_func = remove_func or not_hanler
    edit_func = edit_func or not_hanler

    local added,edited,removed = {},{},{}
    for _,event in ipairs(events) do
        if event.type == 'add' then
            local result = add_func(event.data)
            if result then table.insert(added,result) end
        elseif event.type == 'edit' then
            local result = edit_func(event.data)
            if result then table.insert(edited,result) end
        elseif event.type == 'remove' then
            local result = remove_func(event.data)
            if result then  table.insert(removed,result) end
        end
    end
    return {added,edited,removed} -- each of return is a table
end


function GameUtils:pack_event_table(t)
    local ret = {}
    local added,edited,removed = unpack(t)
    if #added > 0 then ret.added = checktable(added) end
    if #edited > 0 then ret.edited = checktable(edited) end
    if #removed > 0 then ret.removed = checktable(removed) end
    return ret
end
-- DeltaData--> entity
function GameUtils:Handler_DeltaData_Func(data,add_func,edit_func,remove_func)
    local not_hanler = function(...)end
    add_func = add_func or not_hanler
    remove_func = remove_func or not_hanler
    edit_func = edit_func or not_hanler
    local added,edited,removed = {},{},{}
    for data_type,item in pairs(data) do
        if data_type == 'add' then
            for __,v in ipairs(item) do
                local result = add_func(v)
                if result then table.insert(added,result) end
            end
        elseif data_type == 'edit' then
            for __,v in ipairs(item) do
                local result = edit_func(v)
                if result then table.insert(edited,result) end
            end
        elseif data_type == 'remove' then
            for __,v in ipairs(item) do
                local result = remove_func(v)
                if result then table.insert(removed,result) end
            end
        end
    end
    return {added,edited,removed} -- each of return is a table
end


function GameUtils:parseRichText(str)
    str = string.gsub(str, "\n", "\\n")
    str = string.gsub(str, '"', "\"")
    str = string.gsub(str, "'", "\'")
    local items = {}
    local str_array = string.split(str, "{")
    for i, v in ipairs(str_array) do
        if #v > 0 then
            local inner_str_array = string.split(v, "}")
            if #inner_str_array > 1 then
                for i, v in ipairs(inner_str_array) do
                    if #v > 0 then
                        table.insert(items, v)
                        if #inner_str_array ~= i then
                            table.insert(items, "}")
                        end
                    end
                end
            else
                table.insert(items, v)
            end
        end
        if i ~= #str_array then
            table.insert(items, "{")
        end
    end
    for i, v in ipairs(items) do
        if v == "{" then
            local str_func = {}
            table.insert(str_func, v)
            local next_char = table.remove(items, i + 1)
            while next_char do
                table.insert(str_func, next_char)
                if next_char == "}" then
                    break
                end
                next_char = table.remove(items, i + 1)
            end
            table.insert(str_func, 1, "return ")
            local f, err_msg = loadstring(table.concat(str_func, ""))
            local success, result = pcall(f)
            if not success then
                print(err_msg)
            else
                items[i] = result
            end
        end
    end
    return items
end

function GameUtils:formatTimeStyleDayHour(time,min_day)
    min_day = min_day or 1
    if time > 86400*min_day then
        return string.format(_("%d天%d小时"),math.floor(time/86400),math.floor(time%86400/3600))
    else
        return GameUtils:formatTimeStyle1(time)
    end
end



return GameUtils




















