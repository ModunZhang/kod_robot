--
-- Author: Kenny Dai
-- Date: 2015-01-22 11:58:43
--
local Enum = import("..utils.Enum")
local MultiObserver = import(".MultiObserver")
local Item = import(".Item")
local ItemEvent = import(".ItemEvent")
local ItemManager = class("ItemManager", MultiObserver)
local buffTypes = GameDatas.Items.buffTypes
local ResourceManager = import(".ResourceManager")
ItemManager.LISTEN_TYPE = Enum("ITEM_CHANGED","OnItemEventTimer","ITEM_EVENT_CHANGED")

function ItemManager:ctor()
    ItemManager.super.ctor(self)
    self.items = {}
    self.items_buff = {}
    self.items_resource = {}
    self.items_special = {}
    self.items_speedUp = {}
    self.itemEvents = {}
    self:InitAllItems()
end
-- 初始化所有道具，数量 0
function ItemManager:InitAllItems()
    for k,v in pairs(GameDatas.Items) do
        if k ~= "buffTypes" then
            for item_name,item in pairs(v) do
                local item = Item.new()
                item:UpdateData(
                    {
                        name = item_name,
                        count = 0
                    }
                )
                self:InsertItem(item)
            end
        end
    end
end
function ItemManager:OnUserDataChanged(user_data,current_time,deltaData)
    local is_fully_update = deltaData == nil
    if is_fully_update then
        self:OnItemsChanged(user_data.items)
        self:OnItemEventsChanged(user_data.itemEvents)
    end

    local is_delta_update = not is_fully_update and deltaData.items ~= nil
    if is_delta_update then
        self:__OnItemsChanged(deltaData.items)
    end

    is_delta_update = not is_fully_update and deltaData.itemEvents ~= nil
    if is_delta_update then
        self:__OnItemEventsChanged(deltaData.itemEvents)
    end
end
function ItemManager:OnItemsChanged(items)
    if items then
        for i,v in ipairs(items) do
            local item = self:GetItemByName(v.name)
            item:SetCount(v.count)
            self:InsertItem(item)
        end
    end
end
function ItemManager:__OnItemsChanged(__items)
    if __items then
        local added,edited,removed = {},{},{}
        local changed_map = {added,edited,removed}
        local add = __items.add
        local edit = __items.edit
        local remove = __items.remove
        if add then
            for k,data in pairs(add) do
                -- add
                local item = self:GetItemByName(data.name)
                item:SetCount(data.count)
                self:InsertItem(item)
                table.insert(added, item)
            end
        end
        if edit then
            for k,data in pairs(edit) do
                -- eidt 更新
                local item = self:GetItemByName(data.name)
                item:SetCount(data.count)
                self:InsertItem(item)
                table.insert(edited, item)
            end
        end
        if remove then
            for k,data in pairs(remove) do
                -- remove
                local item = self:GetItemByName(data.name)
                self:RemoveItem(item)
                table.insert(removed, item)
            end
        end

        self:NotifyListeneOnType(ItemManager.LISTEN_TYPE.ITEM_CHANGED, function(listener)
            listener:OnItemsChanged(changed_map)
        end)
    end
end
function ItemManager:OnItemEventsChanged( itemEvents )
    if not itemEvents then return end
    for i,v in ipairs(itemEvents) do
        local event = ItemEvent.new()
        event:UpdateData(v)
        self.itemEvents[v.type] = event
        event:AddObserver(self)
    end
end
function ItemManager:__OnItemEventsChanged( __itemEvents )
    if not __itemEvents then return end
    local added,edited,removed = {},{},{}
    local changed_map = {added,edited,removed}
    local add = __itemEvents.add
    local edit = __itemEvents.edit
    local remove = __itemEvents.remove
    if add then
        for k,event_data in pairs(add) do
            local itemEvent = ItemEvent.new()
            itemEvent:UpdateData(event_data)
            self.itemEvents[itemEvent:Type()] = itemEvent
            itemEvent:AddObserver(self)
            table.insert(added, itemEvent)
        end
    end
    if edit then
        for k,event_data in pairs(edit) do
            local itemEvent = self.itemEvents[event_data.type]
            itemEvent:UpdateData(event_data)
            table.insert(edited, itemEvent)
        end
    end
    if remove then
        for k,event_data in pairs(remove) do
            local itemEvent = self.itemEvents[event_data.type]
            itemEvent:Reset()
            self.itemEvents[event_data.type] = nil
            itemEvent = ItemEvent.new()
            itemEvent:UpdateData(event_data)
            table.insert(removed, itemEvent)
        end
    end

    self:NotifyListeneOnType(ItemManager.LISTEN_TYPE.ITEM_EVENT_CHANGED, function(listener)
        listener:OnItemEventChanged(changed_map)
    end)
end
function ItemManager:OnTimer(current_time)
    self:IteratorItmeEvents(function(itemEvent)
        itemEvent:OnTimer(current_time)
    end)
end
function ItemManager:IteratorItmeEvents(func)
    for _,itemEvent in pairs(self.itemEvents) do
        func(itemEvent)
    end
end
function ItemManager:OnItemEventTimer(itemEvent)
    self:NotifyListeneOnType(ItemManager.LISTEN_TYPE.OnItemEventTimer,function(listener)
        listener.OnItemEventTimer(listener,itemEvent)
    end)
end
function ItemManager:GetItemEventByType( type )
    return self.itemEvents[type]
end
function ItemManager:IsBuffActived( type )
    return tolua.type(self.itemEvents[type]) ~= "nil"
