local config_equipments = GameDatas.DragonEquipments.equipments
local config_function = GameDatas.BuildingFunction.blackSmith
local config_levelup = GameDatas.BuildingLevelUp.blackSmith

local Localize = import("..utils.Localize")
local Observer = import(".Observer")
local UpgradeBuilding = import(".UpgradeBuilding")
local BlackSmithUpgradeBuilding = class("BlackSmithUpgradeBuilding", UpgradeBuilding)

function BlackSmithUpgradeBuilding:ctor(...)
    self.black_smith_building_observer = Observer.new()
    self.making_event = self:CreateEvent()
    BlackSmithUpgradeBuilding.super.ctor(self, ...)
end
function BlackSmithUpgradeBuilding:GetNextLevelEfficiency()
    return config_function[self:GetNextLevel()].efficiency
end
function BlackSmithUpgradeBuilding:GetEfficiency()
    if self:GetLevel() > 0 then
        return config_function[self:GetLevel()].efficiency
    end
    return 0
end
function BlackSmithUpgradeBuilding:CreateEvent()
    local black_smith = self
    local event = {}
    function event:Init()
        self:Reset()
    end
    function event:Reset()
        self.content = nil
        self.finished_time = 0
        self.id = nil
    end
    function event:UniqueKey()
        return self:Id()
    end
    function event:StartTime()
        local total = black_smith:GetMakingTimeByEquipment(self.content)
        return self.finished_time - total + DataUtils:getBuffEfffectTime(total, black_smith:GetEfficiency())
    end
    function event:ElapseTime(current_time)
        return current_time - self:StartTime()
    end
    function event:LeftTime(current_time)
        return self.finished_time - current_time
    end
    function event:Percent(current_time)
        local start_time = self:StartTime()
        local elapse_time = current_time - start_time
        local total_time = self.finished_time - start_time
        return elapse_time * 100.0 / total_time
    end
    function event:FinishTime()
        return self.finished_time
    end
    function event:SetFinishTime(current_time)
        self.finished_time = current_time
    end
    function event:Content()
        return self.content
    end
    function event:SetContentWithFinishTime(content, finished_time, id)
        self.content = content
        self.finished_time = finished_time
        self.id = id
    end
    function event:IsEmpty()
        return self.finished_time == 0 and self.content == nil
    end
    function event:IsMaking()
        return self.content ~= nil
    end
    function event:Id()
        return self.id
    end
    function event:ContentDesc()
        return string.format("%s %s", _("正在制作"), Localize.equip[self:Content()])
    end
    function event:TimeDesc(time)
        return GameUtils:formatTimeStyle1(self:LeftTime(time)), self:Percent(time)
    end
    event:Init()
    return event
end
function BlackSmithUpgradeBuilding:ResetAllListeners()
    BlackSmithUpgradeBuilding.super.ResetAllListeners(self)
    self.black_smith_building_observer:RemoveAllObserver()
end
function BlackSmithUpgradeBuilding:AddBlackSmithListener(listener)
    assert(listener.OnBeginMakeEquipmentWithEvent)
    assert(listener.OnMakingEquipmentWithEvent)
    assert(listener.OnEndMakeEquipmentWithEvent)
    self.black_smith_building_observer:AddObserver(listener)
end
function BlackSmithUpgradeBuilding:RemoveBlackSmithListener(listener)
    self.black_smith_building_observer:RemoveObserver(listener)
end
function BlackSmithUpgradeBuilding:GetMakeEquipmentEvent()
    return self.making_event
end
function BlackSmithUpgradeBuilding:IsEquipmentEventEmpty()
    return self.making_event:IsEmpty()
end
function BlackSmithUpgradeBuilding:IsMakingEquipment()
    return self.making_event:IsMaking()
end
function BlackSmithUpgradeBuilding:MakeEquipmentWithFinishTime(equipment, finished_time, id)
    local event = self.making_event
    event:SetContentWithFinishTime(equipment, finished_time, id)
    self.black_smith_building_observer:NotifyObservers(function(listener)
        listener:OnBeginMakeEquipmentWithEvent(self, event)
    end)
end
function BlackSmithUpgradeBuilding:EndMakeEquipmentWithCurrentTime()
    local event = self.making_event
    local equipment = event:Content()
    event:SetContentWithFinishTime(nil, 0)
    self.black_smith_building_observer:NotifyObservers(function(listener)
        listener:OnEndMakeEquipmentWithEvent(self, event, equipment)
    end)
end
function BlackSmithUpgradeBuilding:SpeedUpMakingEquipment()
    self.black_smith_building_observer:NotifyObservers(function(listener)
        if listener.OnSpeedUpMakingEquipment then
            listener:OnSpeedUpMakingEquipment()
        end
    end)
end
function BlackSmithUpgradeBuilding:GetMakingTimeByEquipment(equipment)
    local config = config_equipments[equipment]
    return config.makeTime
end

function BlackSmithUpgradeBuilding:OnTimer(current_time)
    local event = self.making_event
    if event:IsMaking() then
        self.black_smith_building_observer:NotifyObservers(function(listener)
            listener:OnMakingEquipmentWithEvent(self, event, current_time)
        end)
    end
    BlackSmithUpgradeBuilding.super.OnTimer(self, current_time)
end
function BlackSmithUpgradeBuilding:OnUserDataChanged(...)
    BlackSmithUpgradeBuilding.super.OnUserDataChanged(self, ...)
    local userData, current_time, location_id, sub_location_id, deltaData = ...
    
    if not userData.dragonEquipmentEvents then return end

    local is_fully_update = deltaData == nil
    local is_delta_update = self:IsUnlocked() and deltaData and deltaData.dragonEquipmentEvents
    if not is_fully_update and not is_delta_update then
        return 
    end
    print("BlackSmithUpgradeBuilding:OnUserDataChanged")

    if is_delta_update then
        local dragonEquipmentEvents = deltaData.dragonEquipmentEvents
        if dragonEquipmentEvents.add and dragonEquipmentEvents.remove then
            self:EndMakeEquipmentWithCurrentTime()
        end
    end

    local event = userData.dragonEquipmentEvents[1]
    if event then
        local finished_time = event.finishTime / 1000
        if self:IsEquipmentEventEmpty() then
            self:MakeEquipmentWithFinishTime(event.name, finished_time, event.id)
        else
            local makingEvent = self:GetMakeEquipmentEvent()
            if finished_time ~= makingEvent:FinishTime() then
                self:SpeedUpMakingEquipment()
                self:GetMakeEquipmentEvent():SetContentWithFinishTime(event.name, finished_time, event.id)
            end
        end
    elseif not self:IsEquipmentEventEmpty() then
        self:EndMakeEquipmentWithCurrentTime()
    end
end

return BlackSmithUpgradeBuilding



















