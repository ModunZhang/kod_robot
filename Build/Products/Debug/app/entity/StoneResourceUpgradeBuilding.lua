--
-- Author: dannyhe
-- Date: 2014-08-12 21:18:57
--
local ResourceManager = import(".ResourceManager")
local ResourceUpgradeBuilding = import(".ResourceUpgradeBuilding")
local StoneResourceUpgradeBuilding = class("StoneResourceUpgradeBuilding", ResourceUpgradeBuilding)

function StoneResourceUpgradeBuilding:ctor(building_info)
    StoneResourceUpgradeBuilding.super.ctor(self, building_info)
end
function StoneResourceUpgradeBuilding:GetUpdateResourceType()
	return ResourceManager.RESOURCE_TYPE.STONE
end
--

return StoneResourceUpgradeBuilding