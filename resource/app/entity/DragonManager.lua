--
-- Author: Danny He
-- Date: 2014-10-27 21:33:54
--
local Enum = import("app.utils.Enum")
local Localize = import("app.utils.Localize")
local property = import("app.utils.property")
local MultiObserver = import("app.entity.MultiObserver")
local DragonManager = class("DragonManager", MultiObserver)
local AutomaticUpdateResource = import(".AutomaticUpdateResource")
local Dragon = import(".Dragon")
local promise = import("..utils.promise")
local DragonEvent = import(".DragonEvent")
local DragonDeathEvent = import(".DragonDeathEvent")
local config_intInit = GameDatas.PlayerInitData.intInit

DragonManager.LISTEN_TYPE = Enum("OnHPChanged","OnBasicChanged","OnDragonHatched",
    -- "OnDragonEventChanged","OnDragonEventTimer",
    "OnDefencedDragonChanged",
    "OnDragonDeathEventChanged","OnDragonDeathEventTimer","OnDragonDeathEventRefresh")


function DragonManager:ctor()
    DragonManager.super.ctor(self)
    self.dragons_hp = {}
    -- self.dragon_events = {} --孵化事件
    self.dragonDeathEvents = {} --复活事件
end
function DragonManager:GetEnableHatedDragon()
    -- if self:HaveDragonHateEvent() then
    --     return
    -- end
    for _,dragon in pairs(self:GetDragons()) do
        if not dragon:Ishated() then
            return dragon
        end
    end
end
function DragonManager:IsAllHated()
    local count = 0
    -- if self:HaveDragonHateEvent() then
    --     count = count + 1
    -- end
    local max = 0
    for _,dragon in pairs(self:GetDragons()) do
        max = max + 1
        if dragon:Ishated() then
            count = count + 1
        end
    end
    return max == count
end
function DragonManager:IsHateEnable()
    -- if self:HaveDragonHateEvent() then
    --     return false
    -- end
    for _,dragon in pairs(self:GetDragons()) do
        if not dragon:Ishated() then
            return true
        end
    end
end
function DragonManager:GetHatedCount()
    local count = 0
    for _,dragon in pairs(self:GetDragons()) do
        if dragon:Ishated() then
            count = count + 1
        end
    end
    return count
end
function DragonManager:GetDragonArray()
    local arr = {"redDragon","greenDragon","blueDragon"}
    local powerfulDragon = self:GetPowerfulDragonType()
    if powerfulDragon ~= "" then
        local type_index = table.indexof(arr,powerfulDragon)
        local count = #arr
        local dest = {}
        for i= type_index,count do
            table.insert(dest,arr[i])
        end
        for i=1,type_index - 1 do
            table.insert(dest,arr[i])
        end
        return dest
    else
        return arr
    end
end

function DragonManager:SortDragon()
    self.dragon_index_arr = self:GetDragonArray()
    for index,v in ipairs(self.dragon_index_arr) do
        self.dragon_index_arr[v] = index
    end
end

function DragonManager:SortWithFirstDragon(dragon_type)
    local arr = {"redDragon","greenDragon","blueDragon"}
    table.sort( arr, function(a,b) 
        return a == dragon_type
    end)
    self.dragon_index_arr = arr
    for index,v in ipairs(self.dragon_index_arr) do
        self.dragon_index_arr[v] = index
    end
end

function DragonManager:GetDragonIndexByType(dragon_type,needSort)
    if not self.dragon_index_arr or needSort then
        self:SortDragon()
    end
    local arr = self.dragon_index_arr
    return arr[dragon_type]
end

function DragonManager:GetDragonByIndex(index,needSort)
    if not self.dragon_index_arr or needSort then
        self:SortDragon()
    end
    local arr = self.dragon_index_arr
    local dragon_type = arr[index]
    return self:GetDragon(dragon_type)
end

function DragonManager:GetDragon(dragon_type)
    if not dragon_type then return nil end
    return self.dragons_[dragon_type]
end
--获取驻防的龙
function DragonManager:GetDefenceDragon()
    for k,dragon in pairs(self:GetDragons()) do
        if dragon:IsDefenced() then
            return dragon
        end
    end
    return nil
end

function DragonManager:GetPowerfulDragonType()
    local dragonWidget = 0
    local dragonType = ""
    for k,dragon in pairs(self:GetDragons()) do
        if dragon:GetWeight() > dragonWidget then
            dragonWidget = dragon:GetWeight()
            dragonType = k
        end
    end
    return dragonType
end

function DragonManager:GetCanFightPowerfulDragonType()
    local dragonWidget = 0
    local dragonType = ""
    for k,dragon in pairs(self:GetDragons()) do
        if (dragon:Status()=="free" or dragon:Status()=="defence") and not dragon:IsDead() then
            if dragon:GetWeight() > dragonWidget then
                dragonWidget = dragon:GetWeight()
                dragonType = k
            end
        end
    end
    return dragonType
