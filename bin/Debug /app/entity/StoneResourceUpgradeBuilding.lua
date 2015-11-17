--
-- Author: dannyhe
-- Date: 2014-08-12 21:18:57
--
local ResourceUpgradeBuilding = import(".ResourceUpgradeBuilding")
local StoneResourceUpgradeBuilding = class("StoneResourceUpgradeBuilding", ResourceUpgradeBuilding)

function StoneResourceUpgradeBuilding:ctor(building_info)
    StoneResourceUpgradeBuilding.super.ctor(self, building_info)
end
function StoneResourceUpgradeBuilding:GetResType()
    return "stone"
end
--

return StoneResourceUpgradeBuilding