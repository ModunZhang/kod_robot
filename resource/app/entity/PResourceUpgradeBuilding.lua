
-- 包括锻造坊，锯木工坊，磨坊，石匠工坊
local config_function = GameDatas.BuildingFunction
local UpgradeBuilding = import(".UpgradeBuilding")
local PResourceUpgradeBuilding = class("PResourceUpgradeBuilding", UpgradeBuilding)

-- 大资源建造对应小屋
local p_resource_building_to_house = {
	["townHall"] = "dwelling",
	["foundry"] = "miner",
	["stoneMason"] = "quarrier",
	["lumbermill"] = "woodcutter",
	["mill"] = "farmer",
}

function PResourceUpgradeBuilding:ctor(building_info)
    PResourceUpgradeBuilding.super.ctor(self, building_info)
end
-- 获取下一级可以建造的最大小屋数量
function PResourceUpgradeBuilding:GetNextLevelMaxHouseNum()
    local level = self:GetNextLevel() < 0 and 0 or self:GetNextLevel()
    return config_function[self:GetType()][level].houseAdd
end
-- 获取对应资源下一级的保护
function PResourceUpgradeBuilding:GetNextLevelProtection()
	local level = self:GetNextLevel()
    return config_function[self:GetType()][level].protection
end
-- 获取当前等级可以建造的最大小屋数量
function PResourceUpgradeBuilding:GetMaxHouseNum()
	if self:GetLevel() > 0 then
    	return config_function[self:GetType()][self:GetEfficiencyLevel()].houseAdd
	end
	return 0
end
-- 获取对应资源的保护
function PResourceUpgradeBuilding:GetProtection()
	local level = self:GetLevel()
    return config_function[self:GetType()][level].protection or 0
end
-- 获取对应小屋类型
function PResourceUpgradeBuilding:GetHouseType()
    return p_resource_building_to_house[self:GetType()]
end
return PResourceUpgradeBuilding