end

function DragonManager:AddDragon(dragon)
    self.dragons_[dragon:Type()] = dragon
end

function DragonManager:GetDragons()
    return self.dragons_ or {}
end
-- 获取战力高-低的龙list
function DragonManager:GetDragonsSortWithPowerful()
    local dragon_list = {}
    for k,v in pairs(self.dragons_) do
        if v:Ishated() then
            table.insert(dragon_list, v)
        end
    end
    table.sort( dragon_list, function(a,b)
        return a:GetWeight() > b:GetWeight()
    end )
    return dragon_list
end

function DragonManager:OnUserDataChanged(user_data, current_time, deltaData,hp_recovery_perHour)
    self:RefreshDragonData(user_data.dragons,current_time,hp_recovery_perHour,deltaData)
    -- self:RefreshDragonEvents(user_data,deltaData)
    self:RefreshDragonDeathEvents(user_data,deltaData)
end

-- function DragonManager:HaveDragonHateEvent()
--     return not LuaUtils:table_empty(self.dragon_events)
-- end

-- function DragonManager:GetDragonEventByDragonType(dragon_type)
--     return self.dragon_events[dragon_type]
-- end

-- function DragonManager:RefreshDragonEvents(user_data,deltaData)
--     if not user_data.dragonHatchEvents then return end
--     local is_fully_update = deltaData == nil
--     local is_delta_update = not is_fully_update and deltaData.dragonHatchEvents ~= nil
--     if is_fully_update then
--         self.dragon_events = {}
--         for _,v in ipairs(user_data.dragonHatchEvents) do
--             if not self.dragon_events[v.dragonType] then
--                 local dragonEvent = DragonEvent.new()
--                 dragonEvent:UpdateData(v)
--                 self.dragon_events[dragonEvent:DragonType()] = dragonEvent
--                 dragonEvent:AddObserver(self)
--             end
--         end
--     end
--     if is_delta_update then
--         local changed_map = GameUtils:Handler_DeltaData_Func(
--             deltaData.dragonHatchEvents
--             ,function(event_data)
--                 local dragonEvent = DragonEvent.new()
--                 dragonEvent:UpdateData(event_data)
--                 self.dragon_events[dragonEvent:DragonType()] = dragonEvent
--                 dragonEvent:AddObserver(self)
--                 return dragonEvent
--             end
--             ,function(event_data)
--                 if self.dragon_events[event_data.dragonType] then
--                     local dragonEvent = self.dragon_events[event_data.dragonType]
--                     dragonEvent:UpdateData(event_data)
--                 end
--             end
--             ,function(event_data)
--                 if self.dragon_events[event_data.dragonType] then
--                     local dragonEvent = self.dragon_events[event_data.dragonType]
--                     dragonEvent:Reset()
--                     self.dragon_events[event_data.dragonType] = nil
--                     dragonEvent = DragonEvent.new()
--                     dragonEvent:UpdateData(event_data)

--                     GameGlobalUI:showTips(_("提示"),string.format(_("孵化%s完成"),Localize.dragon[event_data.dragonType]))

--                     return dragonEvent
--                 end
--             end
--         )
--         self:NotifyListeneOnType(DragonManager.LISTEN_TYPE.OnDragonEventChanged,function(listener)
--             listener.OnDragonEventChanged(listener,GameUtils:pack_event_table(changed_map))
--         end)
--     end
-- end

-- function DragonManager:IteratorDragonEvents(func)
--     for _,dragonEvent in pairs(self.dragon_events) do
--         func(dragonEvent)
--     end
-- end

-- function DragonManager:OnDragonEventTimer(dragonEvent)
--     self:NotifyListeneOnType(DragonManager.LISTEN_TYPE.OnDragonEventTimer,function(listener)
--         listener.OnDragonEventTimer(listener,dragonEvent)
--     end)
-- end

