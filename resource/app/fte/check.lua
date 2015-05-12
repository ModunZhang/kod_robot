return function(key)
    if key == "ALL" then
        return DataManager:getUserData().basicInfo.power > 2000
    end
    local real_key = DataManager:getUserData()._id.."_"..key
    local has_key = cc.UserDefault:getInstance():getBoolForKey(real_key)
    print(string.format("%s.%40s : %s", DataManager:getUserData()._id, key, has_key and "true" or "false"))
    return has_key
end





