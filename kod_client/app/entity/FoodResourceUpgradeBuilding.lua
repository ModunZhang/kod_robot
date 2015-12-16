--
-- Author: dannyhe
-- Date: 2014-08-12 21:07:01
--
local ResourceUpgradeBuilding = import(".ResourceUpgradeBuilding")
local FoodResourceUpgradeBuilding = class("FoodResourceUpgradeBuilding", ResourceUpgradeBuilding)

function FoodResourceUpgradeBuilding:ctor(building_info)
    FoodResourceUpgradeBuilding.super.ctor(self, building_info)
end
function FoodResourceUpgradeBuilding:GetResType()
    return "food"
end
--

return FoodResourceUpgradeBuilding