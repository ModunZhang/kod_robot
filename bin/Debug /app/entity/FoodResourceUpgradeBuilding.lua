--
-- Author: dannyhe
-- Date: 2014-08-12 21:07:01
--
local ResourceManager = import(".ResourceManager")
local ResourceUpgradeBuilding = import(".ResourceUpgradeBuilding")
local FoodResourceUpgradeBuilding = class("FoodResourceUpgradeBuilding", ResourceUpgradeBuilding)

function FoodResourceUpgradeBuilding:ctor(building_info)
    FoodResourceUpgradeBuilding.super.ctor(self, building_info)
end

function FoodResourceUpgradeBuilding:GetUpdateResourceType()
	return ResourceManager.RESOURCE_TYPE.FOOD
end
--

return FoodResourceUpgradeBuilding