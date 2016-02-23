UtilsForItem = {}



function UtilsForItem:IsItemEventActive(userData, type_)
    for k,v in pairs(userData.itemEvents) do
        if v.type == type_ then
            local time = self:GetItemEventTime(v)
            return time > 0, time
        end
    end
    return false, 0
end

function UtilsForItem:GetItemEventTime(itemEvent)
    return math.ceil(itemEvent.finishTime/1000 - app.timer:GetServerTime())
end

local Localize_item = import(".Localize_item")
function UtilsForItem:GetItemLocalize(item_name)
    return Localize_item.item_name[item_name]
end
function UtilsForItem:GetItemDesc(item_name)
    return Localize_item.item_desc[item_name]
end
local buff     = GameDatas.Items.buff
local resource = GameDatas.Items.resource
local speedup  = GameDatas.Items.speedup
local special  = GameDatas.Items.special
function UtilsForItem:GetItemInfoByName(item_name)
    local config = buff[item_name] 
                or resource[item_name] 
                or speedup[item_name] 
                or special[item_name]
    assert(config)
    return config
end
function UtilsForItem:IsBuffItem(item_name)
    return buff[item_name] 
end
function UtilsForItem:IsResourceItem(item_name)
    return resource[item_name] 
end
function UtilsForItem:IsSpeedUpItem(item_name)
    return speedup[item_name] 
end
function UtilsForItem:IsSpecialItem(item_name)
    return special[item_name]
end
function UtilsForItem:GetBuffItemsInfo()
    local t = {}
    for _,v in pairs(buff) do
        table.insert(t, v)
    end
    return self:__order(t)
end
function UtilsForItem:GetResourcetItemsInfo()
    local t = {}
    for _,v in pairs(resource) do
        table.insert(t, v)
    end
    return self:__order(t)
end
function UtilsForItem:GetSpeedUpItemsInfo()
    local t = {}
    for _,v in pairs(speedup) do
        table.insert(t, v)
    end
    return self:__order(t)
end
function UtilsForItem:GetSpecialItemsInfo()
    local t = {}
    for _,v in pairs(special) do
        table.insert(t, v)
    end
    return self:__order(t)
end
function UtilsForItem:GetNormalItemsInfo()
    local items = {}
    for i,v in ipairs(self:GetSpecialItemsInfo()) do
        if not v.isAdvancedItem then
            table.insert(items, v)
        end
    end
    for i,v in ipairs(self:GetBuffItemsInfo()) do
        if not v.isAdvancedItem then
            table.insert(items, v)
        end
    end
    for i,v in ipairs(self:GetResourcetItemsInfo()) do
        if not v.isAdvancedItem then
            table.insert(items, v)
        end
    end
    for i,v in ipairs(self:GetSpeedUpItemsInfo()) do
        if not v.isAdvancedItem then
            table.insert(items, v)
        end
    end
    return items
end
function UtilsForItem:GetAdvanceItems()
    local item = {}
    for i,v in ipairs(self:GetSpecialItemsInfo()) do
        if v.isAdvancedItem then
            table.insert(item, v)
        end
    end
    for i,v in ipairs(self:GetBuffItemsInfo()) do
        if v.isAdvancedItem then
            table.insert(item, v)
        end
    end
    for i,v in ipairs(self:GetResourcetItemsInfo()) do
        if v.isAdvancedItem then
            table.insert(item, v)
        end
    end
    for i,v in ipairs(self:GetSpeedUpItemsInfo()) do
        if v.isAdvancedItem then
            table.insert(item, v)
        end
    end
    return item
end
function UtilsForItem:__order(items_info)
    local order_items_info = {}
    for k,v in pairs(items_info) do
        table.insert(order_items_info, v)
    end
    table.sort(order_items_info,function ( a,b )
        return a.order < b.order
    end)
    return order_items_info
end
function UtilsForItem:GetItemCount(items, name)
    for i,v in ipairs(items) do
        if v.name == name then
            return v.count
        end
    end
    return 0
end

local buffTypes = GameDatas.Items.buffTypes
function UtilsForItem:GetItemBuff(type)
    return buffTypes[type].effect1 , buffTypes[type].effect2
end


local resource_buff_key = {
    woodBonus   = {"wood"   ,"product"},
    stoneBonus  = {"stone"  ,"product"},
    ironBonus   = {"iron"   ,"product"},
    foodBonus   = {"food"   ,"product"},
    coinBonus   = {"coin"   ,"product"},
    citizenBonus= {"citizen","product"},
}
function UtilsForItem:GetAllResourceBuffData(userData)
    local all_resource_buff = {}
    for _,v in pairs(userData.itemEvents) do
        if resource_buff_key[v.type] then
            local res_type,buff_type = unpack(resource_buff_key[v.type])
            local buff_value = self:GetItemBuff(v.type)
            table.insert(all_resource_buff,{res_type,buff_type,buff_value})
        end
    end
    return all_resource_buff
end

local soldier_buff_key = {
    marchSpeedBonus = 			   "*_march",
    unitHpBonus 	= 				  "*_hp",
    infantryAtkBonus= 			"*_infantry",
    archerAtkBonus 	= 			  "*_archer",
    cavalryAtkBonus = 			 "*_cavalry",
    siegeAtkBonus 	= 			   "*_siege",
    quarterMaster 	= "*_consumeFoodPerHour",
}
function UtilsForItem:GetAllSoldierBuffData(userData)
    local all_soldier_buff = {}
    for _,v in pairs(userData.itemEvents) do
        if soldier_buff_key[v.type] then
            local effect_soldier,buff_field = unpack(string.split(soldier_buff_key[v.type],"_"))
            local buff_value = self:GetItemBuff(v.type)
            table.insert(all_soldier_buff,{effect_soldier,buff_field,buff_value})
        end
    end
    return all_soldier_buff
end

function UtilsForItem:GetAllCityBuffTypes()
    return {
        "quarterMaster",
        "fogOfTrick",
        "woodBonus",
        "stoneBonus",
        "ironBonus",
        "foodBonus",
        "coinBonus",
        "citizenBonus",
    }
end
function UtilsForItem:GetAllWarBuffTypes()
    return {
        "dragonExpBonus",
        "troopSizeBonus",
        "dragonHpBonus",
        "marchSpeedBonus",
        "unitHpBonus",
        "infantryAtkBonus",
        "archerAtkBonus",
        "cavalryAtkBonus",
        "siegeAtkBonus",
    }
end
function UtilsForItem:GetBuff(userData)
    local buff = {
        coin = 0,
        wood = 0,
        iron = 0,
        food = 0,
        stone= 0,
        wallHp = 0,
        citizen= 0,
    }
    for _,v in ipairs(self:GetAllResourceBuffData(userData)) do
        local res_type,buff_type,buff_value = unpack(v)
        if res_type then
            buff[res_type] = buff[res_type] + buff_value
        end
    end
    return setmetatable(buff, BUFF_META)
end



