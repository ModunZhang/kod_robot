local unpack = unpack
local ipairs = ipairs
local insert = table.insert
local tonumber = tonumber
local split = string.split
local find = string.find
local format = string.format
local gsub = string.gsub
local null = json.null

local deltameta = {}
deltameta.__call = function(root, indexstr, value)
    for i,key in ipairs(split(indexstr, ".")) do
        root = root[key]
        if not root then
            return false
        end
    end
    if value then
        return root == value
    end
    return true, root
end


return function(base, delta)
    setmetatable(base, deltameta)
    
    local fixDelta = {}
    for i,v in ipairs(delta) do
        local origin_key,value = unpack(v)
        if type(value) == "table" then
            local ok,origin_value = base(origin_key)
            if ok and origin_value ~= json.null then
                if #origin_value > 0 and #value > 0 then
                    for _,_ in ipairs(origin_value) do
                        table.insert(fixDelta, {string.format("%s.0", origin_key), json.null})
                    end
                    for i,v in ipairs(value) do
                        table.insert(fixDelta, {string.format("%s.%d", origin_key, i - 1), v})
                    end
                elseif #origin_value > 0 and #value == 0 then
                    for _,_ in ipairs(origin_value) do
                        table.insert(fixDelta, {string.format("%s.0", origin_key), json.null})
                    end
                elseif #origin_value == 0 and #value > 0 then
                    for i,v in ipairs(value) do
                        table.insert(fixDelta, {string.format("%s.%d", origin_key, i - 1), v})
                    end
                else
                    table.insert(fixDelta, v)
                end
            else
                table.insert(fixDelta, v)
            end
        else
            table.insert(fixDelta, v)
        end
    end

    -- LuaUtils:outputTable("fixDelta", fixDelta)

    local edit = {}
    for _,v in ipairs(fixDelta) do
        if type(v) == "string" and GameUtils then
            GameUtils:UploadErrors(v)
        end
        local origin_key,value = unpack(v)
        local is_json_null = value == null
        local keys = split(origin_key, ".")
        if #keys == 1 then
            local k = unpack(keys)
            k = tonumber(k) or k
            if type(k) == "number" then -- 索引更新
                k = k + 1
                if is_json_null then            -- 认为是删除
                    edit[k].remove = edit[k].remove or {}
                    insert(edit[k].remove, base[k])
                elseif base[k] then         -- 认为更新
                    edit[k].edit = edit[k].edit or {}
                    insert(edit[k].edit, value)
                else                            -- 认为添加
                    edit[k].add = edit[k].add or {}
                    insert(edit[k].add, value)
                end
            elseif base[k] then
                edit[k] = value
            end
            if base[k] then
                base[k] = value
            end
        else
            local tmp = edit
            local curRoot = base
            local len = #keys
            for i = 1,len do
                local v = keys[i]
                local k = tonumber(v) or v
                if type(k) == "number" then k = k + 1 end
                local parent_root = tmp
                if i ~= len then
                    if type(k) == "number" then
                        tmp.edit = tmp.edit or {}
                        insert(tmp.edit, curRoot[k])
                    elseif not curRoot[k] then
                        break
                    end
                    curRoot[k] = curRoot[k] or {}
                    curRoot = curRoot[k]
                    tmp[k] = tmp[k] or {}
                    tmp = tmp[k]
                else
                    if type(k) == "number" then
                        if is_json_null then
                            tmp.remove = tmp.remove or {}
                            insert(tmp.remove, curRoot[k])
                            table.remove(curRoot, k)
                        elseif curRoot[k] then
                            tmp.edit = tmp.edit or {}
                            insert(tmp.edit, value)
                            curRoot[k] = value
                            tmp[k] = value
                        else
                            tmp.add = tmp.add or {}
                            insert(tmp.add, value)
                            curRoot[k] = value
                            tmp[k] = value
                        end
                    else
                        tmp[k] = value
                        curRoot[k] = value
                    end
                end
            end
        end
    end
    return setmetatable(edit, deltameta)
end







