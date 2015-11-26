DataManager = {}
local initData = import("..fte.initData")
function DataManager:setUserData( userData, deltaData )
    self.user = userData
    if not GLOBAL_FTE then
        LuaUtils:TimeCollect(function()
            self:OnUserDataChanged(self.user, app.timer:GetServerTime(), deltaData)
        end, "DataManager:setUserData")
    end
end
function DataManager:setUserAllianceData(allianceData,deltaData)
    self.allianceData = allianceData
    if GLOBAL_FTE then return end
    if allianceData == json.null then return end
    if not Alliance_Manager then
        print(debug.traceback("", 2))
        assert(false)
    end
    LuaUtils:TimeCollect(function()
        Alliance_Manager:OnAllianceDataChanged(allianceData,app.timer:GetServerTime(),deltaData)
    end, "DataManager:setUserAllianceData")
end
function DataManager:getUserAllianceData()
    return self.allianceData
end

function DataManager:getUserData()
    return self.user
end
function DataManager:hasUserData()
    return type(self.user) == "table"
end

function DataManager:setFteUserDeltaData(deltaData)
    if GLOBAL_FTE then
        LuaUtils:TimeCollect(function()
            self:OnUserDataChanged(self:getFteData(), app.timer:GetServerTime(), deltaData)
        end, "DataManager:setFteUserDeltaData")
    end
end
function DataManager:getFteData()
    return initData
end

function DataManager:OnUserDataChanged(userData, timer, deltaData)
    -- 用于客户端报错，上传GM平台分析错误
    self.latestUserData = userData
    self.latestDeltaData = deltaData
    if not User or not City or not Alliance_Manager or not MailManager then
        print(debug.traceback("", 2))
        assert(false)
    end
    -- 代国强 ， 收到全数据推送时，关闭所有需要关闭的UI，避免UI表现和真实数据不一致，引起bug
    if deltaData == nil then
        UIKit:closeAllUI()
    end
    LuaUtils:TimeCollect(function()
        User:OnUserDataChanged(userData, deltaData)
        if not deltaData then
            User:RefreshOutput()
            User:GeneralLocalPush()
        end
    end, "User:OnUserDataChanged")

    LuaUtils:TimeCollect(function()
        City:OnUserDataChanged(userData, timer, deltaData)
    end, "City:OnUserDataChanged")
    
    User:OnDeltaDataChanged(deltaData)

    LuaUtils:TimeCollect(function()
        Alliance_Manager:OnUserDataChanged(userData, timer, deltaData)
    end, "Alliance_Manager:OnUserDataChanged")
    
    LuaUtils:TimeCollect(function()
        MailManager:OnUserDataChanged(userData, timer, deltaData)
    end, "MailManager:OnUserDataChanged")

    if userData and not deltaData then
        local scene_name = display.getRunningScene().__cname
        if scene_name == "MyCityScene" then
            app:EnterMyCityScene()
        end
    end
end




