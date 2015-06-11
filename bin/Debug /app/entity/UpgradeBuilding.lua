
local Observer = import(".Observer")
local DataUtils = import("..utils.DataUtils")
local MaterialManager = import("..entity.MaterialManager")
local Building = import(".Building")
local UpgradeBuilding = class("UpgradeBuilding", Building)
local Localize = import("..utils.Localize")

local pairs = pairs
local ipairs = ipairs
local format = string.format


UpgradeBuilding.NOT_ABLE_TO_UPGRADE = {
    TILE_NOT_UNLOCKED = _("地块未解锁"),
    IS_MAX_LEVEL = _("建筑已经达到最高等级"),
    IS_MAX_UNLOCK = _("建造数量已达建造上限"),
    LEVEL_CAN_NOT_HIGHER_THAN_KEEP_LEVEL = _("请首先提升城堡等级"),
    RESOURCE_NOT_ENOUGH = _("资源不足"),
    BUILDINGLIST_NOT_ENOUGH = _("建造队列不足"),
    BUILDINGLIST_AND_RESOURCE_NOT_ENOUGH = _("资源不足.建造队列不足"),
    GEM_NOT_ENOUGH = _("金龙币不足"),
    LEVEL_NOT_ENOUGH = _("等级小于0级"),
    BUILDING_IS_UPGRADING = _("建筑正在升级"),
    FREE_CITIZEN_ERROR = _("城民上限不足,无法升级小屋,请升级或建造住宅"),
    PRE_CONDITION = _("前置建筑等级未满足"),
}
local NOT_ABLE_TO_UPGRADE = UpgradeBuilding.NOT_ABLE_TO_UPGRADE
function UpgradeBuilding:ctor(building_info)
    UpgradeBuilding.super.ctor(self, building_info)
    self.config_building_levelup = GameDatas.BuildingLevelUp
    self.config_building_function = GameDatas.BuildingFunction
    self.level = building_info.level and building_info.level or 1
    self.upgrade_to_next_level_time = (building_info.finishTime == nil) and 0 or building_info.finishTime
    self.upgrade_building_observer = Observer.new()
    self.unique_upgrading_key = nil
end
function UpgradeBuilding:GetRealEntity()
    return self
end
function UpgradeBuilding:IsAbleToFreeSpeedUpByTime(time)
    return self:GetFreeSpeedupTime() >= self:GetUpgradingLeftTimeByCurrentTime(time)
end
function UpgradeBuilding:GetFreeSpeedupTime()
    return DataUtils:getFreeSpeedUpLimitTime()
end
function UpgradeBuilding:EventType()
    return self:IsHouse() and "houseEvents" or "buildingEvents"
end
function UpgradeBuilding:UniqueUpgradingKey()
    return self.unique_upgrading_key
end
function UpgradeBuilding:ResetAllListeners()
    UpgradeBuilding.super.ResetAllListeners(self)
    self:GetUpgradeObserver():RemoveAllObserver()
end
-- function UpgradeBuilding:CopyListenerFrom(building)
--     UpgradeBuilding.super.CopyListenerFrom(self, building)
--     self.upgrade_building_observer:CopyListenerFrom(building:GetUpgradeObserver())
-- end
function UpgradeBuilding:AddUpgradeListener(listener)
    assert(listener.OnBuildingUpgradingBegin)
    assert(listener.OnBuildingUpgradeFinished)
    assert(listener.OnBuildingUpgrading)
    self.upgrade_building_observer:AddObserver(listener)
    return self
end
function UpgradeBuilding:RemoveUpgradeListener(listener)
    self.upgrade_building_observer:RemoveObserver(listener)
end
function UpgradeBuilding:GetUpgradeObserver()
    return self.upgrade_building_observer
end
function UpgradeBuilding:GetUpgradingLeftTimeByCurrentTime(current_time)
    local left_time = self.upgrade_to_next_level_time - current_time
    return left_time > 0 and left_time or 0
