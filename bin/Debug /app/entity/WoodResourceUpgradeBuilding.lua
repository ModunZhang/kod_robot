local ResourceManager = import(".ResourceManager")
local ResourceUpgradeBuilding = import(".ResourceUpgradeBuilding")
local WoodResourceUpgradeBuilding = class("WoodResourceUpgradeBuilding", ResourceUpgradeBuilding)

function WoodResourceUpgradeBuilding:ctor(building_info)
    WoodResourceUpgradeBuilding.super.ctor(self, building_info)
end
function WoodResourceUpgradeBuilding:GetUpdateResourceType()
	return ResourceManager.RESOURCE_TYPE.WOOD
end

--

return WoodResourceUpgradeBuilding