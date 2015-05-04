--
-- Author: Kenny Dai
-- Date: 2015-01-20 10:00:47
--

local property = import("..utils.property")
local Localize = import("..utils.Localize")
local MaterialManager = import("..entity.MaterialManager")
local MilitaryTechnology = class("MilitaryTechnology")

local military_config = GameDatas.MilitaryTechs.militaryTechs
local upgrade_config = GameDatas.MilitaryTechLevelUp
-- 建筑名map对应科技
local building_map_tech = {
    trainingGround = _("步兵科技"),
    stable         = _("骑兵科技"),
    hunterHall     = _("弓手科技"),
    workshop       = _("攻城科技"),
}

function MilitaryTechnology:ctor()
    property(self,"name","")
    property(self,"building","")
    property(self,"level","")
end

function MilitaryTechnology:UpdateData(name,json_data)
    self:SetName(name or "")
    self:SetBuilding(json_data.building or self.building or "")
    self:SetLevel(json_data.level or 0)
end

function MilitaryTechnology:OnPropertyChange()
end
-- 获取攻击加成
function MilitaryTechnology:GetAtkEff()
    return military_config[self.name].effectPerLevel * self:Level()
end
-- 获取增加科技点
function MilitaryTechnology:GetTechPoint()
    return military_config[self.name].techPointPerLevel * self:Level()
end
-- 获取下一级攻击加成
function MilitaryTechnology:GetNextLevlAtkEff()
    local next_level = self:IsMaxLevel() and self:Level() or (self:Level()+1)
    return military_config[self.name].effectPerLevel * next_level
end
-- 获取下一级增加科技点
function MilitaryTechnology:GetNextLevlTechPoint()
    local next_level = self:IsMaxLevel() and self:Level() or (self:Level()+1)
    return military_config[self.name].techPointPerLevel * next_level
end
-- 获取技能本地化
function MilitaryTechnology:GetTechLocalize()
    local soldiers = string.split(self:Name(), "_")
    local soldier_category = Localize.soldier_category
    if soldiers[2] == "hpAdd" then
        return string.format(_("%s血量增加"),soldier_category[soldiers[1]])
    end
    return string.format(_("%s对%s的攻击"),soldier_category[soldiers[1]],soldier_category[soldiers[2]])
end
-- 获取技能类别
function MilitaryTechnology:GetTechCategory()
    return building_map_tech[self:Building()]
end
-- 升级条件配置
function MilitaryTechnology:GetLevelUpConfig()
    return upgrade_config[self.name][self.level+1]
end
-- 升级时间
function MilitaryTechnology:GetUpgradeTime()
    return upgrade_config[self.name][self.level+1].buildTime
end
-- 是否达到最大等级
function MilitaryTechnology:IsMaxLevel()
    return self.level == #upgrade_config[self.name]
end
-- 获取立即升级需要金龙币
function MilitaryTechnology:GetInstantUpgradeGems()
    local config = self:GetLevelUpConfig()
    local required = {
        resources={
            coin=config.coin,
        },
        materials={
            trainingFigure=config.trainingFigure,
            bowTarget=config.bowTarget,
            saddle=config.saddle,
            ironPart=config.ironPart
        },
        buildTime=config.buildTime
    }
    return DataUtils:buyResource(required.resources, {}) + DataUtils:buyMaterial(required.materials, {}) + DataUtils:getGemByTimeInterval(required.buildTime)
end
-- 获取普通升级需要金龙币
function MilitaryTechnology:GetUpgradeGems()
    local config = self:GetLevelUpConfig()
    local required = {
        resources={
            coin=config.coin,
        },
        materials={
            trainingFigure=config.trainingFigure,
            bowTarget=config.bowTarget,
            saddle=config.saddle,
            ironPart=config.ironPart
        },
    }

    local has_materials = City:GetMaterialManager():GetMaterialsByType(MaterialManager.MATERIAL_TYPE.TECHNOLOGY)

    local has = {
        resources={
            coin=City:GetResourceManager():GetCoinResource():GetResourceValueByCurrentTime(app.timer:GetServerTime()),
        },
        materials={
            trainingFigure=has_materials.trainingFigure,
            bowTarget=has_materials.bowTarget,
            saddle=has_materials.saddle,
            ironPart=has_materials.ironPart
        },
    }
    -- 正在升级的军事科技剩余升级时间
    local left_time = City:GetSoldierManager():GetUpgradingMitiTaryTechLeftTimeByCurrentTime(self.building)
    return DataUtils:buyResource(required.resources, has.resources) + DataUtils:buyMaterial(required.materials, has.materials) + DataUtils:getGemByTimeInterval(left_time)
end
function MilitaryTechnology:IsAbleToUpgradeNow()
    local current_gem = User:GetGemResource():GetValue()
    return self:GetInstantUpgradeGems() >= current_gem
end
function MilitaryTechnology:IsAbleToUpgrade()
    local level_up_config = self:GetLevelUpConfig()
    local has_materials = City:GetMaterialManager():GetMaterialsByType(MaterialManager.MATERIAL_TYPE.TECHNOLOGY)
    local current_coin = City:GetResourceManager():GetCoinResource():GetResourceValueByCurrentTime(app.timer:GetServerTime())

    local results = {}
    if City:GetSoldierManager():IsUpgradingMilitaryTech(self.building) then
        table.insert(results, _("升级军事科技队列占用"))
    end
    if current_coin<level_up_config.coin then
        table.insert(results, _("银币不足").." ".._("需要补充")..(level_up_config.coin-current_coin))
    end
    if has_materials.trainingFigure<level_up_config.trainingFigure then
        table.insert(results, Localize.sell_type.trainingFigure.._("不足").." ".._("需要补充")..(level_up_config.trainingFigure-has_materials.trainingFigure))
    end
    if has_materials.bowTarget<level_up_config.bowTarget then
        table.insert(results, Localize.sell_type.bowTarget.._("不足").." ".._("需要补充")..(level_up_config.bowTarget-has_materials.bowTarget))
    end
    if has_materials.saddle<level_up_config.saddle then
        table.insert(results, Localize.sell_type.saddle.._("不足").." ".._("需要补充")..(level_up_config.saddle-has_materials.saddle))
    end
    if has_materials.ironPart<level_up_config.ironPart then
        table.insert(results, Localize.sell_type.ironPart.._("不足").." ".._("需要补充")..(level_up_config.ironPart-has_materials.ironPart))
    end

    return results
end

return MilitaryTechnology


