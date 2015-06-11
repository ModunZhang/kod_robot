local unpack = unpack
local ipairs = ipairs
local insert = table.insert
local tonumber = tonumber
local split = string.split
local null = json.null
return function(base, delta)
    local edit = {}
    for _,v in ipairs(delta) do
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
                        else
                            tmp.add = tmp.add or {}
                            insert(tmp.add, value)
                            curRoot[k] = value
                        end
                    else
                        tmp[k] = value
                        curRoot[k] = value
                    end
                end
            end
        end
    end
    return edit
end