end
function UpgradeBuilding:GetUpgradingPercentByCurrentTime(current_time)
    if self:IsUpgrading() then
        local total = self:GetUpgradeTimeToNextLevel()
        return (1 - self:GetUpgradingLeftTimeByCurrentTime(current_time) / (total - DataUtils:getBuildingBuff(total))) * 100
    end
    return 0
end
function UpgradeBuilding:CanUpgrade()
    local legal = self:IsBuildingUpgradeLegal()
    return type(legal) == "nil"
end
function UpgradeBuilding:IsUnlocking()
    return self:GetLevel() == 0 and self.upgrade_to_next_level_time ~= 0
end
function UpgradeBuilding:IsBuilding()
    return self:GetLevel() == 0 and self.upgrade_to_next_level_time ~= 0
end
function UpgradeBuilding:IsUnlocked()
    return self:GetLevel() > 0
end
function UpgradeBuilding:IsUpgrading()
    return self.upgrade_to_next_level_time ~= 0
end
function UpgradeBuilding:InstantUpgradeBy(level)
    self:InstantUpgradeTo(self.level + level)
end
function UpgradeBuilding:InstantUpgradeTo(level)
    self.level = level
    self.upgrade_to_next_level_time = 0

    self:CancelLocalPush()
    self.upgrade_building_observer:NotifyObservers(function(listener)
        listener:OnBuildingUpgradeFinished(self)
    end)
end
function UpgradeBuilding:UpgradeByCurrentTime(current_time)
    self:GeneralLocalPush()
    self.upgrade_building_observer:NotifyObservers(function(listener)
        listener:OnBuildingUpgradingBegin(self, current_time)
    end)
end
function UpgradeBuilding:GetUpgradeTimeToNextLevel()
    return self:GetNextLevelUpgradeTimeByLevel(self.level)
end
function UpgradeBuilding:GetNextLevelUpgradeTimeByLevel(level)
    local config = self.config_building_levelup[self:GetType()]
    if config then
        local is_max_level = #config == level
        return is_max_level and 0 or config[level + 1].buildTime
    end
    return 1
end
function UpgradeBuilding:GetNextLevel()
    return self:IsMaxLevel() and self.level or self.level + 1
end
function UpgradeBuilding:IsMaxLevel()
    local config = self.config_building_levelup[self:GetType()]
    return #config == self.level
end
function UpgradeBuilding:GetBeforeLevel()
    if self.level > 0 then
        return self.level - 1
    else
        return 0
    end
end
function UpgradeBuilding:GetEfficiencyLevel()
    return self.level <= 0 and 1 or self.level
end
function UpgradeBuilding:GetLevel()
    return self.level
end

function UpgradeBuilding:GeneralLocalPush()
    -- local pushIdentity = self.x .. self.y .. self.w .. self.h .. self.orient
    -- local title = format(_("修建%s到LV%d完成"),Localize.getLocaliedKeyByType(self.building_type),(self.level+1))
    -- app:GetPushManager():UpdateBuildPush(self.upgrade_to_next_level_time,title,pushIdentity)
end
function UpgradeBuilding:CancelLocalPush()
    -- local pushIdentity = self.x .. self.y .. self.w .. self.h .. self.orient
    -- app:GetPushManager():CancelBuildPush(pushIdentity)
end
function UpgradeBuilding:IsNeedToUpdate()
    return self.upgrade_to_next_level_time ~= 0
end
function UpgradeBuilding:OnTimer(current_time)
    if self.upgrade_to_next_level_time >= current_time then
        self.upgrade_building_observer:NotifyObservers(function(listener)
            listener:OnBuildingUpgrading(self, current_time)
        end)
    end
end
function UpgradeBuilding:SpeedUpBuilding()
    if self:IsUpgrading() then
        self.upgrade_building_observer:NotifyObservers(function(listener)
            if listener.OnSpeedUpBuilding then
                listener:OnSpeedUpBuilding()
            end
        end)
    end
