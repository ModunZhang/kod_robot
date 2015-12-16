local BuildingRegister = import("..entity.BuildingRegister")
local City_ = import("..entity.City")
local User_ = import("..entity.User")
local MailManager_ = import("..entity.MailManager")
local check = import("..fte.check")
local initData = import("..fte.initData")

local app = app
local timer = app.timer
return function(userData)
    DataManager.user = userData
    timer:Clear()
    MailManager = MailManager_.new()
    if GLOBAL_FTE or userData.basicInfo.terrain == "__NONE__" then
        local fteData = DataManager:getFteData()
        fteData._id                = userData._id
        fteData.serverId           = userData.serverId
        fteData.serverTime         = userData.serverTime
        fteData.logicServerId      = userData.logicServerId
        fteData.basicInfo.name     = userData.basicInfo.name
        fteData.basicInfo.terrain  = userData.basicInfo.terrain
        fteData.basicInfo.language = userData.basicInfo.language
        User = User_.new(initData._id)
        City = City_.new(User):InitWithJsonData(initData)
        DataManager:setFteUserDeltaData()
    else
        User = User_.new(userData._id)
        City = City_.new(User):InitWithJsonData(userData)
        DataManager:setUserData(userData)
    end

    timer:AddListener(City)
    timer:Start()
end

























