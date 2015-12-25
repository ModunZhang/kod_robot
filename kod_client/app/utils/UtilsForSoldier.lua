UtilsForSoldier = {
	soldierStarMax = 3,
}



local soldier_belong_building = {
	swordsman_1 	= "trainingGround",
	swordsman_2 	= "trainingGround",
	swordsman_3 	= "trainingGround",
	sentinel_1 		= "trainingGround",
	sentinel_2 		= "trainingGround",
	sentinel_3 		= "trainingGround",
	lancer_1 		= "stable",
	lancer_2 		= "stable",
	lancer_3 		= "stable",
	horseArcher_1 	= "stable",
	horseArcher_2 	= "stable",
	horseArcher_3 	= "stable",
	ranger_1 		= "hunterHall",
	ranger_2 		= "hunterHall",
	ranger_3 		= "hunterHall",
	crossbowman_1	= "hunterHall",
	crossbowman_2   = "hunterHall",
	crossbowman_3   = "hunterHall",
	catapult_1	 	= "workshop",
	catapult_2	 	= "workshop",
	catapult_3	 	= "workshop",
	ballista_1	 	= "workshop",
	ballista_2	 	= "workshop",
	ballista_3	 	= "workshop",
}
function UtilsForSoldier:SoldierBelongBuilding(soldier_name)
	return soldier_belong_building[soldier_name]
end
local soldiers_special = GameDatas.Soldiers.special
function UtilsForSoldier:IsSpecial(soldier_name)
	return soldiers_special[soldier_name]
end