end
function UpgradeBuilding:OnUserDataChanged(userData, current_time, location_info, house_location_info, deltaData, event)
    local level, finished_time, type_
    if self:IsHouse() then
        level, finished_time = house_location_info.level, (event == nil and 0 or event.finishTime / 1000)
    else
        level, type_, finished_time = location_info.level, location_info.type, (event == nil and 0 or event.finishTime / 1000)
        if type_ ~= self.building_type then
            self.building_type = type_
            self.base_building_observer:NotifyObservers(function(listener)
                listener:OnTransformed(self)
            end)
        end
    end
    self:OnEvent(event)
    if level and finished_time then
        if display.getRunningScene().__cname ~= "MainScene" and level ~= self.level then
            GameGlobalUI:showTips(_("提示"),format(_("建造%s至%d级完成"),Localize.building_name[self:GetType()],level))
        end
        self:OnHandle(level, finished_time)
    end
end
function UpgradeBuilding:GetHouseInfoByEventAndLocation(user_data, event, location_info, sub_location_id)
    local level = self.level
    for _, v in pairs(location_info.houses) do
        if v.location == sub_location_id then
            level = v.level
            break
        end
    end
    return level, event == nil and 0 or event.finishTime / 1000
end
function UpgradeBuilding:OnEvent(event)
    if event then
        self.unique_upgrading_key = event.id
    else
        self.unique_upgrading_key = nil
    end
end
function UpgradeBuilding:OnHandle(level, finish_time)
    if self.level == level then
        if self.upgrade_to_next_level_time == 0 and finish_time ~= 0 then
            self.upgrade_to_next_level_time = finish_time
            local total = self:GetUpgradeTimeToNextLevel()
            self:UpgradeByCurrentTime(finish_time - total - DataUtils:getBuildingBuff(total))
        elseif self.upgrade_to_next_level_time ~= 0 and finish_time ~= 0 then
            if self.upgrade_to_next_level_time ~= finish_time then
                self:SpeedUpBuilding()
            end
            self.upgrade_to_next_level_time = finish_time
            self:GeneralLocalPush()
        elseif self.upgrade_to_next_level_time ~= 0 and finish_time == 0 then
            self:InstantUpgradeTo(level)
        end
    else
        if finish_time == 0 then
            self:InstantUpgradeTo(level)
        else
            self.level = level
            self.upgrade_to_next_level_time = finish_time
            self:GeneralLocalPush()
        end
    end
end
----
function UpgradeBuilding:GetFunctionConfig()
    return self.config_building_function
end
function UpgradeBuilding:GetNextLevelPower()
    return self.config_building_function[self:GetType()][self:GetNextLevel()].power
end
function UpgradeBuilding:GetPower()
    return self.config_building_function[self:GetType()][self:GetLevel()].power
end
function UpgradeBuilding:GetLevelUpWood()
    local level = self.level
    return self.config_building_levelup[self:GetType()][self:GetNextLevel()].wood
end

function UpgradeBuilding:GetLevelUpStone()
    local level = self.level
    return self.config_building_levelup[self:GetType()][self:GetNextLevel()].stone
end

function UpgradeBuilding:GetLevelUpIron()
    local level = self.level
    return self.config_building_levelup[self:GetType()][self:GetNextLevel()].iron
end
function UpgradeBuilding:GetLevelUpCitizen()
    local level = self.level
    local b_config = self.config_building_levelup[self:GetType()]
    if b_config[self:GetNextLevel()].citizen and b_config[self:GetLevel()].citizen then
        return b_config[self:GetNextLevel()].citizen - b_config[self:GetLevel()].citizen
    else
        return 0
    end
end
function UpgradeBuilding:GetLevelUpBlueprints()
    local level = self.level
    return self.config_building_levelup[self:GetType()][self:GetNextLevel()].blueprints
end

function UpgradeBuilding:GetLevelUpTools()
    local level = self.level
    return self.config_building_levelup[self:GetType()][self:GetNextLevel()].tools
end

function UpgradeBuilding:GetLevelUpTiles()
    local level = self.level
    return self.config_building_levelup[self:GetType()][self:GetNextLevel()].tiles
end

function UpgradeBuilding:GetLevelUpPulley()
    local level = self.level
    return self.config_building_levelup[self:GetType()][self:GetNextLevel()].pulley
end

