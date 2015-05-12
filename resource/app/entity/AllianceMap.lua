local Enum = import("..utils.Enum")
local MultiObserver = import(".MultiObserver")
local Localize = import("..utils.Localize")
local AllianceMap = class("AllianceMap", MultiObserver)
-- local allianceBuildingType = GameDatas.AllianceInitData.buildingType
local buildingName = GameDatas.AllianceInitData.buildingName

AllianceMap.LISTEN_TYPE = Enum("BUILDING","BUILDING_INFO")


-- {
--     "id": "7kf2_RE13",
--     "name": "decorate_tree_1",
--     "location": {
--         "x": 1,
--         "y": 1
--     }
-- }
local mapObject_meta = {}
mapObject_meta.__index = mapObject_meta
function mapObject_meta:GetName()
    return self.name
end
function mapObject_meta:GetAllianceBuildingInfo()
    return self.alliance_map:FindAllianceBuildingInfoByObjects(self)
end
function mapObject_meta:GetAllianceVillageInfo()
    return self.alliance_map:FindAllianceVillagesInfoByObject(self)
end
function mapObject_meta:GetAllianceMemberInfo()
    return self.alliance_map:GetAllianceMemberInfo(self)
end
function mapObject_meta:GetAlliance()
    return self.alliance_map:GetAlliance()
end
function mapObject_meta:GetAllianceMap()
    return self.alliance_map
end
function mapObject_meta:SetAllianceMap(alliance_map)
    self.alliance_map = alliance_map
    return self
end
function mapObject_meta:GetType()
    return buildingName[self.name].type
end
function mapObject_meta:GetName()
    return self.name
end
function mapObject_meta:Id()
    return self.id
end
function mapObject_meta:GetSize()
    if not self.width then
        local config = buildingName[self.name] or {width = 1, height = 1}
        self.width = config.width
        self.height = config.height
    end
    return self.width, self.height
end
function mapObject_meta:GetLogicPosition()
    local location = self.location
    return location.x, location.y
end
function mapObject_meta:GetMidLogicPosition()
    local w,h = self:GetSize()
    local x,y = self:GetLogicPosition()
    return (2 * x - w + 1) / 2, (2 * y - h + 1) / 2
end
-- function mapObject_meta:GetMidLogicPosition()
--     local start_x, end_x, start_y, end_y = self:GetGlobalRegion()
--     return (start_x + end_x) / 2, (start_y + end_y) / 2
-- end
function mapObject_meta:GetTopLeftPoint()
    local start_x, end_x, start_y, end_y = self:GetGlobalRegion()
    return start_x, start_y
end
function mapObject_meta:GetTopRightPoint()
    local start_x, end_x, start_y, end_y = self:GetGlobalRegion()
    return end_x, start_y
end
function mapObject_meta:GetBottomLeftPoint()
    local start_x, end_x, start_y, end_y = self:GetGlobalRegion()
    return start_x, end_y
end
function mapObject_meta:GetBottomRightPoint()
    local start_x, end_x, start_y, end_y = self:GetGlobalRegion()
    return end_x, end_y
end
function mapObject_meta:IsContainPoint(x, y)
    local start_x, end_x, start_y, end_y = self:GetGlobalRegion()
    return x >= start_x and x <= end_x and y >= start_y and y <= end_y
end
function mapObject_meta:IsIntersect(building)
    local start_x, end_x, start_y, end_y = building:GetGlobalRegion()
    if self:IsContainPoint(start_x, start_y) then
        return true
    end
    if self:IsContainPoint(start_x, end_y) then
        return true
    end
    if self:IsContainPoint(end_x, start_y) then
        return true
    end
    if self:IsContainPoint(end_x, end_y) then
        return true
    end
end
function mapObject_meta:GetGlobalRegion()
    local w, h = self:GetSize()
    local x, y = self:GetLogicPosition()

    local start_x, end_x, start_y, end_y

    local is_orient_x = w > 0
    local is_orient_neg_x = not is_orient_x
    local is_orient_y = h > 0
    local is_orient_neg_y = not is_orient_y

    if is_orient_x then
        start_x, end_x = x - w + 1, x
    elseif is_orient_neg_x then
        start_x, end_x = x, x + math.abs(w) - 1
    end

    if is_orient_y then
        start_y, end_y = y - h + 1, y
    elseif is_orient_neg_y then
        start_y, end_y = y, y + math.abs(h) - 1
    end
    return start_x, end_x, start_y, end_y
end



local function is_city(object)
    return object.name == "member"
end
local function is_building(object)
    return buildingName[object.name].type == "building"
end
local function is_village(object)
    return buildingName[object.name].type == "village"
end
local function is_decorator(object)
    return buildingName[object.name].type == "decorate"
end
function AllianceMap:ctor(alliance)
    AllianceMap.super.ctor(self)
    self.alliance = alliance
    self.mapObjects = {}
    self.buildings = {}
    self.buildingMapObjects = {}
    self.memberMapObjects = {}
    self.villageMapObjects = {}
    self.decoratorMapObjects = {}
end
function AllianceMap:Reset()
    self.mapObjects = {}
    self.buildings = {}
    self.buildingMapObjects = {}
    self.memberMapObjects = {}
    self.villageMapObjects = {}
    self.decoratorMapObjects = {}
end
function AllianceMap:GetMapObjectsByType(type_)
    if type_ == "building" then
        return self.buildingMapObjects
    elseif type_ == "member" then
        return self.memberMapObjects
    elseif type_ == "village" then
        return self.villageMapObjects
    elseif type_ == "decorate" then
        return self.decoratorMapObjects
    end
    return {}
end
function AllianceMap:GetAllianceMemberInfo(object)
    if is_city(object) then
        return self:GetAlliance():GetMemberByMapObjectsId(object:Id())
    end
