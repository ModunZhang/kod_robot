UtilsForTech = {}
local Localize = import(".Localize")
local UILib = import("..ui.UILib")

local building_map_tech = {
    trainingGround = _("步兵科技"),
    stable         = _("骑兵科技"),
    hunterHall     = _("弓手科技"),
    workshop       = _("攻城科技"),
}
function UtilsForTech:GetTechCategoryLocalize(tech)
    return building_map_tech[tech.building]
end
function UtilsForTech:GetProductionTechImage(tech_name)
    return UILib.produc_tiontechs_image[tech_name]
end
local tech_icon_map = {
	infantry= "tech_infantry_128x128.png",
	archer 	= 	"tech_archer_128x128.png",
	cavalry =  "tech_cavalry_128x128.png",
	siege 	= 	 "tech_siege_128x128.png",
	hpAdd 	= 		"tech_hp_128x128.png",
}
function UtilsForTech:GetMiliTechIcon(tech_name)
    local _,category = unpack(string.split(tech_name, "_"))
    return tech_icon_map[category]
end
local productionTechs = GameDatas.ProductionTechs.productionTechs
local militaryTechs = GameDatas.MilitaryTechs.militaryTechs
function UtilsForTech:GetTechLocalize(tech_name)
    if productionTechs[tech_name] then
        return Localize.productiontechnology_name[tech_name]
    end
    local category1,category2 = unpack(string.split(tech_name, "_"))
    if category2 == "hpAdd" then
        return string.format(_("%s血量增加"), Localize.soldier_category[category1])
    end
    return string.format(_("对%s的攻击"), Localize.soldier_category[category2])
end

function UtilsForTech:GetProductionTechConfig(tech_name)
    return productionTechs[tech_name]
end

local ProductionTechLevelUp = GameDatas.ProductionTechLevelUp
local MilitaryTechLevelUp = GameDatas.MilitaryTechLevelUp
function UtilsForTech:GetTechInfo(tech_name, level)
    local config = ProductionTechLevelUp[tech_name] or MilitaryTechLevelUp[tech_name]
    return level > #config and config[#config] or config[level]
end
function UtilsForTech:IsMaxLevel(tech_name, tech)
    return tech.level == self:MaxLevel(tech_name)
end
function UtilsForTech:MaxLevel(tech_name)
    local config = ProductionTechLevelUp[tech_name] or MilitaryTechLevelUp[tech_name]
    return #config
end
function UtilsForTech:GetTechPoint(tech_name, tech)
    return militaryTechs[tech_name].techPointPerLevel * tech.level
end
function UtilsForTech:GetNextLevelTechPoint(tech_name, tech)
    local next_level = self:IsMaxLevel(tech_name, tech) and tech.level or (tech.level + 1)
    return militaryTechs[tech_name].techPointPerLevel * next_level
end
function UtilsForTech:GetEffect(tech_name, tech)
    local config = productionTechs[tech_name] or militaryTechs[tech_name]
    return config.effectPerLevel * tech.level
end
function UtilsForTech:GetNextLevelEffect(tech_name, tech)
    local config = productionTechs[tech_name] or militaryTechs[tech_name]
    local next_level = self:IsMaxLevel(tech_name, tech) and tech.level or (tech.level + 1)
    return config.effectPerLevel * next_level
end


--如果是资源相关科技返回资源的类型 否则返回nil
local map_resource = {
    stoneCarving= {"stone"  ,"product"},
    forestation = {"wood"   ,"product"},
    ironSmelting= {"iron"   ,"product"},
    cropResearch= {"food"   ,"product"},
    fastFix     = {"wallHp" ,"product"},
    beerSupply  = {"citizen",  "limit"},
    mintedCoin  = {"coin"   ,"product"},
}
function UtilsForTech:GetResourceBuff(tech_name, tech)
    if map_resource[tech_name] then
        local resource_type,buff_type = unpack(map_resource[tech_name])
        
        return resource_type,buff_type,self:GetEffect(tech_name, tech)
    end
    return nil,nil,nil
end
function UtilsForTech:GetBuff(userData)
    local buff = {
        coin = 0,
        wood = 0,
        iron = 0,
        food = 0,
        stone= 0,
        wallHp = 0,
        citizen= 0,
    }
    for tech_name,tech in pairs(userData.productionTechs) do
        local res_type,buff_type,buff_value = self:GetResourceBuff(tech_name, tech)
        if buff_type == "product" then
            buff[res_type] = buff[res_type] + buff_value
        end
    end
    return setmetatable(buff, BUFF_META)
end
function UtilsForTech:GetLimitBuff(userData)
    local buff = {
        coin = 0,
        wood = 0,
        iron = 0,
        food = 0,
        stone= 0,
        wallHp = 0,
        citizen= 0,
    }
    for tech_name,tech in pairs(userData.productionTechs) do
        local res_type,buff_type,buff_value = self:GetResourceBuff(tech_name, tech)
        if buff_type == "limit" then
            buff[res_type] = buff[res_type] + buff_value
        end
    end
    return setmetatable(buff, BUFF_META)
end





