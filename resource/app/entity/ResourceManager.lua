local Enum = import("..utils.Enum")
local Resource = import(".Resource")
local AutomaticUpdateResource = import(".AutomaticUpdateResource")
local PopulationAutomaticUpdateResource = import(".PopulationAutomaticUpdateResource")
local Observer = import(".Observer")
local ResourceManager = class("ResourceManager", Observer)

local intInit = GameDatas.PlayerInitData.intInit

ResourceManager.RESOURCE_BUFF_TYPE = Enum("PRODUCT","LIMIT")

ResourceManager.RESOURCE_TYPE = Enum(
    "BLOOD",
    "WOOD",
    "FOOD",
    "IRON",
    "STONE",
    "CART",
    "POPULATION",
    "COIN",
    "RUBY",             -- 红宝石
    "BERYL",            -- 绿宝石
    "SAPPHIRE",         -- 蓝宝石
    "TOPAZ",            -- 黄宝石
    "WALLHP",
    "CASINOTOKEN")              -- 玩家宝石

local ENERGY = ResourceManager.RESOURCE_TYPE.ENERGY
local WOOD = ResourceManager.RESOURCE_TYPE.WOOD
local FOOD = ResourceManager.RESOURCE_TYPE.FOOD
local IRON = ResourceManager.RESOURCE_TYPE.IRON
local STONE = ResourceManager.RESOURCE_TYPE.STONE
local CART = ResourceManager.RESOURCE_TYPE.CART
local POPULATION = ResourceManager.RESOURCE_TYPE.POPULATION
local COIN = ResourceManager.RESOURCE_TYPE.COIN
local BLOOD = ResourceManager.RESOURCE_TYPE.BLOOD
local CASINOTOKEN = ResourceManager.RESOURCE_TYPE.CASINOTOKEN
local WALLHP = ResourceManager.RESOURCE_TYPE.WALLHP

local RESOURCE_TYPE = ResourceManager.RESOURCE_TYPE
local dump_buffs = function(...)
    local t, name = ...
    dump(LuaUtils:table_map(t, function(k, v)
        return RESOURCE_TYPE[k], v
    end), name)
end

function ResourceManager:ctor()
    ResourceManager.super.ctor(self)
    self.resources = {
        [WOOD] = AutomaticUpdateResource.new(),
        [FOOD] = AutomaticUpdateResource.new(),
        [IRON] = AutomaticUpdateResource.new(),
        [STONE] = AutomaticUpdateResource.new(),
        [CART] = AutomaticUpdateResource.new(),
        [POPULATION] = PopulationAutomaticUpdateResource.new(),
        [COIN] = AutomaticUpdateResource.new(),
        [BLOOD] = Resource.new(),
        [WALLHP] = AutomaticUpdateResource.new(),
        [CASINOTOKEN] = Resource.new(),
    }
    self:GetCoinResource():SetValueLimit(math.huge)

    self.resource_citizen = {
        [WOOD] = 0,
        [FOOD] = 0,
        [IRON] = 0,
        [STONE] = 0,
        [POPULATION] = 0,
        [WALLHP] = 0,
    }
end
function ResourceManager:OnTimer(current_time)
    self:OnResourceChanged()
end
function ResourceManager:GetWallHpResource()
    return self.resources[WALLHP]
end
function ResourceManager:GetWoodResource()
    return self.resources[WOOD]
end
function ResourceManager:GetFoodResource()
    return self.resources[FOOD]
end
function ResourceManager:GetIronResource()
    return self.resources[IRON]
end
function ResourceManager:GetStoneResource()
    return self.resources[STONE]
end
function ResourceManager:GetCartResource()
    return self.resources[CART]
end
function ResourceManager:GetPopulationResource()
    return self.resources[POPULATION]
end
function ResourceManager:GetCoinResource()
    return self.resources[COIN]
end
function ResourceManager:GetBloodResource()
    return self.resources[BLOOD]
end
function ResourceManager:GetCasinoTokenResource()
    return self.resources[CASINOTOKEN]
end
function ResourceManager:GetResourceByType(RESOURCE_TYPE)
    return self.resources[RESOURCE_TYPE]
end
function ResourceManager:OnResourceChanged()
    self:NotifyObservers(function(listener)
        listener:OnResourceChanged(self)
    end)
end
--获取食物的生产量
function ResourceManager:GetFoodProductionPerHour()
    return City:GetSoldierManager():GetTotalUpkeep() + self:GetFoodResource():GetProductionPerHour()