end
function AllianceMap:FindAllianceBuildingInfoByObjects(object)
    if is_building(object) then
        local id = object:Id()
        for _,v in ipairs(self.buildings) do
            if v.id == id then
                return v
            end
        end
    end
end
function AllianceMap:FindAllianceBuildingInfoByName(name)
    for k, v in pairs(self.buildings) do
        if v.name == name then
            return v
        end
    end
end
function AllianceMap:GetAllBuildingsInfo()
    return self.buildings
end
function AllianceMap:IteratorAllianceBuildings(func)
    for k,v in pairs(self:GetMapObjectsByType("building")) do
        if func(k,v) then
            return
        end
    end
end
function AllianceMap:IteratorCities(func)
    for k,v in pairs(self:GetMapObjectsByType("member")) do
        if func(k,v) then
            return
        end
    end
end
function AllianceMap:IteratorVillages(func)
    for k,v in pairs(self:GetMapObjectsByType("village")) do
        if func(k,v) then
            return
        end
    end
end
function AllianceMap:IteratorDecorators(func)
    for k,v in pairs(self:GetMapObjectsByType("decorate")) do
        if func(k,v) then
            return
        end
    end
end
function AllianceMap:IteratorByType(type_, func)
    self:IteratorAllObjects(function(k, v)
        if v:GetType() == type_ then
            if func(k, v) then
                return true
            end
        end
    end)
end
function AllianceMap:FindMapObjectById(id)
    for i,v in ipairs(self.mapObjects) do
        if v:Id() == id then
            return v
        end
    end
end
function AllianceMap:GetMapObjects()
    return self.mapObjects
end
function AllianceMap:IteratorAllObjects(func)
    for k, v in pairs(self.mapObjects) do
        if func(k, v) then
            return
        end
    end
end
function AllianceMap:CanMoveBuilding(allianceBuilding, x, y)
    local building = clone(allianceBuilding)
    building.location.x = x
    building.location.y = y
    for _,v in ipairs({building:GetGlobalRegion()}) do
        if v < 0 and v >= 51 then
            return false
        end
    end
    --
    local x1,y1 = allianceBuilding:GetLogicPosition()
    for _,v in pairs(self.mapObjects) do
        local x2,y2 = v:GetLogicPosition()
        -- 不一样才能比较
        if x1 ~= x2 or y1 ~= y2 then
            if building:IsIntersect(v) then
                return false
            end
        end
    end
    return true
end
function AllianceMap:GetAlliance()
    return self.alliance
end
function AllianceMap:OnAllianceDataChanged(allianceData, deltaData)
    self:OnMapObjectsChanged(allianceData, deltaData)
    self:OnAllianceBuildingInfoChange(allianceData, deltaData)
end
function AllianceMap:FindAllianceVillagesInfoByObject(object)
    if is_village(object) then 
        local village_info = self:GetAlliance():GetAllianceVillageInfos()[object:Id()]
        if village_info then
            return village_info
        end
    end
end
function AllianceMap:OnAllianceBuildingInfoChange(allianceData, deltaData)
    local is_fully_update = deltaData == nil
    local is_delta_update = not is_fully_update and deltaData.buildings ~= nil

    if is_fully_update or is_delta_update then
        self.buildings = allianceData.buildings
        if is_fully_update then
            for _,v in pairs(self.buildings) do
                self:NotifyListeneOnType(AllianceMap.LISTEN_TYPE.BUILDING_INFO, function(listener)
                    listener:OnBuildingInfoChange(v)
                end)
            end
        elseif is_delta_update then
            for i,v in ipairs(deltaData.buildings.edit or {}) do
                self:NotifyListeneOnType(AllianceMap.LISTEN_TYPE.BUILDING_INFO, function(listener)
                    listener:OnBuildingInfoChange(v)
                end)
                GameGlobalUI:showTips(_("提示"),string.format(_("建造%s至%d级完成"),Localize.alliance_buildings[v.name],v.level))
            end
        end
    end
end
function AllianceMap:OnMapObjectsChanged(allianceData, deltaData)
    local is_fully_update = deltaData == nil
    local is_delta_update = not is_fully_update and deltaData.mapObjects ~= nil

    if is_fully_update or is_delta_update then
        self.mapObjects = allianceData.mapObjects
        local objects_map = {
            building = {},
            member = {},
            village = {},
            decorate = {},
        }
        for k,v in pairs(self.mapObjects) do
            local type_ = buildingName[v.name].type
            objects_map[type_][v.id] = setmetatable(v, mapObject_meta):SetAllianceMap(self)
        end
        self.buildingMapObjects = objects_map.building
        self.memberMapObjects = objects_map.member
        self.villageMapObjects = objects_map.village
        self.decoratorMapObjects = objects_map.decorate
        if is_fully_update then
            self:NotifyListeneOnType(AllianceMap.LISTEN_TYPE.BUILDING, function(listener)
                if listener.OnBuildingFullUpdate then
                    listener:OnBuildingFullUpdate(self)
                end
            end)
        elseif is_delta_update then
            for i,v in ipairs(deltaData.mapObjects.add or {}) do
                setmetatable(v, mapObject_meta):SetAllianceMap(self)
            end
            for i,v in ipairs(deltaData.mapObjects.edit or {}) do
            -- todo
            end
            for i,v in ipairs(deltaData.mapObjects.remove or {}) do
                setmetatable(v, mapObject_meta):SetAllianceMap(self)
            end
            self:NotifyListeneOnType(AllianceMap.LISTEN_TYPE.BUILDING, function(listener)
                if listener.OnBuildingDeltaUpdate then
                    listener:OnBuildingDeltaUpdate(self, deltaData.mapObjects)
                end
            end)
        end
    end
end


return AllianceMap