--复活事件
function DragonManager:RefreshDragonDeathEvents(user_data,deltaData)
    if not user_data.dragonDeathEvents then return end
    local is_fully_update = deltaData == nil
    local is_delta_update = not is_fully_update and deltaData.dragonDeathEvents ~= nil
    local is_full_array = is_delta_update and not deltaData.dragonDeathEvents.add and not deltaData.dragonDeathEvents.edit and not deltaData.dragonDeathEvents.remove

    if is_fully_update or is_full_array then
        for __,v in pairs(self.dragonDeathEvents) do
            v:Reset()
        end
        self.dragonDeathEvents = {}
        for _,v in ipairs(user_data.dragonDeathEvents) do
            if not self.dragonDeathEvents[v.dragonType] then
                local dragonDeathEvent = DragonDeathEvent.new()
                dragonDeathEvent:UpdateData(v)
                dragonDeathEvent:AddObserver(self)
                self.dragonDeathEvents[dragonDeathEvent:DragonType()] = dragonDeathEvent
            end
        end
        self:NotifyListeneOnType(DragonManager.LISTEN_TYPE.OnDragonDeathEventRefresh,function(listener)
            listener.OnDragonDeathEventRefresh(listener,self.dragonDeathEvents)
        end)
    end
    if is_delta_update and not is_full_array then
        local changed_map = GameUtils:Handler_DeltaData_Func(
            deltaData.dragonDeathEvents
            ,function(event_data)
                local dragonDeathEvent = DragonDeathEvent.new()
                dragonDeathEvent:UpdateData(event_data)
                dragonDeathEvent:AddObserver(self)
                self.dragonDeathEvents[dragonDeathEvent:DragonType()] = dragonDeathEvent
                return dragonDeathEvent
            end
            ,function(event_data)
                if self.dragonDeathEvents[event_data.dragonType] then
                    local dragonDeathEvent = self.dragonDeathEvents[event_data.dragonType]
                    dragonDeathEvent:UpdateData(event_data)
                end
                return dragonDeathEvent
            end
            ,function(event_data)
                if self.dragonDeathEvents[event_data.dragonType] then
                    local dragonDeathEvent = self.dragonDeathEvents[event_data.dragonType]
                    dragonDeathEvent:Reset()
                    self.dragonDeathEvents[event_data.dragonType] = nil
                    dragonDeathEvent = DragonDeathEvent.new()
                    dragonDeathEvent:UpdateData(event_data)
                    GameGlobalUI:showTips(_("提示"),string.format(_("%s已经复活"),Localize.dragon[event_data.dragonType]))
                    return dragonDeathEvent
                end
            end
        )
        self:NotifyListeneOnType(DragonManager.LISTEN_TYPE.OnDragonDeathEventChanged,function(listener)
            listener.OnDragonDeathEventChanged(listener,GameUtils:pack_event_table(changed_map))
        end)
    end
end

function DragonManager:IteratorDragonDeathEvents(func)
    for __,v in pairs(self.dragonDeathEvents) do
        func(v)
    end
end

function DragonManager:GetDragonDeathEventByType(dragonType)
    return self.dragonDeathEvents[dragonType]
end

function DragonManager:OnDragonDeathEventTimer(dragonDeathEvent)
    self:NotifyListeneOnType(DragonManager.LISTEN_TYPE.OnDragonDeathEventTimer,function(listener)
        listener.OnDragonDeathEventTimer(listener,dragonDeathEvent)
    end)
end

function DragonManager:RefreshDragonData( dragons,resource_refresh_time,hp_recovery_perHour,deltaData)
    if not dragons then return end
    if not self.dragons_ or deltaData == nil then -- 初始化龙信息
        self.dragons_ = {}
        for k,v in pairs(dragons) do
            local dragon = Dragon.new(k,v.strength,v.vitality,v.status,v.star,v.level,v.exp,v.hp or 0)
            dragon:UpdateEquipmetsAndSkills(v)
            self:AddDragon(dragon)
            self:checkHPRecoveryIf_(dragon,v.hpRefreshTime/1000,hp_recovery_perHour)
        end
    elseif dragons and deltaData.dragons then
        --遍历更新龙信息
        local need_notify_defence = false
        for k,v in pairs(dragons) do
            local dragon = self:GetDragon(k)
            if dragon then
                local dragonIsHated_ = dragon:Ishated()
                local isDefenced = dragon:IsDefenced()
                local old_star = dragon:Star()
                dragon:Update(v) -- include UpdateEquipmetsAndSkills
                local star_chaned =  dragon:Star() > old_star
                if not need_notify_defence then
                    need_notify_defence = isDefenced ~= dragon:IsDefenced()
                end
                if dragonIsHated_ ~= dragon:Ishated() then
                    self:NotifyListeneOnType(DragonManager.LISTEN_TYPE.OnDragonHatched,function(listener)
                        listener.OnDragonHatched(listener,dragon)
                    end)
                    if DragonManager.hate_callback then
                        DragonManager.hate_callback()
                        DragonManager.hate_callback = nil
                    end
                else
                    self:NotifyListeneOnType(DragonManager.LISTEN_TYPE.OnBasicChanged,function(listener)
                        listener.OnBasicChanged(listener,dragon,star_chaned)
                    end)
                end
            end
            self:checkHPRecoveryIf_(dragon,resource_refresh_time,hp_recovery_perHour)
        end
        if need_notify_defence then
            self:NotifyListeneOnType(DragonManager.LISTEN_TYPE.OnDefencedDragonChanged,function(listener)
                listener.OnDefencedDragonChanged(listener,self:GetDefenceDragon())
            end)
            if DragonManager.defence_callback then
                DragonManager.defence_callback()
                DragonManager.defence_callback = nil
            end
        end
    end
    self:CheckFinishEquipementDragonPormise()
