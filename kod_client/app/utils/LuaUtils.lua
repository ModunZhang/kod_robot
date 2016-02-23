LuaUtils = {}


function LuaUtils:TimeCollect(func, msg)
    local t = os.clock()
    func()
    printLog("INFO", "%s", string.format("%s : eplapse time %.6f\n", msg or "time", (os.clock() - t)))
end


function LuaUtils:Warning(str)
    print(" Warning: " .. str)
end

function LuaUtils:Error(str)
    print(" Error: " .. str)
end

function LuaUtils:printTab(n)
    for i = 1, n do
        io.write('\t')
    end
end
function LuaUtils:table_size(t)
    local r = 0
    for _, _ in pairs(t) do r = r + 1 end
    return r
end

function LuaUtils:table_insert_top(dest,src)
    local temp_table = self:table_reverse(src)
    for _,v in ipairs(temp_table) do
        table.insert(dest, 1,v)
    end
end

function LuaUtils:table_empty(t)
    return not next(t)
end

function LuaUtils:printValue(v, depth)
    if type(v) == 'string' then
        io.write(string.format('%q', v))
    elseif type(v) == 'number' then
        io.write(v)
    elseif type(v) == 'boolean' then
        io.write((v and 'true') or 'false')
    elseif type(v) == 'table' then
        self:printTable(v, depth)
    elseif type(v) == 'userdata' then
        io.write("userdata")
    elseif type(v) == 'function' then
        io.write("function")
    else
        self:Warning("invalid type " .. type(v))
    end
end

function LuaUtils:printTable(t, depth)
    if (t == nil) then
        print("printTable: nil table")
        return
    end
    local depth = depth or 1
    if (depth > 9) then
        self:Warning("too many depth; ignore")
        return
    end
    io.write('{\n')
    for k, v in pairs(t) do
        if (k ~= 'superNode') then
            self:printTab(depth)
            io.write('[')
            self:printValue(k, depth + 1)
            io.write('] = ')
            self:printValue(v, depth + 1)
            io.write(',\n')
        end
    end

    self:printTab(depth - 1)
    io.write('}\n')
end

function LuaUtils:outputTable(name, t) 
    if CONFIG_LOG_DEBUG_FILE then
        io.write((type(name) == "table" and "name" or name) .. ' = ')
        self:printTable(type(name) == "table" and name or t)
    end
end


function LuaUtils:hexToRgb(hex)
    if string.len(hex) ~= 6 then
        return 0, 0, 0
    else
        red = string.sub(hex, 1, 2)
        green = string.sub(hex, 3, 4)
        blue = string.sub(hex, -2)
        red = tonumber(red, 16)
        green = tonumber(green, 16)
        blue = tonumber(blue, 16)
        return red, green, blue
    end
end

function LuaUtils:decToHex(IN)
    local B, K, OUT, I, D = 16, "0123456789ABCDEF", "", 0
    while IN > 0 do
        I = I + 1
        IN, D = math.floor(IN / B), math.fmod(IN, B) + 1
        OUT = string.sub(K, D, D) .. OUT
    end
    return OUT
end

function LuaUtils:rgbToHex(c)
    local output = decToHex(c[1]) .. decToHex(c[2]) .. decToHex(c[3])
    return output
end

function LuaUtils:getDocPathFromFilePath(filePath)
    local getPath = function(str, sep)
        sep = sep or '/'
        return str:match("(.*" .. sep .. ")")
    end
    return getPath(filePath)
end

--table

function LuaUtils:table_reverse(t)
    local r = {}
    for i=#t,1,-1 do
        table.insert(r,t[i])
    end
    return r
end

function LuaUtils:table_filter(t, func)
    local r = {}
    for k, v in pairs(t) do
        if func(k, v) then r[k] = v end
    end
    return r
end

function LuaUtils:table_filteri(t, func)
    local r = {}
    for k, v in ipairs(t) do
        if func(k, v) then table.insert(r,v) end
    end
    return r
end

function LuaUtils:table_map(t, func)
    local r = {}
    for k, v in pairs(t) do
        local nk, nv = func(k, v)
        r[nk] = nv
    end
    return r
end

function LuaUtils:table_slice(t,star_index,end_index)
    local r = {}
    for i= star_index,end_index do
        if t[i] then
            table.insert(r,t[i])
        end
    end
    return r
end

function LuaUtils:string_foreach(str,func)
    str:gsub(".", function(c)
       func(c)
    end)
end

function LuaUtils:isString(str)
    return str and type(str) == 'string'
end