end
function ResourceManager:UpdateByCity(city, current_time)
    -- 产量
    -- 资源小车
    local tradeGuild = city:GetFirstBuildingByType("tradeGuild")
    local cart_recovery, max_cart = 0, 0
    if tradeGuild:GetLevel() > 0 then
        cart_recovery = tradeGuild:GetCartRecovery()
        max_cart = tradeGuild:GetMaxCart()
    end

    -- 城墙
    local wallBuilding = city:GetGate()
    local wall_hp_production_per_hour = wallBuilding:GetWallConfig().wallRecovery

    local total_production_map = {
        [WOOD] = 0,
        [FOOD] = 0,
        [IRON] = 0,
        [STONE] = 0,
        [COIN] = 0,
        [POPULATION] = 0,
        [WALLHP] = wall_hp_production_per_hour or 0,
        [CART] = cart_recovery,
    }

    -- 上限
    local max_wood, max_food, max_iron, max_stone = city:GetFirstBuildingByType("warehouse"):GetResourceValueLimit()
    local wall_max_hp = wallBuilding:GetWallConfig().wallHp
    local total_limit_map = {
        [WOOD] = max_wood,
        [FOOD] = max_food,
        [IRON] = max_iron,
        [STONE] = max_stone,
        [COIN] = math.huge,
        [POPULATION] = intInit.initCitizen.value,
        [CART] = max_cart,
        [WALLHP] = wall_max_hp or 0,
    }

    local citizen_map = {
        [WOOD] = 0,
        [FOOD] = 0,
        [IRON] = 0,
        [STONE] = 0,
        [POPULATION] = 0,
        [WALLHP] = 0,
        [CART] = 0,
    }
    local total_citizen = 0
    --小屋对资源的影响
    city:IteratorDecoratorBuildingsByFunc(function(key, decorator)
        if iskindof(decorator, 'ResourceUpgradeBuilding') then
            local resource_type = decorator:GetUpdateResourceType()
            if resource_type then
                local citizen = decorator:GetCitizen()
                total_citizen = total_citizen + citizen
                total_production_map[resource_type] = total_production_map[resource_type] + decorator:GetProductionPerHour()
                if citizen_map[resource_type] then
                    citizen_map[resource_type] = citizen_map[resource_type] + citizen
                end
                if POPULATION == resource_type then
                    total_production_map[COIN] = total_production_map[COIN] + decorator:GetProductionPerHour()
                    total_limit_map[POPULATION] = total_limit_map[POPULATION] + decorator:GetProductionLimit()
                end
            end
        end
    end)
    -- buff对资源的影响
    local buff_production_map,buff_limt_map = self:GetTotalBuffData(city)
    self.resource_citizen = citizen_map
    self:GetPopulationResource():SetLowLimitResource(total_citizen)
    for resource_type, production in pairs(total_production_map) do
        local buff_limit = 1 + buff_limt_map[resource_type]
        local resource_limit = math.floor(total_limit_map[resource_type] * buff_limit)
        local resource = self.resources[resource_type]
        resource:SetValueLimit(resource_limit)

        local buff_production = 1 + buff_production_map[resource_type]
        if resource_type == POPULATION then
            local production = (resource_limit - resource:GetLowLimitResource()) / intInit.playerCitizenRecoverFullNeedHours.value
            resource:SetProductionPerHour(current_time, production * buff_production)
        else
            local resource_production = math.floor(production * buff_production)
            if resource_type == FOOD then
                resource_production = resource_production - city:GetSoldierManager():GetTotalUpkeep()
            end
            resource:SetProductionPerHour(current_time, resource_production)
        end
    end
end
function ResourceManager:GetCitizenAllocInfo()
    return self.resource_citizen
end
function ResourceManager:GetCitizenAllocated()
    local total_citizen = 0
    for k, v in pairs(self.resource_citizen) do
        total_citizen = total_citizen + v
    end
    return total_citizen
end
function ResourceManager:UpdateFromUserDataByTime(resources, current_time)
    local my_resources = self.resources
    my_resources[BLOOD]:SetValue(resources.blood)
    my_resources[CASINOTOKEN]:SetValue(resources.casinoToken)
    my_resources[COIN]:UpdateResource(current_time, resources.coin)
    my_resources[WOOD]:UpdateResource(current_time, resources.wood)
    my_resources[FOOD]:UpdateResource(current_time, resources.food)
    my_resources[IRON]:UpdateResource(current_time, resources.iron)
    my_resources[STONE]:UpdateResource(current_time, resources.stone)
    my_resources[CART]:UpdateResource(current_time, resources.cart)
    my_resources[POPULATION]:UpdateResource(current_time, resources.citizen)
    my_resources[WALLHP]:UpdateResource(current_time, resources.wallHp)
