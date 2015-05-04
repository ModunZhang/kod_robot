local config_function = GameDatas.BuildingFunction.toolShop
local config_levelup = GameDatas.BuildingLevelUp.toolShop
local Observer = import(".Observer")
local UpgradeBuilding = import(".UpgradeBuilding")
local ToolShopUpgradeBuilding = class("ToolShopUpgradeBuilding", UpgradeBuilding)


local TECHNOLOGY = "technology"
local BUILDING = "building"

function ToolShopUpgradeBuilding:ctor(building_info)
    self.toolShop_building_observer = Observer.new()
    self.building_event = self:CreateEvent(BUILDING)
    self.technology_event = self:CreateEvent(TECHNOLOGY)
    self.category = {
        building = self.building_event,
        technology = self.technology_event,
    }

    ToolShopUpgradeBuilding.super.ctor(self, building_info)
end
function ToolShopUpgradeBuilding:CreateEvent(category)
    local tool_shop = self
    local event = {}
    function event:Init(category)
        self.category = category
        self:Reset()
    end
    function event:Reset()
        self.content = {}
        self.finished_time = 0
        self.id = nil
    end
    function event:UniqueKey()
        return self:Id()
    end
    function event:Category()
        return self.category
    end
    function event:Id()
        return self.id
    end
    function event:StartTime()
        return self.finished_time - tool_shop:GetMakingTimeByCategory(self.category)
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
    function event:TotalCount()
        local count = 0
        for k, v in pairs(self.content) do
            count = count + v.count
        end
        return count
    end
    function event:Content()
        return self.content
    end
    function event:SetContent(content, finished_time,id)
        self.content = content == nil and {} or content
        self.finished_time = finished_time
        self.id = id
    end
    function event:IsStored(current_time)
        return #self.content > 0 and (self.finished_time == 0 or current_time >= self.finished_time)
    end
    function event:IsEmpty()
        return self.finished_time == 0 and #self.content == 0
    end
    function event:IsMaking(current_time)
        return current_time < self.finished_time
    end
    event:Init(category)
    return event
end
function ToolShopUpgradeBuilding:GetTechnologyEvent()
    return self.technology_event
end
function ToolShopUpgradeBuilding:GetBuildingEvent()
    return self.building_event
end
function ToolShopUpgradeBuilding:ResetAllListeners()
    ToolShopUpgradeBuilding.super.ResetAllListeners(self)
    self.toolShop_building_observer:RemoveAllObserver()
end
function ToolShopUpgradeBuilding:AddToolShopListener(listener)
    assert(listener.OnBeginMakeMaterialsWithEvent)
    assert(listener.OnMakingMaterialsWithEvent)
    assert(listener.OnEndMakeMaterialsWithEvent)
    assert(listener.OnGetMaterialsWithEvent)
    self.toolShop_building_observer:AddObserver(listener)
end
function ToolShopUpgradeBuilding:RemoveToolShopListener(listener)
    self.toolShop_building_observer:RemoveObserver(listener)
end
function ToolShopUpgradeBuilding:GetMakeMaterialsEvents()
    return self.category
end
function ToolShopUpgradeBuilding:IsMakingAny(current_time)
    for _,v in pairs(self.category) do
        if v:IsMaking(current_time) then
            return true
        end
    end
    return false
end
function ToolShopUpgradeBuilding:GetMakeMaterialsEventByCategory(category)
    return self.category[category]
end
function ToolShopUpgradeBuilding:IsMaterialsEmptyByCategory(category)
    return self.category[category]:IsEmpty()
end
function ToolShopUpgradeBuilding:IsStoredMaterialsByCategory(category, current_time)
    return self.category[category]:IsStored(current_time)
end
function ToolShopUpgradeBuilding:IsMakingMaterialsByCategory(category, current_time)
    return self.category[category]:IsMaking(current_time)
end
function ToolShopUpgradeBuilding:MakeMaterialsByCategoryWithFinishTime(category, materials, current_time, finished_time, id)
    if self.category[category]:IsMaking(current_time) then return end
    local event = self.category[category]
    event:SetContent(materials, finished_time,id)
    self.toolShop_building_observer:NotifyObservers(function(listener)
        listener:OnBeginMakeMaterialsWithEvent(self, event)
    end)
