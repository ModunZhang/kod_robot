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
local soldiers_normal = GameDatas.Soldiers.normal
local soldiers_special = GameDatas.Soldiers.special
function UtilsForSoldier:IsSpecial(soldier_name)
	return soldiers_special[soldier_name]
end
function UtilsForSoldier:GetSoldierUpkeep(userData)
    local total = 0
    for soldier_name,count in pairs(userData.soldiers) do
        total = total + self:GetSoldierConfig(userData, soldier_name).consumeFoodPerHour * count
    end
    local soldiers = {}
    if userData.defenceTroop and userData.defenceTroop ~= json.null then
    	local defenceTroop = userData.defenceTroop or {}
    	soldiers = defenceTroop.soldiers or {}
    end
    for _,v in ipairs(soldiers) do
        total = total + self:GetSoldierConfig(userData, v.name).consumeFoodPerHour * v.count
    end
    -- item效果
    local itemBuff = 0
    local vipBuff = 0
    if UtilsForItem:IsItemEventActive(userData, "quarterMaster") then
        itemBuff = UtilsForItem:GetItemBuff("quarterMaster")
    end
    -- vip效果
    if UtilsForVip:IsVipActived(userData) then
        vipBuff = UtilsForVip:GetVipBuffByName(userData, "soldierConsumeSub")
    end

    total = math.ceil(total * (1 - itemBuff -vipBuff))
    return total 
end
function UtilsForSoldier:GetSoldierConfig(userData, soldier_name)
    return  self:IsSpecial(soldier_name)
        and soldiers_special[soldier_name]
         or soldiers_normal[soldier_name.."_"..self:SoldierStarByName(userData, soldier_name)]
end
function UtilsForSoldier:SoldierStarByName(userData, soldier_name)
    return  self:IsSpecial(soldier_name)
        and soldiers_special[soldier_name].star
         or userData.soldierStars[soldier_name] or 1
end
