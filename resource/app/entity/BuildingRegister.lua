local UpgradeBuilding = import("..entity.UpgradeBuilding")
local BuildingRegister = {
    woodcutter 		= import("..entity.ResourceUpgradeBuilding"),
    farmer 			= import("..entity.ResourceUpgradeBuilding"),
    miner 			= import("..entity.ResourceUpgradeBuilding"),
    quarrier 		= import("..entity.ResourceUpgradeBuilding"),
    dwelling 		= import("..entity.ResourceUpgradeBuilding"),
    dragonEyrie     = import("..entity.DragonEyrieUpgradeBuilding"),
}
setmetatable(BuildingRegister, {__index = function(t, k)
	return UpgradeBuilding
end})   
return BuildingRegister