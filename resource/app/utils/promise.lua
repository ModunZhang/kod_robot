-- error类
local err_class = {}
err_class.__index = err_class
function err_class.new(...)
    local r = {}
    setmetatable(r, err_class)
    r:ctor(...)
    return r
end
function err_class:ctor(...)
    self.errcode = {...}
end
function err_class:reason()
    return unpack(self.errcode)
end
function err_class:isSyntaxError()
    local _,code = unpack(self.errcode)
    return code == "syntaxError"
end
local function is_error(obj)
    return getmetatable(obj) == err_class
end

------
local promise = {}
promise.__index = promise
local PENDING = 1
local RESOLVED = 2
local REJECTED = 3
local empty_func = function(...) return ... end
local function is_promise(obj)
    return getmetatable(obj) == promise
end
local function pop_head(array)
    assert(type(array) == "table")
    return table.remove(array, 1)
end
local function is_complete(p)
    return #p.thens == 0
end
local function is_not_complete(p)
    return #p.thens > 0
end
local function done_promise(p)
    local result = p.result
    table.foreachi(p.dones, function(_, v) v(result) end)
    p.dones = {}
end
local function fail_promise(p)
    local result = p.result
    table.foreachi(p.fails, function(_, v) v(result) end)
    p.fails = {}
end
local function complete_and_pop_promise(p)
    if p:state() == REJECTED then
        fail_promise(p)
    else
        done_promise(p)
    end
    return pop_head(p.next_promises)
end
local function do_function_with_protect(func, param)
    local success, result
    -- if CONFIG_IS_DEBUG then
    --     success, result = true,func(param)
    -- else
        success, result = pcall(func, param)
    -- end
    if not success then
        result = not is_error(result) and err_class.new(result, "syntaxError") or result
    end
    return success, result
end
local function do_promise(p)
    local head = pop_head(p.thens)
    local success_func, failed_func = unpack(head or {})
    local success, result
    if type(success_func) == "function" then
        success, result = do_function_with_protect(success_func, p.result)
    end
    p.result = result
    return success, result, failed_func
end
local function handle_next_failed(p, err)
    -- 当前任务里面找
    local thens = p.thens
    local _, failed_func
    repeat
        local head = pop_head(thens)
        _, failed_func = unpack(head or {})
    until failed_func ~= nil or #thens == 0
    if type(failed_func) == "function" then
        local success, err_ = do_function_with_protect(failed_func, err)
        p.result = err_
        if success then
            return p
        else
            return handle_next_failed(p, err_)
        end
    end
    -- 没有找到,就应该完成这个promise并在子promise里面找
    local next_promise = complete_and_pop_promise(p)
    if next_promise == nil then
        if p.ignore_error then
            p.result = err
            return p
        end
        dump(err)
        err = err or ""
        if type(err) == "table" then
            local t = {}
            for k,v in pairs(err) do
                if type(v) == "string" then
                    table.insert(t, string.format("%s=%s", k, v))
                end
            end
            assert(false, "你应该捕获这个错误!" ..  table.concat(t,";"))
        else
            assert(false, "你应该捕获这个错误!" .. err)
        end
    else
        next_promise.state_ = REJECTED
    end
    return handle_next_failed(next_promise, err)
end
local has_a_new_promise = true
local has_no_promise = false
local function handle_result(p, success, result, failed_func)
    if success then
        if is_promise(result) then
            table.insert(result.next_promises, p)
            return has_a_new_promise, result
        end
    else
        -- 如果当前任务有错误处理函数,捕获并继续传入下一个任务进行处理
        p.state_ = REJECTED
        if not is_error(result) then
            result = err_class.new(result, "syntaxError")
        end
        if type(failed_func) == "function" then
            local success_, result_ = do_function_with_protect(failed_func, err)
            p.result = result_
            if success_ then
                return has_no_promise, p
            else
                return has_no_promise, handle_next_failed(p, result_)
            end
        else
            return has_no_promise, handle_next_failed(p, result)
        end
    end
    return has_no_promise, p
