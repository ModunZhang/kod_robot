--
-- Author: Danny He
-- Date: 2015-01-15 20:06:17
--
local config_productiontechlevelup = GameDatas.ProductionTechLevelUp
local ProductionTechnology = class("ProductionTechnology")
local property = import("..utils.property")
local productionTechs = GameDatas.ProductionTechs.productionTechs
local Localize = import("..utils.Localize")
local ResourceManager = import(".ResourceManager")
local UILib = import("..ui.UILib")

local unpack = unpack

property(ProductionTechnology,"index","")
property(ProductionTechnology,"level","")
property(ProductionTechnology,"name","")
property(ProductionTechnology,"unlockBy","")
property(ProductionTechnology,"unlockLevel","")
property(ProductionTechnology,"effectPerLevel","")
property(ProductionTechnology,"enable",true)
property(ProductionTechnology,"academyLevel",0)
function ProductionTechnology:ctor()
end

function ProductionTechnology:UpdateData(name,json_data)
    self:SetName(name or "")
    self:SetIndex(json_data.index or 0)
    self:SetLevel(json_data.level or 0)
    local tech = productionTechs[self:Name()]
    self:SetUnlockBy(tech.unlockBy)
    self:SetUnlockLevel(tech.unlockLevel)
    self:SetEffectPerLevel(tech.effectPerLevel)
    self:SetAcademyLevel(tech.academyLevel)
end

function ProductionTechnology:OnPropertyChange()
end

function ProductionTechnology:GetLevelUpCost()
    if config_productiontechlevelup[self:Name()] and config_productiontechlevelup[self:Name()][self:GetNextLevel()] then
        return config_productiontechlevelup[self:Name()][self:GetNextLevel()]
    end
    return nil
end

function ProductionTechnology:GetNextLevelUpCost()
    if config_productiontechlevelup[self:Name()] and config_productiontechlevelup[self:Name()][self:GetNextLevel() + 1] then
        return config_productiontechlevelup[self:Name()][self:GetNextLevel() + 1]
    end
    return nil
end

function ProductionTechnology:GetNextLevel()
    if self:Level() < self:MaxLevel() then
        return self:Level() + 1
    else
        return self:MaxLevel()
    end
end

function ProductionTechnology:GetImageName()
    return UILib.produc_tiontechs_image[self:Name()]
end

function ProductionTechnology:GetLocalizedName()
    return Localize.productiontechnology_name[self:Name()] or ""
end

function ProductionTechnology:GetBuffLocalizedDesc()
    return Localize.productiontechnology_buffer[self:Name()] or ""
end

function ProductionTechnology:GetBuffEffectVal()
    return self:Level() * self:EffectPerLevel()
end
function ProductionTechnology:GetNextLevelBuffEffectVal()
    if self:GetNextLevel() then
        return self:GetNextLevel() * self:EffectPerLevel()
    end
end
function ProductionTechnology:IsReachLimitLevel()
    return self:Level() >= self:MaxLevel()
end

function ProductionTechnology:MaxLevel()
    return #config_productiontechlevelup[self:Name()]
end

function ProductionTechnology:GetCurrentLevelPower()
    local config = config_productiontechlevelup[self:Name()]
    if config and config[self:Level()] then
        return config[self:Level()].power
    end
    return 0
end

function ProductionTechnology:GetNextLevelPower()
    if self:GetNextLevel() then
        local config = config_productiontechlevelup[self:Name()]
        if config and config[self:GetNextLevel()] then
            return config[self:GetNextLevel()].power
        end
    end
    return 0
end
--是否开放
function ProductionTechnology:IsOpen()
    return self:Index() < 10
end
--如果是资源相关科技返回资源的类型 否则返回nil
local RESOURCE_TYPE = ResourceManager.RESOURCE_TYPE
local RESOURCE_BUFF_TYPE = ResourceManager.RESOURCE_BUFF_TYPE
local map_resource = {
    stoneCarving = {RESOURCE_TYPE.STONE,RESOURCE_BUFF_TYPE.PRODUCT},
    forestation = {RESOURCE_TYPE.WOOD,RESOURCE_BUFF_TYPE.PRODUCT},
    ironSmelting = {RESOURCE_TYPE.IRON,RESOURCE_BUFF_TYPE.PRODUCT},
    cropResearch = {RESOURCE_TYPE.FOOD,RESOURCE_BUFF_TYPE.PRODUCT},
    fastFix = {RESOURCE_TYPE.WALLHP,RESOURCE_BUFF_TYPE.PRODUCT},
    beerSupply = {RESOURCE_TYPE.CITIZEN,RESOURCE_BUFF_TYPE.LIMIT},
}
function ProductionTechnology:GetResourceBuffData()
    if map_resource[self:Name()] then
        local resource_type,buff_type = unpack(map_resource[self:Name()])
        return resource_type,buff_type,self:GetBuffEffectVal()
    end
    return nil,nil,nil
end

return ProductionTechnology

