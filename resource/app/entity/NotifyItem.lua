local Localize_item = import("..utils.Localize_item")
local Localize = import("..utils.Localize")
local function unique_key(item)
    return string.format("%s_%s", item.type, item.name)
end
local m = {}
m.__add = function(a, b)
    local r = {}
    for _, v in ipairs(a) do
        local item = r[unique_key(v)]
        if item then
            item.count = item.count + v.count
        else
            r[unique_key(v)] = v
        end
    end
    for _, v in ipairs(b) do
        local av = r[unique_key(v)]
        if av then
            av.count = av.count + v.count
        else
            r[unique_key(v)] = v
        end
    end
    local r1 = {}
    for _, v in pairs(r) do
        r1[#r1 + 1] = v
    end
    setmetatable(r1, getmetatable(a))
    return r1
end
m.__sub = function(a, b)
    local r = {}
    for _, v in ipairs(a) do
        local item = r[unique_key(v)]
        if item then
            item.count = item.count + v.count
        else
            r[unique_key(v)] = v
        end
    end
    for _, v in ipairs(b) do
        local av = r[unique_key(v)]
        if av then
            av.count = av.count - v.count
        end
    end
    local r1 = {}
    for _, v in pairs(r) do
        if v.count > 0 then
            r1[#r1 + 1] = v
        end
    end
    setmetatable(r1, getmetatable(a))
    return r1
end
m.__tostring = function(a)
    return table.concat(LuaUtils:table_map(a, function(k, v)
        local txt
        if v.type == "items" then
            txt = string.format("%sx%s", Localize_item.item_name[v.name], GameUtils:formatNumber(v.count))
        elseif v.type == "resources" then
            txt = string.format("%sx%s", Localize.fight_reward[v.name], GameUtils:formatNumber(v.count))
        elseif v.type == "soldierMaterials" then
            txt = string.format("%sx%s", Localize.soldier_material[v.name], GameUtils:formatNumber(v.count))
        elseif v.type == "soldiers" then
            txt = string.format("%sx%s", Localize.soldier_name[v.name], GameUtils:formatNumber(v.count))
        end
        return k, txt
    end), ", ")
end
m.__concat = function(a, b)
    return string.format("%s%s", tostring(a), tostring(b))
end
NotifyItem = {}
function NotifyItem.new(...)
    return setmetatable({...}, m)
end
return setmetatable(NotifyItem, m)