end
function ItemManager:GetBuffEffect( type )
    return buffTypes[type].effect1 , buffTypes[type].effect2
end
function ItemManager:GetAllResourceTypes()
    local RESOURCE_TYPE = ResourceManager.RESOURCE_TYPE
    local RESOURCE_BUFF_TYPE = ResourceManager.RESOURCE_BUFF_TYPE

    local buff_map =  {
        woodBonus = {RESOURCE_TYPE.WOOD,RESOURCE_BUFF_TYPE.PRODUCT},
        stoneBonus = {RESOURCE_TYPE.STONE,RESOURCE_BUFF_TYPE.PRODUCT},
        ironBonus = {RESOURCE_TYPE.IRON,RESOURCE_BUFF_TYPE.PRODUCT},
        foodBonus = {RESOURCE_TYPE.FOOD,RESOURCE_BUFF_TYPE.PRODUCT},
        coinBonus = {RESOURCE_TYPE.COIN,RESOURCE_BUFF_TYPE.PRODUCT},
        citizenBonus = {RESOURCE_TYPE.CITIZEN,RESOURCE_BUFF_TYPE.PRODUCT},
    }
    return buff_map
end
function ItemManager:GetAllResourceBuffData()
    local all_resource_buff = {}
    local resource_buff_key = self:GetAllResourceTypes()
    self:IteratorItmeEvents(function(event)
        if resource_buff_key[event:Type()] then
            local resource_type,buff_type = unpack(resource_buff_key[event:Type()])
            local buff_value = self:GetBuffEffect(event:Type())
            table.insert(all_resource_buff,{resource_type,buff_type,buff_value})
        end
    end)
    return all_resource_buff
end

function ItemManager:GetAllSoldierBuffTypes()
    --标识为 “生效兵种_属性” 支持通配符*
    local buff_map = {
        marchSpeedBonus = "*_march",
        unitHpBonus = "*_hp",
        infantryAtkBonus = "*_infantry",
        archerAtkBonus = "*_archer",
        cavalryAtkBonus = "*_cavalry",
        siegeAtkBonus = "*_siege",
        quarterMaster = "*_consumeFoodPerHour"
    }
    return buff_map
end

function ItemManager:GetAllSoldierBuffData()
    local all_soldier_buff = {}
    local soldier_buff_key = self:GetAllSoldierBuffTypes()
    self:IteratorItmeEvents(function(event)
        if soldier_buff_key[event:Type()] then
            local effect_soldier,buff_field = unpack(string.split(soldier_buff_key[event:Type()],"_"))
            local buff_value = self:GetBuffEffect(event:Type())
            table.insert(all_soldier_buff,{effect_soldier,buff_field,buff_value})
        end
    end)
    return all_soldier_buff
end

function ItemManager:GetAllCityBuffTypes()
    return {
        "masterOfDefender",
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
function ItemManager:GetAllWarBuffTypes()
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
-- 按照道具类型添加到对应table,并加入总表
function ItemManager:InsertItem(item)
    self:GetCategoryItems(item)[item:Name()] = item
    self.items[item:Name()] = item
end
function ItemManager:RemoveItem(item)
    self:GetCategoryItems(item)[item:Name()]:SetCount(0)
    self.items[item:Name()]:SetCount(0)
end
function ItemManager:GetCategoryItems(item)
    if item:Category() == Item.CATEGORY.BUFF then
        return self.items_buff
    elseif item:Category() == Item.CATEGORY.RESOURCE then
        return self.items_resource
    elseif item:Category() == Item.CATEGORY.SPECIAL then
        return self.items_special
    elseif item:Category() == Item.CATEGORY.SPEEDUP then
        return self.items_speedUp
    end
end
function ItemManager:GetItems()
    return self.items
end
function ItemManager:GetItemByName(name)
    return self.items[name]
end
function ItemManager:GetSpecialItems()
    return self:__order(self.items_special)
end
function ItemManager:GetBuffItems()
    return self:__order(self.items_buff)

end
function ItemManager:GetResourcetItems()
    return self:__order(self.items_resource)
end
function ItemManager:GetSpeedUpItems()
    return self:__order(self.items_speedUp)
end

function ItemManager:__order(items)
    local order_items = {}
    for k,v in pairs(items) do
        table.insert(order_items, v)
    end
    table.sort(order_items,function ( a,b )
        return a:Order() < b:Order()
    end)
    return order_items
end

function ItemManager:GetSameTypeItems(item)
    local same_items = {}
    local find_area = self:GetCategoryItems(item)
    local area_type = string.split(item:Name(),"_")
    if #area_type == 2 then
        for i=1,math.huge do
            local same_item = find_area[area_type[1].."_"..i]
            if same_item then
                if same_item:IsSell()then
                    table.insert(same_items, same_item)
                else
                    if same_item:Count()>0  then
                        table.insert(same_items, same_item)
                    end
                end
            else
                break
            end
        end
    end
    return same_items
end
function ItemManager:GetCanSellSameTypeItems(item)
    local same_items = self:GetSameTypeItems(item)
    local canSell = {}
    for i,v in ipairs(same_items) do
        if v:IsSell() then
            table.insert(canSell, v)
        end
    end
    return canSell
end
function ItemManager:CanOpenChest( item )
    local area_type = string.split(item:Name(),"_")
    local key_item = self:GetItemByName("chestKey_"..area_type[2])
    -- 木宝箱不需要钥匙
    return  not key_item or key_item:Count()>0
end
return ItemManager

