end
local function repeat_resolve(p)
    while is_not_complete(p) do
        local is_has_a_new_promise, cp = handle_result(p, do_promise(p))
        if is_has_a_new_promise and cp.state_ == PENDING then
            return
        end
        -- 当前promise改变了
        if cp ~= p then
            p = cp
        end
    end
    local state_, result_ = p:state(), p.result
    local next_promise = complete_and_pop_promise(p)
    while true do
        if not next_promise then return end

        next_promise.result = result_

        if is_not_complete(next_promise) then break end

        next_promise = complete_and_pop_promise(next_promise)
    end
    return repeat_resolve(next_promise)
end
local function catch_resolve(p, data)
    assert(p.state_ == PENDING)
    p.state_ = REJECTED
    p.result = data
    repeat_resolve(p)
    return p
end
local function failed_resolve(p, data)
    assert(p.state_ == PENDING)
    p.state_ = REJECTED
    p.result = data
    repeat_resolve(handle_next_failed(p, data))
    return p
end
local function resolve(p, data)
    assert(p.state_ == PENDING, p.state_)
    p.state_ = RESOLVED
    p.result = data
    repeat_resolve(p)
    return p
end
local function clear_promise(p)
    p.thens = {}
    p.dones = {}
    p.fails = {}
    p.next_promises = {}
end
-- 因为某种原因取消了promise对象
local function cancel_promise(p)
    clear_promise(p)
end
local function ignore_error(p)
    p.ignore_error = true
end
function promise.new(data)
    local r = {}
    setmetatable(r, promise)
    r:ctor(data)
    return r
end
function promise:ctor(resolver)
    self.ignore_error = false
    self.state_ = PENDING
    clear_promise(self)
    self:next(resolver or empty_func)
end
function promise:state()
    return self.state_
end
function promise:resolve(data)
    if is_error(data) then
        assert(false)
    end
    return resolve(self, data)
end
function promise:next(success_func, failed_func)
    if is_promise(success_func) then
        local p = success_func
        success_func = function() return p end
    end
    assert(type(success_func) == "function", "必须要有成功处理函数,如果不想要,请调用catch(func(err)end)")
    assert(self.state_ == PENDING, "暂不支持完成之后再次添加任务!")
    table.insert(self.thens, {success_func, failed_func})
    return self
end
function promise:catch(func)
    assert(type(func) == "function")
    self:next(empty_func, function(err)
        return func(err)
    end)
    return self
end
function promise:done(func)
    local func = func or empty_func
    assert(type(func) == "function", "done的函数不能为空!")
    table.insert(self.dones, func)
    return self
end
function promise:fail(func)
    assert(type(func) == "function", "fail的函数不能为空!")
    table.insert(self.fails, func)
    return self
end
function promise:always(func)
    return self:done(func):fail(func)
end
function promise.reject(...)
    error(err_class.new(...))
end
local function foreach_promise(func, ...)
    assert(type(func) == "function")
    local p = promise.new()
    local promises = {...}
    for i, v in ipairs(promises) do
        local other_promises = {}
        for _, ov in ipairs(promises) do
            if ov ~= v then
                table.insert(other_promises, ov)
            end
        end
        ignore_error(v)
        func(i, v, p, other_promises)
    end
    return p
end
function promise.all(...)
    assert(...)
    local task_count = #{...}
    local count = 0
    local results = {}
    local not_resolved = true
    return foreach_promise(function(i, v, p)
        v:always(function(result)
            if not_resolved then
                if v:state() == REJECTED then
                    not_resolved = false
                    if is_error(result) then
                        failed_resolve(p, result)
                    else
                        catch_resolve(p, result)
                    end
                else
                    results[i] = result
                    count = count + 1
                    if task_count == count then
                        p:resolve(results)
                    end
                end
            end
        end)
    end, ...)
end
function promise.any(...)
    assert(...)
    local not_resolved = true
    return foreach_promise(function(_, v, p, other_promises)
        v:always(function(result)
            if not_resolved then
                not_resolved = false
                if v:state() == REJECTED then
                    if is_error(result) then
                        failed_resolve(p, result)
                    else
                        catch_resolve(p, result)
                    end
                else
                    p:resolve(result)
                end
                for _, v in ipairs(other_promises) do
                    cancel_promise(v)
                end
            end
        end)
    end, ...)
end
function promise.isError(obj)
    return is_error(obj)
end




return promise




