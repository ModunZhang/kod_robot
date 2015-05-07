local promise = import(".promise")
local scheduler = require(cc.PACKAGE_NAME .. ".scheduler")

local function delay_(time, func)
    local p = promise.new(func)
    scheduler.performWithDelayGlobal(function()
        p:resolve()
    end, time)
    return p
end
local function defer(func)
    return delay_(0, func)
end
local function defferPromise(p)
    defer(function() p:resolve() end)
    return p
end
local function delay(time)
    return function(obj)
        return delay_(time, function() return obj end)
    end
end
local function timeOut(time)
    local time = time or 0
    return delay_(time):next(function()
        promise.reject({code = 0, msg = time}, "timeout")
    end)
end
local function promiseWithTimeOut(p, time)
    return promise.any(p, timeOut(time))
end
local function promiseWithCatchError(p)
    return p:catch(function(err)
        dump(err)
        local content, title = err:reason()
        local dialog = UIKit:showMessageDialog(title,content,function()
            app:retryConnectServer()
        end)
    end)
end

local function promiseFilterNetError(p,need_catch)
    return p:catch(function(err)
        if err:isSyntaxError() then
            return
        end
        local content, title = err:reason()
        title = title or ""
        if not need_catch then
            if title == 'timeout' then
                content = _("请求超时")
                UIKit:showMessageDialog(title == 'timeout' and _("错误") or title, content,function()
                    if title == 'timeout' then
                        app:retryConnectServer()
                    end
                end,nil,false)
            else
                local code = content.code
                if UIKit:getErrorCodeKey(code) == "reLoginNeeded" then
                    app:retryConnectServer()
                else
                    UIKit:showMessageDialog(_("错误"), content.msg .. string.format("[%d]",code),function()
                        end,nil,false)
                end
            end
        end
        if need_catch then
            promise.reject(content, title)
        else
            return err
        end
    end)
end

local function promiseOfMoveTo(node, x, y, time, easing)
    local p = promise.new()
    transition.moveTo(node, {
        x = x, y = y, time = time or 0, easing = easing,
        onComplete = function()
            p:resolve(node)
        end
    })
    return p
end

local function promiseOfSchedule(node, time, dt, func)
    local p = promise.new()
    local t = 0
    dt = dt or 0.01
    local speed = cc.RepeatForever:create(
        transition.sequence({
            cc.DelayTime:create(dt),
            cc.CallFunc:create(function()
                t = t + dt
                if t > time then
                    func(1)
                    p:resolve()
                    node:stopAction(node.speed_action)
                else
                    if type(func) == "function" then
                        func(t / time)
                    end
                end
            end)
        })
    )
    node.speed_action = speed
    node:runAction(speed)
    return p
end

return {
    defer = defer,
    defferPromise = defferPromise,
    Delay = delay_,
    delay = delay,
    timeOut = timeOut,
    promiseWithTimeOut = promiseWithTimeOut,
    promiseWithCatchError = promiseWithCatchError,
    promiseFilterNetError = promiseFilterNetError,
    promiseOfMoveTo = promiseOfMoveTo,
    promiseOfSchedule = promiseOfSchedule,
}

