end


function DragonManager:checkHPRecoveryIf_(dragon,resource_refresh_time,hp_recovery_perHour)
    --龙死了 并且 龙还在血量恢复队列中 从队列中移除这条龙
    if dragon:Ishated() and dragon:IsDead() and self:GetHPResource(dragon:Type())  then
        self:RemoveHPResource(dragon:Type())
    end
    local tmp_resource = self:GetHPResource(dragon:Type())
    if resource_refresh_time and tmp_resource then
        tmp_resource:UpdateResource(resource_refresh_time,dragon:Hp())
    end
    --判断是否可以执行血量恢复 如果队列中没有这条龙会添加
    if dragon:Ishated() and not dragon:IsDead() and dragon:Status() ~= 'march' then
        local hp_resource = self:AddHPResource(dragon:Type())
        hp_resource:UpdateResource(resource_refresh_time,dragon:Hp())
        local val_of_hp_recovery_perHour = hp_recovery_perHour[dragon:Type()]
        hp_resource:SetProductionPerHour(resource_refresh_time,val_of_hp_recovery_perHour)
        hp_resource:SetValueLimit(dragon:GetMaxHP())
    end
end

-- HP
function DragonManager:AddHPResource(dragon_type)
    if not self:GetHPResource(dragon_type) then
        self.dragons_hp[dragon_type] = AutomaticUpdateResource.new()
    end
    return self:GetHPResource(dragon_type)
end

function DragonManager:RemoveHPResource(dragon_type)
    if self:GetHPResource(dragon_type) then
        self.dragons_hp[dragon_type] = nil
    else
        return true
    end
end

function DragonManager:GetHPResource(dragon_type)
    return self.dragons_hp[dragon_type]
end

function DragonManager:GetCurrentHPValueByDragonType(dragon_type)
    if not self:GetHPResource(dragon_type) then
        return -1
    end
    return self:GetHPResource(dragon_type):GetResourceValueByCurrentTime(app.timer:GetServerTime())
end

function DragonManager:UpdateHPResourceByTime(current_time)
    for dragonType, v in pairs(self.dragons_hp) do
        local dragon = self:GetDragon(dragonType)
        if dragon then
            dragon:SetHp(self:GetCurrentHPValueByDragonType(dragonType))
        end
    end
end

function DragonManager:OnTimer(current_time)
    self:UpdateHPResourceByTime(current_time)
    self:OnHPChanged()
    -- self:IteratorDragonEvents(function(dragonEvent)
    --     dragonEvent:OnTimer(current_time)
    -- end)
    self:IteratorDragonDeathEvents(function(dragonDeathEvent)
        dragonDeathEvent:OnTimer(current_time)
    end)
end

function DragonManager:OnHPChanged()
    self:NotifyListeneOnType(DragonManager.LISTEN_TYPE.OnHPChanged,function(listener)
        listener.OnHPChanged(listener)
    end)
end

-- function DragonManager:GetHateNeedMinutes(dragonType)
--     if self:NoDragonHated() then return 0 end
--     return config_intInit['playerHatchDragonNeedMinutes']['value']
-- end

-- function DragonManager:NoDragonHated()
--     for __,dragon in pairs(self:GetDragons()) do
--         if dragon:Ishated() then
--             return false
--         end
--     end
--     return true
-- end

--新手引导
DragonManager.promise_callbacks = {}
function DragonManager:PromiseOfFinishEquipementDragon()
    local p = promise.new()
    table.insert(self.promise_callbacks, function(dragon)
        if dragon:Ishated() then
            for _,eq in pairs(dragon:Equipments()) do
                if eq:IsLoaded() then
                    return p:resolve()
                end
            end
        end
    end)
    return p
end

function DragonManager:CheckFinishEquipementDragonPormise()
    for _,dragon in pairs(self:GetDragons()) do
        if #self.promise_callbacks > 0 and self.promise_callbacks[1](dragon) then
            table.remove(self.promise_callbacks, 1)
        end
    end
end
function DragonManager:PromiseOfHate()
    local p = promise.new()
    DragonManager.hate_callback = function()
        return p:resolve()
    end
    return p
end
function DragonManager:PromiseOfDefence()
    local p = promise.new()
    DragonManager.defence_callback = function()
        return p:resolve()
    end
    return p
end



return DragonManager

