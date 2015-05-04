local BuildingRegister = import("..entity.BuildingRegister")
local City_ = import("..entity.City")
local AllianceManager_ = import("..entity.AllianceManager")
local User_ = import("..entity.User")
local MailManager_ = import("..entity.MailManager")
local ItemManager_ = import("..entity.ItemManager")

local app = app
local timer = app.timer
return function(userData)
    User = User_.new(userData._id)
    Alliance_Manager = AllianceManager_.new()
    MailManager = MailManager_.new()
    ItemManager = ItemManager_.new()
    City = City_.new(userData):SetUser(User)

    DataManager:setUserData(userData)

    timer:AddListener(User)
    timer:AddListener(City)
    timer:AddListener(ItemManager)
    timer:AddListener(Alliance_Manager)
    timer:Start()
    app:GetChatManager():FetchAllChatMessageFromServer()
    if ext.gamecenter.isGameCenterEnabled() and not ext.gamecenter.isAuthenticated() then
         ext.gamecenter.authenticate(false)
    end
    if device.platform ~= 'mac' then
        app:getStore():updateTransactionStates()
    end
end

