end
function ToolShopUpgradeBuilding:EndMakeMaterialsByCategoryWithCurrentTime(category, materials, current_time, id)
    if self.category[category]:IsStored(current_time) then return end
    local event = self.category[category]
    event:SetContent(materials, 0, id)
    self.toolShop_building_observer:NotifyObservers(function(listener)
        listener:OnEndMakeMaterialsWithEvent(self, event, current_time)
    end)
end
function ToolShopUpgradeBuilding:GetMaterialsByCategory(category)
    local event = self.category[category]
    local materials = event:Content()
    event:Reset()
    self.toolShop_building_observer:NotifyObservers(function(listener)
        listener:OnGetMaterialsWithEvent(self, event, materials)
    end)
end
function ToolShopUpgradeBuilding:SpeedUpMakingMaterial()
    self.toolShop_building_observer:NotifyObservers(function(listener)
        if listener.OnSpeedUpMakingMaterial then
            listener:OnSpeedUpMakingMaterial()
        end
    end)
end
function ToolShopUpgradeBuilding:GetMakingTimeByCategory(category)
    local _, _, _, _, time = self:GetNeedByCategory(category)
    return time
end
local needs = {"Wood", "Stone", "Iron", "time"}
function ToolShopUpgradeBuilding:GetNeedByCategory(category)
    local config = config_function[self:GetEfficiencyLevel()]
    local key = category == BUILDING and "Bm" or "Am"
    local need = {}
    for _, v in ipairs(needs) do
        table.insert(need, config[string.format("product%s%s", key, v)])
    end
    return config["production"], unpack(need)
end
function ToolShopUpgradeBuilding:GetProduction()
    local config = config_function[self:GetEfficiencyLevel()]
    return config["production"]
end
function ToolShopUpgradeBuilding:GetNextLevelProduction()
    local config = config_function[self:GetNextLevel()]
    return config["production"]
end

function ToolShopUpgradeBuilding:OnTimer(current_time)
    for _, event in pairs(self.category) do
        if event:IsMaking(current_time) then
            self.toolShop_building_observer:NotifyObservers(function(listener)
                listener:OnMakingMaterialsWithEvent(self, event, current_time)
            end)
        end
    end
    ToolShopUpgradeBuilding.super.OnTimer(self, current_time)
end

function ToolShopUpgradeBuilding:OnUserDataChanged(...)
    ToolShopUpgradeBuilding.super.OnUserDataChanged(self, ...)
    local userData, current_time, location_id, sub_location_id, deltaData = ...

    if not userData.materialEvents then return end

    local is_fully_update = deltaData == nil
    local is_delta_update = self:IsUnlocked() and deltaData and deltaData.materialEvents
    if not is_fully_update and not is_delta_update then
        return 
    end
    print("ToolShopUpgradeBuilding:OnUserDataChanged")
    local BUILDING_EVENT = 1
    local TECHNOLOGY_EVENT = 2
    local category_map = {
        [BUILDING_EVENT] = BUILDING,
        [TECHNOLOGY_EVENT] = TECHNOLOGY,
    }
    local events = {
        [BUILDING_EVENT] = nil,
        [TECHNOLOGY_EVENT] = nil,
    }

    for k, v in pairs(userData.materialEvents) do
        if v.category == "buildingMaterials" then
            events[BUILDING_EVENT] = v
        elseif v.category == "technologyMaterials" then
            events[TECHNOLOGY_EVENT] = v
        end
    end

    for category_index, category in ipairs(category_map) do
        local event = events[category_index]
        if event then
            local finished_time = event.finishTime / 1000
            local is_making_end = finished_time == 0
            if is_making_end then
                self:EndMakeMaterialsByCategoryWithCurrentTime(category, event.materials, current_time, event.id)
            elseif self:IsMaterialsEmptyByCategory(category) then
                self:MakeMaterialsByCategoryWithFinishTime(category, event.materials, current_time, finished_time, event.id)
            else
                local makingEvent = self:GetMakeMaterialsEventByCategory(category)
                if finished_time ~= makingEvent:FinishTime() then
                    self:SpeedUpMakingMaterial()
                    self:GetMakeMaterialsEventByCategory(category):SetContent(event.materials, finished_time, event.id)
                end
            end
        else
            if self:IsStoredMaterialsByCategory(category, current_time) then
                self:GetMaterialsByCategory(category)
            end
        end
    end
end

return ToolShopUpgradeBuilding















