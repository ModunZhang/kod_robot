--
-- Author: Kenny Dai
-- Date: 2015-01-30 15:03:56
--
local Enum = import("..utils.Enum")
local MultiObserver = import(".MultiObserver")
local Item = import(".Item")
local AllianceItemsManager = class("AllianceItemsManager", MultiObserver)

AllianceItemsManager.LISTEN_TYPE = Enum("ITEM_CHANGED","ITEM_LOGS_CHANGED")

function AllianceItemsManager:ctor()
    AllianceItemsManager.super.ctor(self)
    self.items = {}
    self.items_buff = {}
    self.items_resource = {}
    self.items_special = {}
    self.items_speedUp = {}
    self.item_logs = {}
    self:InitAllItems()
end
-- 是否有新货物
function AllianceItemsManager:IsNewGoodsCome()
    return self.isNewGoodsCome
end
function AllianceItemsManager:NewGoodsCome()
    self.isNewGoodsCome = true
end
-- 已查看新货物
function AllianceItemsManager:HasCheckNewGoods()
    self.isNewGoodsCome = false
end
-- 初始化所有道具，数量 0
function AllianceItemsManager:InitAllItems()
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

function AllianceItemsManager:OnItemsChanged(alliance_data,deltaData)
    local is_fully_update = deltaData == nil
    if is_fully_update then
        if alliance_data.items then
            for i,v in ipairs(alliance_data.items) do
                local item = self:GetItemByName(v.name)
                item:SetCount(v.count)
                self:InsertItem(item)
            end
        end
    end
    local is_delta_update = not is_fully_update and deltaData.items ~= nil
    if is_delta_update then
        local changed_map = GameUtils:Handler_DeltaData_Func(
            deltaData.items
            ,function(data)
                -- add
                local item = self:GetItemByName(data.name)
                item:SetCount(data.count)
                self:InsertItem(item)
                print("__OnItemsChanged add",data.name,data.count)
                return item
            end
            ,function(data)
                -- eidt 更新
                local item = self:GetItemByName(data.name)
                item:SetCount(data.count)
                self:InsertItem(item)
                print("__OnItemsChanged edit",data.name,data.count)
                return item
            end
            ,function(data)
                -- remove
                local item = self:GetItemByName(data.name)
                self:RemoveItem(item)
                return item
            end
        )
        self:NotifyListeneOnType(AllianceItemsManager.LISTEN_TYPE.ITEM_CHANGED, function(listener)
            listener:OnItemsChanged(changed_map)
        end)
    end
end
function AllianceItemsManager:OnItemLogsChanged(alliance_data,deltaData)
    local is_fully_update = deltaData == nil
    if is_fully_update then
        if alliance_data.itemLogs then
            local itemLogs = clone(alliance_data.itemLogs)
            table.sort( itemLogs, function ( a,b )
                return a.time > b.time
            end )
            self.item_logs = itemLogs
        end
    end
    local is_delta_update = not is_fully_update and deltaData.itemLogs ~= nil
    local item_logs = self.item_logs
    if is_delta_update then
        local changed_map = GameUtils:Handler_DeltaData_Func(
            deltaData.itemLogs
            ,function(data)
                -- add
                table.insert(item_logs, 1,data)
                self:NewGoodsCome()
                return data
            end
            ,function(data)
                -- eidt 更新
                assert(false,"联盟商店记录会更新？")
                return data
            end
            ,function(data)
                for i,v in ipairs(item_logs) do
                    if v.time == data.time then
                        table.remove(item_logs,i)
                    end
                end
                return data
            end
        )
        self:NotifyListeneOnType(AllianceItemsManager.LISTEN_TYPE.ITEM_LOGS_CHANGED, function(listener)
            listener:OnItemLogsChanged(changed_map)
        end)
    end
end


-- 按照道具类型添加到对应table,并加入总表
function AllianceItemsManager:InsertItem(item)
    self:GetCategoryItems(item)[item:Name()] = item
    self.items[item:Name()] = item
end
function AllianceItemsManager:RemoveItem(item)
    self:GetCategoryItems(item)[item:Name()]:SetCount(0)
    self.items[item:Name()]:SetCount(0)
end
function AllianceItemsManager:GetCategoryItems(item)
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
function AllianceItemsManager:GetItemByName(name)
    return self.items[name]
end
function AllianceItemsManager:GetSpecialItems()
    return self:__order(self.items_special)
end
function AllianceItemsManager:GetBuffItems()
    return self:__order(self.items_buff)

end
function AllianceItemsManager:GetResourcetItems()
    return self:__order(self.items_resource)
end
function AllianceItemsManager:GetSpeedUpItems()
    return self:__order(self.items_speedUp)
end
function AllianceItemsManager:GetAllNormalItems()
    local normal_items = {}
    for i,v in ipairs(self:GetSpecialItems()) do
        if not v:IsAdvancedItem() then
            table.insert(normal_items, v)
        end
    end
    for i,v in ipairs(self:GetBuffItems()) do
        if not v:IsAdvancedItem() then
            table.insert(normal_items, v)
        end
    end
    for i,v in ipairs(self:GetResourcetItems()) do
        if not v:IsAdvancedItem() then
            table.insert(normal_items, v)
        end
    end
    for i,v in ipairs(self:GetSpeedUpItems()) do
        if not v:IsAdvancedItem() then
            table.insert(normal_items, v)
        end
    end
    return normal_items
end
function AllianceItemsManager:GetAllSuperItems()
    local super_items = {}
    for i,v in ipairs(self:GetSpecialItems()) do
        if v:IsAdvancedItem() then
            table.insert(super_items, v)
        end
    end
    for i,v in ipairs(self:GetBuffItems()) do
        if v:IsAdvancedItem() then
            table.insert(super_items, v)
        end
    end
    for i,v in ipairs(self:GetResourcetItems()) do
        if v:IsAdvancedItem() then
            table.insert(super_items, v)
        end
    end
    for i,v in ipairs(self:GetSpeedUpItems()) do
        if v:IsAdvancedItem() then
            table.insert(super_items, v)
        end
    end
    return super_items
end
function AllianceItemsManager:__order(items)
    local order_items = {}
    for k,v in pairs(items) do
        table.insert(order_items, v)
    end
    table.sort(order_items,function ( a,b )
        return a:Order() < b:Order()
    end)
    return order_items
end
function AllianceItemsManager:GetItemLogs()
    return self.item_logs
end
return AllianceItemsManager





