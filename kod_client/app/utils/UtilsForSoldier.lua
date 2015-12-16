UtilsForSoldier = {
	soldierStarMax = 3,
}



local soldier_belong_building = {
	swordsman 	= "trainingGround",
	sentinel 	= "trainingGround",
	lancer 		= "stable",
	horseArcher = "stable",
	ranger 		= "hunterHall",
	crossbowman = "hunterHall",
	catapult 	= "workshop",
	ballista 	= "workshop",
}
function UtilsForSoldier:SoldierBelongBuilding(soldier_name)
	return soldier_belong_building[soldier_name]
end
local soldiers_special = GameDatas.Soldiers.special
function UtilsForSoldier:IsSpecial(soldier_name)
	return soldiers_special[soldier_name]
end

