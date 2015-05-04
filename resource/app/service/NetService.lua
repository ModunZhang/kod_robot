local NetService = {}
local cocos_promise = import("..utils.cocos_promise")
NetService.NET_STATE = {DISCONNECT = -1 , CONNECT = 0}
function NetService:init(  )
    self.m_pomelo = CCPomelo:getInstance()
    self.m_deltatime = 0
    self.m_urlcode = import("app.utils.urlcode")
    self.net_state = self.NET_STATE.DISCONNECT
end

function NetService:getNetState()
    return self.net_state
end

function NetService:isConnected()
    return self.net_state == self.NET_STATE.CONNECT
end

function NetService:isDisconnected()
    return self.net_state == self.NET_STATE.DISCONNECT
end

function NetService:connect(host, port, cb)
    self.m_pomelo:asyncConnect(host, port, function ( success ) 
        if success then 
            self.net_state = self.NET_STATE.CONNECT
        else
            self.net_state = self.NET_STATE.DISCONNECT
        end
        cb(success)
    end)
end

function NetService:disconnect( )
    if self.net_state == self.NET_STATE.DISCONNECT then return end
    self.m_pomelo:cleanup() -- clean the callback in pomelo thread
    self.m_pomelo:stop()
    self.net_state = self.NET_STATE.DISCONNECT
end


function NetService:getServerTime()
    return ext.now() + self.m_deltatime
end

function NetService:setDeltatime(deltatime)
    self.m_deltatime = deltatime
end

function NetService:request(route, lmsg, cb)
    if self.net_state == self.NET_STATE.DISCONNECT then 
        cocos_promise.defer(function()
            cb(false,{message = _("连接服务器失败,请检测你的网络环境!"),code = 0}) 
        end)
        return 
    end
    lmsg = lmsg or {}
    lmsg.__time__ = ext.now() + self.m_deltatime
    self.m_pomelo:request(route, json.encode(lmsg), function ( success, jmsg )
            if not success then  self.net_state = self.NET_STATE.DISCONNECT end 
            if jmsg then
                jmsg = json.decode(jmsg)
            else
               jmsg = nil 
            end
            cb(success, jmsg)
    end)
end

function NetService:notify( route, lmsg, cb )
    if self.net_state == self.NET_STATE.DISCONNECT then 
        cocos_promise.defer(function()
            cb(false,{message = _("连接服务器失败,请检测你的网络环境!"),code = 0}) 
        end)
    return end
    lmsg = lmsg or {}
    lmsg.__time__ = ext.now() + self.m_deltatime
    self.m_pomelo:notify(route, json.encode(lmsg), function ( success )
        if not success then  self.net_state = self.NET_STATE.DISCONNECT end 
        cb(success)
    end)
end

function NetService:addListener( event, cb )
    self.m_pomelo:addListener(event, function ( success, jmsg )
        cb(success, jmsg and json.decode(jmsg) or nil)
    end)
end

function NetService:removeListener( event )
    self.m_pomelo:removeListener(event)
end

function NetService:get(url, args, cb, progressCb)
    local urlString = url
    if param then
        urlString = urlString .. "?" .. self.m_urlcode.encodetable(args)
    end

    local request = network.createHTTPRequest(function(event)
        local request = event.request
        local eventName = event.name

        if eventName == "completed" then
            cb(true, request:getResponseStatusCode(), request:getResponseData())
        elseif eventName == "cancelled" then

        elseif eventName == "failed" then
            cb(false, request:getErrorCode(), request:getErrorMessage())
        elseif eventName == "inprogress" then
            local totalLength = event.dltotal
            local currentLength = event.dlnow
            if progressCb then progressCb(totalLength, currentLength) end
        end
    end, urlString)

    request:setTimeout(180) -- 3 min
    request:start()

    return request
end

function NetService:cancelGet(request)
    request:cancel()
end

function NetService:formatTimeAsTimeAgoStyleByServerTime( time )
    time =  math.floor(math.abs(self:getServerTime() - time) / 1000)
    return GameUtils:formatTimeAsTimeAgoStyle(time)
end

return NetService

