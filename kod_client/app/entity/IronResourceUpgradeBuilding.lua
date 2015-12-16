--
-- Author: dannyhe
-- Date: 2014-08-12 21:18:40
--
local ResourceUpgradeBuilding = import(".ResourceUpgradeBuilding")
local IronResourceUpgradeBuilding = class("IronResourceUpgradeBuilding", ResourceUpgradeBuilding)

function IronResourceUpgradeBuilding:ctor(building_info)
    IronResourceUpgradeBuilding.super.ctor(self, building_info)
end
function IronResourceUpgradeBuilding:GetResType()
    return "iron"
end
--

return IronResourceUpgradeBuilding