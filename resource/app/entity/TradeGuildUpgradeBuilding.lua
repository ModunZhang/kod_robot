--
-- Author: Kenny Dai
-- Date: 2015-01-12 16:41:03
--


local config_function = GameDatas.BuildingFunction.tradeGuild
local config_levelup = GameDatas.BuildingLevelUp.tradeGuild
local UpgradeBuilding = import(".UpgradeBuilding")
local TradeGuildUpgradeBuilding = class("TradeGuildUpgradeBuilding", UpgradeBuilding)

function TradeGuildUpgradeBuilding:ctor(building_info)
    TradeGuildUpgradeBuilding.super.ctor(self, building_info)
end

function TradeGuildUpgradeBuilding:GetMaxCart()
    local User = self:BelongCity():GetUser()
    local tech = User.productionTechs["logistics"]
    local tech_effect = UtilsForTech:GetEffect("logistics", tech)
	if tech.level > 0 then
        return math.ceil(config_function[self:GetEfficiencyLevel()].maxCart * (1 + tech_effect))
    end
    return 0
end
function TradeGuildUpgradeBuilding:GetMaxSellQueue()
	if self:GetLevel() > 0 then
		return config_function[self:GetEfficiencyLevel()].maxSellQueue
    end
    return 0
end
function TradeGuildUpgradeBuilding:GetCartRecovery()
	if self:GetLevel() > 0 then
		return config_function[self:GetEfficiencyLevel()].cartRecovery
    end
    return 0
end
function TradeGuildUpgradeBuilding:GetNextLevelMaxCart()
    if self:GetNextLevel() > 0 then
        return config_function[self:GetNextLevel()].maxCart
    end
    return 0
end
function TradeGuildUpgradeBuilding:GetNextLevelCartRecovery()
    if self:GetNextLevel() > 0 then
        return config_function[self:GetNextLevel()].cartRecovery
    end
    return 0
end
function TradeGuildUpgradeBuilding:GetUnlockSellQueueLevel(queueIndex)
    for k,v in pairs(config_function) do
        if v.maxSellQueue==queueIndex then
            return k
        end
    end
end

return TradeGuildUpgradeBuilding

