UtilsForVip = {}



function UtilsForVip:GetVipFreeSpeedUpTime(userData)
	return self:GetVipBuffByName(userData, "freeSpeedup")
end
function UtilsForVip:GetVipBuff(userData)
	local config = self:GetVipConfig(userData)
    return setmetatable({
        coin = 0,
        wood = config.woodProductionAdd,
        food = config.foodProductionAdd,
        iron = config.ironProductionAdd,
        stone= config.stoneProductionAdd,
        wallHp = config.wallHpRecoveryAdd,
        citizen= config.citizenRecoveryAdd,
    }, BUFF_META)
end
function UtilsForVip:GetVipBuffByName(userData, name)
    return self:GetVipConfig(userData)[name]
end
local vip_level = GameDatas.Vip.level
function UtilsForVip:GetVipConfig(userData)
    return self:IsVipActived(userData) 
       and vip_level[self:GetVipLevel(userData)] 
        or vip_level[0]
end
function UtilsForVip:GetVipLevel(userData)
    return DataUtils:getPlayerVIPLevel(userData.basicInfo.vipExp)
end
function UtilsForVip:IsVipActived(userData)
    local vipEvent = userData.vipEvents[1]
    if vipEvent then
        local left = vipEvent.finishTime / 1000 - app.timer:GetServerTime()
        local isactive = left > 0
        return isactive, isactive and left or 0
    end
    return false, 0
end
