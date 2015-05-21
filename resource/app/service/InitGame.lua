local BuildingRegister = import("..entity.BuildingRegister")
local City_ = import("..entity.City")
local AllianceManager_ = import("..entity.AllianceManager")
local User_ = import("..entity.User")
local MailManager_ = import("..entity.MailManager")
local ItemManager_ = import("..entity.ItemManager")
local check = import("..fte.check")
local initData = import("..fte.initData")

local app = app
local timer = app.timer
return function(userData)
    DataManager.user = userData
    timer:Clear()

    MailManager = MailManager_.new()
    ItemManager = ItemManager_.new()
    Alliance_Manager = AllianceManager_.new()
    if GLOBAL_FTE then
        User = User_.new(initData._id)
        City = City_.new(User):InitWithJsonData(initData)
        DataManager:setFteUserDeltaData()
    else
        User = User_.new(userData._id)
        City = City_.new(User):InitWithJsonData(userData)
        DataManager:setUserData(userData)
    end

    timer:AddListener(User)
    timer:AddListener(City)
    timer:AddListener(ItemManager)
    timer:AddListener(Alliance_Manager)
    timer:Start()


    if not GLOBAL_FTE then
        app:GetChatManager():FetchAllChatMessageFromServer()
    end

    if ext.gamecenter.isGameCenterEnabled() and not ext.gamecenter.isAuthenticated() then
         ext.gamecenter.authenticate(false)
    end
    if device.platform ~= 'mac' then
        app:getStore():updateTransactionStates()
    end
end

