function UpgradeBuilding:GetLevelUpBuildTime()
    local level = self.level
    return self.config_building_levelup[self:GetType()][self:GetNextLevel()].buildTime
end

-- 升级前置条件
function UpgradeBuilding:IsBuildingUpgradeLegal()
    local city =  self:BelongCity()
    local level = self.level

    --等级小于0级
    if level<0 then
        return UpgradeBuilding.NOT_ABLE_TO_UPGRADE.LEVEL_NOT_ENOUGH
    end
    --建筑正在升级
    if self:IsUpgrading() then
        return UpgradeBuilding.NOT_ABLE_TO_UPGRADE.BUILDING_IS_UPGRADING
    end
    local level_up_config = self.config_building_levelup[self:GetType()]

    if #level_up_config == level then
        return UpgradeBuilding.NOT_ABLE_TO_UPGRADE.IS_MAX_LEVEL
    end
    -- 是否达到建造上限
    if city:GetFirstBuildingByType("keep"):GetFreeUnlockPoint(city) < 1 and self.level==0 then
        return UpgradeBuilding.NOT_ABLE_TO_UPGRADE.IS_MAX_UNLOCK
    end
    local config
    if self:IsHouse() then
        config = GameDatas.Houses.houses[self:GetType()]
    else
        local location_id = city:GetLocationIdByBuildingType(self:GetType())
        config = GameDatas.Buildings.buildings[location_id]
    end
    -- 等级大于5级时有升级前置条件
    if self:GetLevel()>5 then
        local configParams = string.split(config.preCondition,"_")
        local preType = configParams[1]
        local preName = configParams[2]
        local preLevel = tonumber(configParams[3])
        local limit
        if preType == "building" then
            local find_buildings = city:GetBuildingByType(preName)
            for i,v in ipairs(find_buildings) do
                if v:GetLevel()>=self:GetLevel()+preLevel then
                    limit = true
                end
            end
        else
            city:IteratorDecoratorBuildingsByFunc(function (index,house)
                if house:GetType() == preName and house:GetLevel()>=self:GetLevel()+preLevel then
                    limit = true
                end
            end)
        end
        if not limit then
            return UpgradeBuilding.NOT_ABLE_TO_UPGRADE.PRE_CONDITION
        end
    end
end
-- 获取升级前置条件描述
function UpgradeBuilding:GetPreConditionDesc()
    local city =  self:BelongCity()
    local config
    if self:IsHouse(self) then
        config = GameDatas.Houses.houses[self:GetType()]
    else
        local location_id = city:GetLocationIdByBuildingType(self:GetType())
        config = GameDatas.Buildings.buildings[location_id]
    end
    local configParams = string.split(config.preCondition,"_")
    local preName = configParams[2]
    local preLevel = tonumber(configParams[3])
    return format(_("需要%s达到%d级"),Localize.building_name[preName],self:GetLevel()+preLevel)
end
-- 获取等级最高建筑的升级前置条件建筑
function UpgradeBuilding:GetPreConditionBuilding()
    local city =  self:BelongCity()
    local config
    if self:IsHouse() then
        config = GameDatas.Houses.houses[self:GetType()]
    else
        local location_id = city:GetLocationIdByBuildingType(self:GetType())
        config = GameDatas.Buildings.buildings[location_id]
    end
    local configParams = string.split(config.preCondition,"_")
    local preName = configParams[2]
    return city:PreconditionByBuildingType(preName) or city:GetRuinsNotBeenOccupied()[1] or preName