end
local resource_building_map = {
    mill = FOOD,
    lumbermill = WOOD,
    foundry = IRON,
    stoneMason = STONE,
    townHall = POPULATION,
}
function ResourceManager:GetTotalBuffData(city)
    local buff_production_map =
        {
            [WOOD] = 0,
            [FOOD] = 0,
            [IRON] = 0,
            [STONE] = 0,
            [COIN] = 0,
            [POPULATION] = 0,
            [WALLHP] = 0,
            [CART] = 0,
        }
    local buff_limt_map =
        {
            [WOOD] = 0,
            [FOOD] = 0,
            [IRON] = 0,
            [STONE] = 0,
            [COIN] = 0,
            [POPULATION] = 0,
            [WALLHP] = 0,
            [CART] = 0,
        }
    -- 建筑对资源的影响
    -- 以及小屋位置对资源的影响
    city:IteratorFunctionBuildingsByFunc(function(_,v)
        if v:IsUnlocked() then
            local resource_type = resource_building_map[v:GetType()]
            if resource_type then
                local count = #city:GetHousesAroundFunctionBuildingByType(v, v:GetHouseType(), 2)
                local house_buff = 0
                if count >= 6 then
                    house_buff = 0.1
                elseif count >= 3 then
                    house_buff = 0.05
                end
                buff_production_map[resource_type] = buff_production_map[resource_type] + house_buff
            end
        end
    end)
    dump_buffs(buff_production_map, "建筑对资源的影响--->")
    --学院科技
    local techs_buff_map = {
        [WOOD] = 0,
        [FOOD] = 0,
        [IRON] = 0,
        [STONE] = 0,
        [COIN] = 0,
        [POPULATION] = 0,
        [WALLHP] = 0,
        [CART] = 0,
    }
    city:IteratorTechs(function(__,tech)
        local resource_type,buff_type,buff_value = tech:GetResourceBuffData()
        if resource_type then
            local target_map = buff_type == self.RESOURCE_BUFF_TYPE.PRODUCT and buff_production_map or buff_limt_map
            target_map[resource_type] = target_map[resource_type] + buff_value
            techs_buff_map[resource_type] = techs_buff_map[resource_type] + buff_value
        end
    end)
    dump_buffs(techs_buff_map, "学院科技对资源的影响--->")
    --道具buuff
    local item_buff_map = {
        [WOOD] = 0,
        [FOOD] = 0,
        [IRON] = 0,
        [STONE] = 0,
        [COIN] = 0,
        [POPULATION] = 0,
        [WALLHP] = 0,
        [CART] = 0,
    }
    local item_buff = ItemManager:GetAllResourceBuffData()
    for _,v in ipairs(item_buff) do
        local resource_type,buff_type,buff_value = unpack(v)
        if resource_type  then
            local target_map = buff_type == self.RESOURCE_BUFF_TYPE.PRODUCT and buff_production_map or buff_limt_map
            if type(resource_type) == 'number' then
                target_map[resource_type] = target_map[resource_type] + buff_value
                item_buff_map[resource_type] = item_buff_map[resource_type] + buff_value
            elseif type(resource_type) == 'table' then
                for _,one_resource_type in ipairs(resource_type) do
                    target_map[one_resource_type] = target_map[one_resource_type] + buff_value
                    item_buff_map[one_resource_type] = item_buff_map[one_resource_type] + buff_value
                end
            end
        end
    end
    dump_buffs(item_buff_map, "道具对资源的影响--->")
    --vip buff
    local vip_buff_map = {
        [WOOD] = User:GetVIPWoodProductionAdd(),
        [FOOD] = User:GetVIPFoodProductionAdd(),
        [IRON] = User:GetVIPIronProductionAdd(),
        [STONE] = User:GetVIPStoneProductionAdd(),
        [POPULATION] = User:GetVIPCitizenRecoveryAdd(),
        [WALLHP] = User:GetVIPWallHpRecoveryAdd(),
        [COIN] = 0,
        [CART] = 0,
    }
    dump_buffs(vip_buff_map, "VIP对资源的影响--->")
    for resource_type,v in pairs(buff_production_map) do
        buff_production_map[resource_type] = v + vip_buff_map[resource_type]
    end
    --end
    dump_buffs(buff_production_map,"buff_production_map--->")
    dump_buffs(buff_limt_map,"buff_limt_map--->")
    return buff_production_map,buff_limt_map
end


return ResourceManager
















