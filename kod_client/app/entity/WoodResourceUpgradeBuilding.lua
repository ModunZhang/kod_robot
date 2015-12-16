local ResourceUpgradeBuilding = import(".ResourceUpgradeBuilding")
local WoodResourceUpgradeBuilding = class("WoodResourceUpgradeBuilding", ResourceUpgradeBuilding)

function WoodResourceUpgradeBuilding:ctor(building_info)
    WoodResourceUpgradeBuilding.super.ctor(self, building_info)
end
function WoodResourceUpgradeBuilding:GetResType()
    return "wood"
end

--

return WoodResourceUpgradeBuilding