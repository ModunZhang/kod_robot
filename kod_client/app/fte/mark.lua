return function(key)
    local user_default = cc.UserDefault:getInstance()
    user_default:setBoolForKey(DataManager:getUserData()._id.."_"..key, true)
    user_default:flush()
    print("mark", DataManager:getUserData()._id..key)
end