end
function UpgradeBuilding:IsAbleToUpgrade(isUpgradeNow)
    local city = self:BelongCity()

    local pre_limit = self:IsBuildingUpgradeLegal()
    if pre_limit then
        return pre_limit, true
    end

    local gem = city:GetUser():GetGemResource():GetValue()
    if isUpgradeNow then
        if gem<self:getUpgradeNowNeedGems() then
            return UpgradeBuilding.NOT_ABLE_TO_UPGRADE.GEM_NOT_ENOUGH
        end
        return
    end
    local m =city:GetMaterialManager():GetMaterialsByType(MaterialManager.MATERIAL_TYPE.BUILD)
    local config = self.config_building_levelup[self:GetType()]

    -- 升级所需资源不足
    local wood = city.resource_manager:GetWoodResource():GetResourceValueByCurrentTime(app.timer:GetServerTime())
    local iron = city.resource_manager:GetIronResource():GetResourceValueByCurrentTime(app.timer:GetServerTime())
    local stone = city.resource_manager:GetStoneResource():GetResourceValueByCurrentTime(app.timer:GetServerTime())
    local citizen = city.resource_manager:GetCitizenResource():GetNoneAllocatedByTime(app.timer:GetServerTime())
    local is_resource_enough = wood<config[self:GetNextLevel()].wood
        or stone<config[self:GetNextLevel()].stone
        or iron<config[self:GetNextLevel()].iron
        or (config[self:GetNextLevel()].citizen and config[self:GetLevel()].citizen and citizen<(config[self:GetNextLevel()].citizen-config[self:GetLevel()].citizen))
        or m.tiles<config[self:GetNextLevel()].tiles
        or m.tools<config[self:GetNextLevel()].tools
        or m.blueprints<config[self:GetNextLevel()].blueprints
        or m.pulley<config[self:GetNextLevel()].pulley
    local max = city.build_queue
    local current = max - #city:GetUpgradingBuildings()

    if is_resource_enough and current <= 0 then
        return UpgradeBuilding.NOT_ABLE_TO_UPGRADE.BUILDINGLIST_AND_RESOURCE_NOT_ENOUGH
    end
    if is_resource_enough then
        return UpgradeBuilding.NOT_ABLE_TO_UPGRADE.RESOURCE_NOT_ENOUGH
    end
    if current <= 0 then
        return UpgradeBuilding.NOT_ABLE_TO_UPGRADE.BUILDINGLIST_NOT_ENOUGH
    end
end

function UpgradeBuilding:getUpgradeNowNeedGems()

    local resource_config = DataUtils:getBuildingUpgradeRequired(self.building_type, self:GetNextLevel())
    local required_gems = 0
    required_gems = required_gems + DataUtils:buyResource(resource_config.resources, {})
    required_gems = required_gems + DataUtils:buyMaterial(resource_config.materials, {})
    required_gems = required_gems + DataUtils:getGemByTimeInterval(resource_config.buildTime)

    return required_gems
end

function UpgradeBuilding:getUpgradeRequiredGems()
    local city = self:BelongCity()
    local required_gems = 0
    local has_resourcce = {
        wood = city.resource_manager:GetWoodResource():GetResourceValueByCurrentTime(app.timer:GetServerTime()),
        iron = city.resource_manager:GetIronResource():GetResourceValueByCurrentTime(app.timer:GetServerTime()),
        stone = city.resource_manager:GetStoneResource():GetResourceValueByCurrentTime(app.timer:GetServerTime()),
        citizen = city.resource_manager:GetCitizenResource():GetNoneAllocatedByTime(app.timer:GetServerTime()),
    }

    local has_materials =city:GetMaterialManager():GetMaterialsByType(MaterialManager.MATERIAL_TYPE.BUILD)

    local resource_config = DataUtils:getBuildingUpgradeRequired(self.building_type, self:GetNextLevel())
    required_gems = required_gems + DataUtils:buyResource(resource_config.resources, has_resourcce)
    required_gems = required_gems + DataUtils:buyMaterial(resource_config.materials, has_materials)
    --当升级队列不足时，立即完成正在升级的建筑中所剩升级时间最少的建筑
    if #city:GetUpgradingBuildings()>0 then
        local min_time = math.huge
        for k,v in pairs(city:GetUpgradingBuildings()) do
            local left_time = v:GetUpgradingLeftTimeByCurrentTime(app.timer:GetServerTime())
            if left_time<min_time then
                min_time=left_time
                print("完成上个升级的建筑",v:GetType())
            end
        end
        print("完成上个升级事件的时间",min_time)
        required_gems = required_gems + DataUtils:getGemByTimeInterval(min_time)
    end

    return required_gems
end

return UpgradeBuilding


















