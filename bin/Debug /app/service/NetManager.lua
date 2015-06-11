local promise = import("..utils.promise")
local GameGlobalUIUtils = import("..ui.GameGlobalUIUtils")
local Localize_item = import("..utils.Localize_item")
local Localize = import("..utils.Localize")
local decodeInUserDataFromDeltaData = import("..utils.DiffFunction")
local cocos_promise = import("..utils.cocos_promise")

local SUCCESS_CODE = 200
local FAILED_CODE = 500
local TIME_OUT = 15


NetManager = {}
-- 过滤器
local function get_player_response_msg(response)
    if response.msg.playerData then
        local user_data = DataManager:getUserData()
        local edit = decodeInUserDataFromDeltaData(user_data, response.msg.playerData)
        LuaUtils:outputTable("get_player_response_msg edit",edit)
        DataManager:setUserData(user_data, edit)
        return response
    end

    return response
end
local function get_response_mail_msg(response)
    if response.msg.playerData then
        local user_data = DataManager:getUserData()
        local mail_response = response.msg.playerData
        for i,v in ipairs(mail_response) do
            if type(v) == "table" then
                local keys = string.split(v[1], ".")
                local newKey = ""
                local len = #keys
                local is_changed_saved_mails = false
                for i=1,len do
                    local k = tonumber(keys[i]) or keys[i]
                    if type(k) == "number" then
                        local client_index
                        local mail_index = MailManager:GetMailByServerIndex(k)
                        if not mail_index then
                            is_changed_saved_mails = true
                            client_index = MailManager:GetSavedMailByServerIndex(k) - 1
                        else
                            client_index = mail_index - 1
                        end
                        newKey = newKey..client_index..(i~=len and "." or "")
                    else
                        newKey = newKey..keys[i]..(i~=len and "." or "")
                    end
                end
                if is_changed_saved_mails then
                    local split = string.split(newKey, ".")
                    local key = "savedMails."
                    for i=2,#split do
                        key = key..split[i]..(i~=#split and "." or "")
                    end
                    v[1] = key
                else
                    v[1] = newKey
                end
            end
        end
        local edit = decodeInUserDataFromDeltaData(user_data, response.msg.playerData)
        DataManager:setUserData(user_data, edit)
    end

    return response
end
local function get_response_delete_mail_msg(response)
    if response.msg.playerData then
        local user_data = DataManager:getUserData()
        local mail_response = response.msg.playerData
        for i,v in ipairs(mail_response) do
            if type(v) == "table" then
                local keys = string.split(v[1], ".")
                local newKey = ""
                local len = #keys
                for i=1,len do
                    local k = tonumber(keys[i]) or keys[i]
                    if type(k) == "number" then
                        local client_index = MailManager:GetMailByServerIndex(k) - 1
                        newKey = newKey..client_index..(i~=len and "." or "")
                    else
                        newKey = newKey..keys[i]..(i~=len and "." or "")
                    end
                end

                v[1] = newKey
                local clone_response = clone(response)
                clone_response.msg.playerData = {}
                table.insert(clone_response.msg.playerData, v)
                local edit = decodeInUserDataFromDeltaData(user_data, clone_response.msg.playerData)
                DataManager:setUserData(user_data, edit)
            end
        end
    end

    return response
end

local function get_response_report_msg(response)
    if response.msg.playerData then
        local user_data = DataManager:getUserData()
        local report_response = response.msg.playerData
        for i,v in ipairs(report_response) do
            if type(v) == "table" then
                local keys = string.split(v[1], ".")
                local newKey = ""
                local len = #keys
                local is_saved_report = false
                for i=1,len do
                    local k = tonumber(keys[i]) or keys[i]
                    if type(k) == "number" then
                        local client_index
                        local report_index = MailManager:GetReportByServerIndex(k)
                        if report_index then
                            client_index = report_index - 1
                        else
                            is_saved_report = true
                            client_index = MailManager:GetSavedReportByServerIndex(k) - 1
                        end
                        newKey = newKey..client_index..(i~=len and "." or "")
                    else
                        newKey = newKey..keys[i]..(i~=len and "." or "")
                    end
                end
                if is_saved_report then
                    local split = string.split(newKey, ".")
                    local key = "savedReports."
                    for i=2,#split do
                        key = key..split[i]..(i~=#split and "." or "")
                    end
                    v[1] = key
                else
                    v[1] = newKey
                end
            end
        end
        local edit = decodeInUserDataFromDeltaData(user_data, response.msg.playerData)
        DataManager:setUserData(user_data, edit)
    end

    return response
end
local function get_response_delete_report_msg(response)
    if response.msg.playerData then
        local user_data = DataManager:getUserData()
        local report_response = response.msg.playerData
        for i,v in ipairs(report_response) do
            if type(v) == "table" then
                local keys = string.split(v[1], ".")
                local newKey = ""
                local len = #keys
                for i=1,len do
                    local k = tonumber(keys[i]) or keys[i]
                    if type(k) == "number" then
                        local client_index = MailManager:GetReportByServerIndex(k) - 1
                        newKey = newKey..client_index..(i~=len and "." or "")
                    else
                        newKey = newKey..keys[i]..(i~=len and "." or "")
                    end
                end
                v[1] = newKey
                local clone_response = clone(response)
                clone_response.msg.playerData = {}
                table.insert(clone_response.msg.playerData, v)
                local edit = decodeInUserDataFromDeltaData(user_data, clone_response.msg.playerData)
                DataManager:setUserData(user_data, edit)
            end
        end
    end

    return response
end
-- 只更新市政厅每日任务
local function get_daily_quests_response_msg(response)
    LuaUtils:outputTable("response", response)
    if response.msg.playerData then
        DataManager:getUserData().dailyQuests = response.msg.playerData[1][2]
        User:OnDailyQuestsChanged(DataManager:getUserData())
    end
    return response
end
local function get_alliance_response_msg(response)
    if response.msg.allianceData then
        local user_alliance_data = DataManager:getUserAllianceData()
        if user_alliance_data == json.null then
            DataManager:setUserAllianceData(response.msg.allianceData)
        else
            local edit = decodeInUserDataFromDeltaData(user_alliance_data,response.msg.allianceData)
            DataManager:setUserAllianceData(user_alliance_data, edit)
        end
        return response
    end
    return response
end
-- enemyAllianceData 全是返回的全数据
local function get_enemy_alliance_response_msg(response)
    if response.msg.enemyAllianceData then
        DataManager:setEnemyAllianceData(response.msg.enemyAllianceData)
        return response
    end
    return response
end

-- 只更新联盟的请求加入信息
local function get_alliance_joinrequestevents_response_msg(response)
    if response.msg.joinRequestEvents then
        DataManager:getUserAllianceData().joinRequestEvents = response.msg.joinRequestEvents
        Alliance_Manager:GetMyAlliance():OnJoinRequestEventsChanged(DataManager:getUserAllianceData())
    end
    return response
end

-- 只更新联盟战历史记录
local function get_alliance_alliancefightreports_response_msg(response)
    if response.msg.allianceFightReports then
        DataManager:getUserAllianceData().allianceFightReports = response.msg.allianceFightReports
        Alliance_Manager:GetMyAlliance():OnAllianceFightReportsChanged(DataManager:getUserAllianceData())
    end
    return response
end
--只更新圣地战斗记录
local function get_alliance_allianceshrinereports_response_msg(response)
    if response.msg.shrineReports then
        DataManager:getUserAllianceData().shrineReports = response.msg.shrineReports
        Alliance_Manager:GetMyAlliance():GetAllianceShrine():OnShrineReportsDataChanged(DataManager:getUserAllianceData())
    end
    return response
end

-- 只更新物品记录
local function get_alliance_itemlogs_response_msg(response)
    if response.msg.itemLogs then
        DataManager:getUserAllianceData().itemLogs = response.msg.itemLogs
        Alliance_Manager:GetMyAlliance():GetItemsManager():OnItemLogsChanged(DataManager:getUserAllianceData())
    end
    return response
end

local function check_response(m)
    return function(result)
        if result.success then
            return result
        end
        promise.reject({code = -1, msg = m}, m)
    end
end
local function check_request(m)
    return function(result)
        if not result.success or result.msg.code ~= SUCCESS_CODE then
            local code = result.msg.code
            local error_data = UIKit:getErrorCodeData(code) or {}
            local msg = error_data.message or _("未知错误!")
            if result.msg.code == 0 then
                promise.reject({code = code, msg = msg}, "timeout")
            else
                promise.reject({code = code, msg = msg}, m)
            end
        end
        return result
    end
end
-- 返回promise的函数
local function get_request_promise(request_route, data, m)
    local p = promise.new(check_request(m or ""))
    NetManager.m_netService:request(request_route, data, function(success, msg)
        p:resolve({success = success, msg = msg})
    end)
    return p
end
local function get_blocking_request_promise(request_route, data, m,need_catch,loading_ui_time)
    --默认后面的处理需要主动catch错误
    need_catch = type(need_catch) == 'boolean' and need_catch or false
    UIKit:WaitForNet(loading_ui_time)
    local p = cocos_promise.promiseWithTimeOut(get_request_promise(request_route, data, m), TIME_OUT):always(function()
        UIKit:NoWaitForNet()
    end)
    return cocos_promise.promiseFilterNetError(p,need_catch)
end
local function get_none_blocking_request_promise(request_route, data, m, need_catch)
    need_catch = need_catch or false
    -- return cocos_promise.promiseWithTimeOut(get_request_promise(request_route, data, m), TIME_OUT)
    return cocos_promise.promiseFilterNetError(get_request_promise(request_route, data, m), need_catch)
end
local function get_callback_promise(callbacks, m)
    local p = promise.new(check_response(m or ""))
    table.insert(callbacks, 1, function(success, msg)
        p:resolve({success = success, msg = msg})
    end)
    return p
end
------------------------
--
function NetManager:init()

    self.m_netService = import"app.service.NetService"
    self.m_netService:init()

    self.m_updateServer = {
        host = CONFIG_IS_LOCAL and CONFIG_LOCAL_SERVER.update.host or CONFIG_REMOTE_SERVER.update.host,
        port = CONFIG_IS_LOCAL and CONFIG_LOCAL_SERVER.update.port or CONFIG_REMOTE_SERVER.update.port,
        name = CONFIG_IS_LOCAL and CONFIG_LOCAL_SERVER.update.name or CONFIG_REMOTE_SERVER.update.name,
    }
    self.m_gateServer = {
        host = CONFIG_IS_LOCAL and CONFIG_LOCAL_SERVER.gate.host or CONFIG_REMOTE_SERVER.gate.host,
        port = CONFIG_IS_LOCAL and CONFIG_LOCAL_SERVER.gate.port or CONFIG_REMOTE_SERVER.gate.port,
        name = CONFIG_IS_LOCAL and CONFIG_LOCAL_SERVER.gate.name or CONFIG_REMOTE_SERVER.gate.name,
    }
    self.m_logicServer = {
        id = nil,
        host = nil,
        port = nil,
    }
end

function NetManager:getServerTime()
    return self.m_netService:getServerTime()
end

function NetManager:disconnect()
    self:removeEventListener("disconnect")
    self.m_netService:disconnect()
end

function NetManager:isConnected()
    return self.m_netService:isConnected()
end

function NetManager:addEventListener(event, cb)
    self.m_netService:addListener(event, function(success, msg)
        cb(success, msg)
    end)
end

function NetManager:removeEventListener(event)
    self.m_netService:removeListener(event)
end

local base_event_map = {
    disconnect = function(success, response)
        printLog("Server Status","disconnect")
        if NetManager.m_netService:isConnected() then
            UIKit:showKeyMessageDialog(_("错误"), _("与服务器的链接中断，请检查你的网络环境后重试!"), function()
                app:retryConnectServer()
            end)
        end
    end,
    timeout = function(success, response)
    end,
    onKick = function(success, response)
        printLog("Server Status","onKick")
        NetManager:disconnect()
        UIKit:showKeyMessageDialog(_("提示"), _("服务器连接断开!"), function()
            app:restart(false)
        end)
    end,
}


local logic_event_map = {
    -- player
    onPlayerDataChanged = function(success, response)
        if not NetManager.m_was_inited_game then return end
        if success then
            local user_data = DataManager:getUserData()
            local edit = decodeInUserDataFromDeltaData(user_data, response)
            LuaUtils:outputTable("edit", edit)
            -- 在客户端没有 mails 或者 reports key时，收到邮件或者战报需要增加未读字段数值
            if not user_data.reports then
                for i,v in ipairs(response) do
                    if v[1] and string.find(v[1],"reports") then
                        MailManager:IncreaseUnReadReportNum(1)
                    end
                end
            end
            if not user_data.mails then
                for i,v in ipairs(response) do
                    if v[1] and string.find(v[1],"mails") then
                        MailManager:IncreaseUnReadMailsNum(1)
                    end
                end
            end
            DataManager:setUserData(user_data, edit)
        end
    end,
    -- chat
    onChat = function(success, response)
        if not NetManager.m_was_inited_game then return end
        if success then
            app:GetChatManager():HandleNetMessage("onChat", response)
        end
    end,
    -- alliance
    onAllianceDataChanged = function(success, response)
        if not NetManager.m_was_inited_game then return end
        if success and DataManager:hasUserData() then
            LuaUtils:outputTable("onAllianceDataChanged", response)
            local user_alliance_data = DataManager:getUserAllianceData()
            local edit = decodeInUserDataFromDeltaData(user_alliance_data, response)
            DataManager:setUserAllianceData(user_alliance_data, edit)
        end
    end,
    onJoinAllianceSuccess = function(success, response)
        if not NetManager.m_was_inited_game then return end
        if success and DataManager:hasUserData() then
            DataManager:setEnemyAllianceData(response.enemyAllianceData)
            DataManager:setUserAllianceData(response.allianceData)
            local user_data = DataManager:getUserData()
            local edit = decodeInUserDataFromDeltaData(user_data, response.playerData)
            DataManager:setUserData(user_data, edit)
        end
    end,
    onEnemyAllianceDataChanged = function(success, response)
        if not NetManager.m_was_inited_game then return end
        if success and DataManager:hasUserData() then
            LuaUtils:outputTable("onEnemyAllianceDataChanged", response)
            local user_enemy_alliance_data = DataManager:getEnemyAllianceData()
            local edit = decodeInUserDataFromDeltaData(user_enemy_alliance_data,response)
            DataManager:setEnemyAllianceData(user_enemy_alliance_data,edit)
        end
    end,
    onAllianceFight = function(success, response)
        if not NetManager.m_was_inited_game then return end
        if success and DataManager:hasUserData() then
            LuaUtils:outputTable("onAllianceFight", response)
            local user_enemy_alliance_data = response.enemyAllianceData
            DataManager:setEnemyAllianceData(user_enemy_alliance_data)
            local user_alliance_data = DataManager:getUserAllianceData()
            local edit = decodeInUserDataFromDeltaData(user_alliance_data, response.allianceData)
            DataManager:setUserAllianceData(user_alliance_data, edit)
        end
    end,
    onNotice = function(success, response)
        if success then
            local running_scene = display.getRunningScene().__cname
            if running_scene ~= "MainScene" and running_scene ~= "LogoScene" then
                GameGlobalUI:showNotice(response.type,response.content)
            end
        end
    end,
}
---
function NetManager:InitEventsMap(...)
    self:CleanAllEventListeners()
    for _,events in ipairs{...} do
        for event_name,callback in pairs(events) do
            self:addEventListener(event_name, function(success, response)
                callback(success, response)
                local callback_ = unpack(self.event_callback_map[event_name])
                if type(callback_) == "function" then
                    callback_(success, response)
                end
                self.event_callback_map[event_name] = {}
            end)
        end
        for k,v in pairs(events) do
            self.event_map[k] = v
            self.event_callback_map[k] = {}
        end
    end
end
function NetManager:CleanAllEventListeners()
    for event_name,_ in pairs(self.event_map or {}) do
        self:removeEventListener(event_name)
    end
    self.event_map = {}
    self.event_callback_map = {}
end
function NetManager:GetPromiseOfEventName(event_name, failed_info)
    return get_callback_promise(self.event_callback_map[event_name], failed_info)
end
-- 事件回调promise
local function get_playerdata_callback()
    return NetManager:GetPromiseOfEventName("onPlayerDataChanged", "返回玩家数据失败!")
end
local function get_alliancedata_callback()
    return NetManager:GetPromiseOfEventName("onAllianceDataChanged", "修改联盟信息失败!")
end
local function get_sendchat_callback()
    return NetManager:GetPromiseOfEventName("onChat", "发送聊天失败!")
end
local function get_fetchchat_callback()
    return NetManager:GetPromiseOfEventName("onAllChat", "获取聊天失败!")
end



--连接网关服务器
local function get_connectGateServer_promise()
    local p = promise.new(check_request("连接网关服务器失败!"))
    NetManager.m_netService:connect(NetManager.m_gateServer.host, NetManager.m_gateServer.port, function(success)
        p:resolve({success = success, msg = {code = SUCCESS_CODE}})
    end)
    return cocos_promise.promiseWithTimeOut(p, TIME_OUT)
end
function NetManager:getConnectGateServerPromise()
    return get_connectGateServer_promise():next(function(result)
        self:InitEventsMap(base_event_map)
    end)
end
-- 获取服务器列表
function NetManager:getLogicServerInfoPromise()
    local device_id = device.getOpenUDID()
    return get_none_blocking_request_promise("gate.gateHandler.queryEntry", {deviceId = device_id}, "获取逻辑服务器失败",true)
        :done(function(result)
            self:CleanAllEventListeners()
            self.m_netService:disconnect()
            self.m_logicServer.host = result.msg.data.host
            self.m_logicServer.port = result.msg.data.port
            self.m_logicServer.id = result.msg.data.id
        end)
end
-- 连接逻辑服务器
local function get_connectLogicServer_promise()
    local p = promise.new(check_request("连接逻辑服务器失败!"))
    NetManager.m_netService:connect(NetManager.m_logicServer.host, NetManager.m_logicServer.port, function(success)
        p:resolve({success = success, msg = {code = SUCCESS_CODE}})
    end)
    return cocos_promise.promiseWithTimeOut(p, TIME_OUT)
end
function NetManager:getConnectLogicServerPromise()
    return get_connectLogicServer_promise():next(function(result)
        self:InitEventsMap(base_event_map, logic_event_map)
    end)
end
-- 登录
function NetManager:getLoginPromise(deviceId)
    local device_id = device.getOpenUDID()
    local requestTime = ext.now()
    return get_none_blocking_request_promise("logic.entryHandler.login", {
        deviceId = deviceId or device_id,
        requestTime = requestTime,
    }, nil, true):next(function(response)
        if response.success then
            app:GetPushManager():CancelAll() -- 登录成功便清空本地通知
            local playerData = response.msg.playerData
            local user_alliance_data = response.msg.allianceData
            local user_enemy_alliance_data = response.msg.enemyAllianceData

            local diff_time = ext.now() - requestTime 
            local request_server_time = requestTime + playerData.deltaTime
            local real_server_time = diff_time / 2 + request_server_time  
            local delta_time = real_server_time - ext.now()

            -- print_(requestTime, diff_time, playerData.deltaTime, delta_time, request_server_time, real_server_time)
            if self.m_was_inited_game then
                self.m_netService:setDeltatime(delta_time)
                DataManager:setUserData(playerData)
                DataManager:setUserAllianceData(user_alliance_data)
                DataManager:setEnemyAllianceData(user_enemy_alliance_data)
            else
                -- LuaUtils:outputTable("logic.entryHandler.login", response)
                self.m_netService:setDeltatime(delta_time)
                local InitGame = import("app.service.InitGame")
                InitGame(playerData) -- inner DataManager:setUserData ...
                DataManager:setUserAllianceData(user_alliance_data)
                DataManager:setEnemyAllianceData(user_enemy_alliance_data)
                self.m_was_inited_game = true
            end
        end
        return response
    end)
end
-- 初始化玩家数据
function NetManager:initPlayerData(terrain, language)
    if DataManager:getUserData().basicInfo.terrain ~= "__NONE__" then
        assert(false)
    end
    assert(terrain == "grassLand" or
        terrain == "desert" or
        terrain == "iceField" )
    return get_blocking_request_promise("logic.playerHandler.initPlayerData", {
        terrain = terrain,
        language = language or app:GetGameLanguage(),
    }, "初始化玩家数据失败!"):done(get_player_response_msg)
end
-- 个人修改地形
local function get_changeTerrain_promise(terrain)
    return get_blocking_request_promise("logic.playerHandler.setTerrain", {
        terrain = terrain
    }, "修改地形失败!")
end
function NetManager:getChangeToGrassPromise()
    return get_changeTerrain_promise("grassLand"):done(get_player_response_msg)
end
function NetManager:getChangeToDesertPromise()
    return get_changeTerrain_promise("desert"):done(get_player_response_msg)
end
function NetManager:getChangeToIceFieldPromise()
    return get_changeTerrain_promise("iceField"):done(get_player_response_msg)
end
-- 设置玩家头像
function NetManager:getSetPlayerIconPromise(icon)
    return get_blocking_request_promise("logic.playerHandler.setPlayerIcon",{
        icon = icon
    }):done(get_player_response_msg)
end
-- 建造小屋
function NetManager:getCreateHouseByLocationPromise(location, sub_location, building_type)
    return get_blocking_request_promise("logic.playerHandler.createHouse", {
        buildingLocation = location,
        houseLocation = sub_location,
        houseType = building_type,
        finishNow = false
    }, "建造小屋失败!"):done(get_player_response_msg)
end
-- 升级小屋
local function get_upgradeHouse_promise(location, sub_location, finish_now)
    return get_blocking_request_promise("logic.playerHandler.upgradeHouse", {
        buildingLocation = location,
        houseLocation = sub_location,
        finishNow = finish_now or false
    }, "升级小屋失败!"):done(get_player_response_msg)
end
function NetManager:getUpgradeHouseByLocationPromise(location, sub_location)
    return get_upgradeHouse_promise(location, sub_location, false)
end
function NetManager:getInstantUpgradeHouseByLocationPromise(location, sub_location)
    return get_upgradeHouse_promise(location, sub_location, true)
end
-- 升级功能建筑
local function get_upgradeBuilding_promise(location, finish_now)
    return get_blocking_request_promise("logic.playerHandler.upgradeBuilding", {
        location = location,
        finishNow = finish_now or false
    }, "升级功能建筑失败!"):done(get_player_response_msg)
end
function NetManager:getUpgradeBuildingByLocationPromise(location)
    return get_upgradeBuilding_promise(location, false)
end
function NetManager:getInstantUpgradeBuildingByLocationPromise(location)
    return get_upgradeBuilding_promise(location, true)
end
-- 升级防御塔
function NetManager:getUpgradeTowerPromise()
    return NetManager:getUpgradeBuildingByLocationPromise(22)
end
function NetManager:getInstantUpgradeTowerPromise()
    return NetManager:getInstantUpgradeBuildingByLocationPromise(22)
end
-- 升级城门
function NetManager:getUpgradeWallByLocationPromise()
    return NetManager:getUpgradeBuildingByLocationPromise(21)
end
function NetManager:getInstantUpgradeWallByLocationPromise()
    return NetManager:getInstantUpgradeBuildingByLocationPromise(21)
end
--转换生产建筑类型
function NetManager:getSwitchBuildingPromise(buildingLocation,newBuildingName)
    return get_blocking_request_promise("logic.playerHandler.switchBuilding", {
        buildingLocation = buildingLocation,
        newBuildingName = newBuildingName
    },
    "转换生产建筑类型失败!"):done(get_player_response_msg)
end


-- 制造材料
local function get_makeMaterial_promise(category)
    return get_blocking_request_promise("logic.playerHandler.makeMaterial", {
        category = category,
        finishNow = false
    }, "制造材料失败!"):done(get_player_response_msg)
end
-- 建造建筑材料
function NetManager:getMakeBuildingMaterialPromise()
    return get_makeMaterial_promise("buildingMaterials")
end
-- 建造科技材料
function NetManager:getMakeTechnologyMaterialPromise()
    return get_makeMaterial_promise("technologyMaterials")
end
-- 获取材料
function NetManager:getFetchMaterialsPromise(id)
    return get_blocking_request_promise("logic.playerHandler.getMaterials", {
        eventId = id,
    }, "获取材料失败!"):done(get_player_response_msg):done(function()
        app:GetAudioManager():PlayeEffectSoundWithKey("COMPLETE")
    end)
end
-- 打造装备
local function get_makeDragonEquipment_promise(equipment_name, finish_now)
    return get_blocking_request_promise("logic.playerHandler.makeDragonEquipment", {
        equipmentName = equipment_name,
        finishNow = finish_now or false
    }, "打造装备失败!"):done(get_player_response_msg):done(function()
        app:GetAudioManager():PlayeEffectSoundWithKey("UI_BLACKSMITH_FORGE")
    end)
end
function NetManager:getMakeDragonEquipmentPromise(equipment_name)
    return get_makeDragonEquipment_promise(equipment_name)
end
function NetManager:getInstantMakeDragonEquipmentPromise(equipment_name)
    return get_makeDragonEquipment_promise(equipment_name, true)
end
-- 招募士兵
local function get_recruitNormalSoldier_promise(soldierName, count, finish_now)
    return get_blocking_request_promise("logic.playerHandler.recruitNormalSoldier", {
        soldierName = soldierName,
        count = count,
        finishNow = finish_now or false
    }, "招募普通士兵失败!"):done(get_player_response_msg)
end
function NetManager:getRecruitNormalSoldierPromise(soldierName, count, cb)
    return get_recruitNormalSoldier_promise(soldierName, count):done(function(response)
        app:GetAudioManager():PlayeEffectSoundWithKey("TROOP_RECRUIT")
        return response
    end)
end
function NetManager:getInstantRecruitNormalSoldierPromise(soldierName, count, cb)
    return get_recruitNormalSoldier_promise(soldierName, count, true):done(function()
        app:GetAudioManager():PlayeEffectSoundWithKey("COMPLETE")
        GameGlobalUI:showTips(_("招募士兵完成"),Localize.soldier_name[soldierName].."X"..count)
    end)
end
-- 招募特殊士兵
local function get_recruitSpecialSoldier_promise(soldierName, count, finish_now)
    return get_blocking_request_promise("logic.playerHandler.recruitSpecialSoldier", {
        soldierName = soldierName,
        count = count,
        finishNow = finish_now or false
    }, "招募特殊士兵失败!"):done(get_player_response_msg)
end
function NetManager:getRecruitSpecialSoldierPromise(soldierName, count)
    return get_recruitSpecialSoldier_promise(soldierName, count):done(function(response)
        app:GetAudioManager():PlayeEffectSoundWithKey("TROOP_RECRUIT")
        return response
    end)
end
function NetManager:getInstantRecruitSpecialSoldierPromise(soldierName, count)
    return get_recruitSpecialSoldier_promise(soldierName, count, true):done(function()
        app:GetAudioManager():PlayeEffectSoundWithKey("COMPLETE")
        GameGlobalUI:showTips(_("招募士兵完成"),Localize.soldier_name[soldierName].."X"..count)
    end)
end
-- 普通治疗士兵
local function get_treatSoldier_promise(soldiers, finish_now)
    return get_blocking_request_promise("logic.playerHandler.treatSoldier", {
        soldiers = soldiers,
        finishNow = finish_now or false
    }, "普通治疗士兵失败!"):done(get_player_response_msg)
end
function NetManager:getTreatSoldiersPromise(soldiers)
    return get_treatSoldier_promise(soldiers)
end
function NetManager:getInstantTreatSoldiersPromise(soldiers)
    return get_treatSoldier_promise(soldiers, true):done(function ()
        local get_list = ""
        for k,v in pairs(soldiers) do
            local m_name = Localize.soldier_name[v.name]
            get_list = get_list .. m_name .. "X"..v.count.." "
        end
        GameGlobalUI:showTips(_("治愈士兵完成"),get_list)
    end)
end
-- 孵化
function NetManager:getHatchDragonPromise(dragonType)
    return get_blocking_request_promise("logic.playerHandler.hatchDragon", {
        dragonType = dragonType,
    }, "孵化失败!"):done(get_player_response_msg)
end
-- 装备
function NetManager:getLoadDragonEquipmentPromise(dragonType, equipmentCategory, equipmentName)
    return get_blocking_request_promise("logic.playerHandler.setDragonEquipment", {
        dragonType = dragonType,
        equipmentCategory = equipmentCategory,
        equipmentName = equipmentName
    }, "装备失败!"):done(get_player_response_msg)
end
-- 卸载装备
function NetManager:getResetDragonEquipmentPromise(dragonType, equipmentCategory)
    return get_blocking_request_promise("logic.playerHandler.resetDragonEquipment", {
        dragonType = dragonType,
        equipmentCategory = equipmentCategory
    }, "卸载装备失败!"):done(get_player_response_msg)
end
-- 强化装备
function NetManager:getEnhanceDragonEquipmentPromise(dragonType, equipmentCategory, equipments)
    return get_blocking_request_promise("logic.playerHandler.enhanceDragonEquipment", {
        dragonType = dragonType,
        equipmentCategory = equipmentCategory,
        equipments = equipments
    }, "强化装备失败!"):done(get_player_response_msg)
end
-- 升级龙星
function NetManager:getUpgradeDragonStarPromise(dragonType)
    return get_blocking_request_promise("logic.playerHandler.upgradeDragonStar", {
        dragonType = dragonType,
    }, "升级龙星失败!"):done(get_player_response_msg)
end
-- 升级龙技能
function NetManager:getUpgradeDragonDragonSkillPromise(dragonType, skillKey)
    return get_blocking_request_promise("logic.playerHandler.upgradeDragonSkill", {
        dragonType = dragonType,
        skillKey = skillKey
    }, "升级龙技能失败!"):done(get_player_response_msg)
end
-- 获取每日任务列表
function NetManager:getDailyQuestsPromise()
    return get_blocking_request_promise("logic.playerHandler.getDailyQuests", {},
        "获取每日任务列表失败!"):done(get_daily_quests_response_msg)
end
-- 为每日任务中某个任务增加星级
function NetManager:getAddDailyQuestStarPromise(questId)
    return get_blocking_request_promise("logic.playerHandler.addDailyQuestStar",
        {
            questId = questId
        },
        "为每日任务中某个任务增加星级失败!"):done(get_player_response_msg)
end
-- 开始一个每日任务
function NetManager:getStartDailyQuestPromise(questId)
    return get_blocking_request_promise("logic.playerHandler.startDailyQuest",
        {
            questId = questId
        },
        "开始一个每日任务失败!"):done(get_player_response_msg)
end
-- 领取每日任务奖励
function NetManager:getDailyQeustRewardPromise(questEventId)
    return get_blocking_request_promise("logic.playerHandler.getDailyQeustReward",
        {
            questEventId = questEventId
        },
        "领取每日任务奖励失败!"):done(get_player_response_msg):done(function()
        app:GetAudioManager():PlayeEffectSoundWithKey("COMPLETE")
        end)
end
-- 发送个人邮件
function NetManager:getSendPersonalMailPromise(memberId, title, content , contacts)
    return get_blocking_request_promise("logic.playerHandler.sendMail", {
        memberId = memberId,
        title = title,
        content = content,
    }, "发送个人邮件失败!"):done(get_response_msg):done(function ( response )
        GameGlobalUI:showTips(_("提示"),_("发送邮件成功"))
        if contacts then
            -- 保存联系人
            contacts.time = app.timer:GetServerTime()
            app:GetGameDefautlt():addRecentContacts(contacts)
        end
        return response
    end)
end
-- 获取收件箱邮件
function NetManager:getFetchMailsPromise(fromIndex)
    return get_blocking_request_promise("logic.playerHandler.getMails", {
        fromIndex = fromIndex
    }, "获取收件箱邮件失败!")
end
-- 阅读邮件
function NetManager:getReadMailsPromise(mailIds)
    return get_none_blocking_request_promise("logic.playerHandler.readMails", {
        mailIds = mailIds
    }, "阅读邮件失败!"):done(get_response_mail_msg)
end
-- 收藏邮件
function NetManager:getSaveMailPromise(mailId)
    return get_blocking_request_promise("logic.playerHandler.saveMail", {
        mailId = mailId
    }, "收藏邮件失败!"):done(get_response_mail_msg)
end
-- 取消收藏邮件
function NetManager:getUnSaveMailPromise(mailId)
    return get_blocking_request_promise("logic.playerHandler.unSaveMail", {
        mailId = mailId
    }, "取消收藏邮件失败!"):done(get_response_mail_msg)
end
-- 获取收藏邮件
function NetManager:getFetchSavedMailsPromise(fromIndex)
    return get_blocking_request_promise("logic.playerHandler.getSavedMails", {
        fromIndex = fromIndex
    }, "获取收藏邮件失败!")
end
-- 获取已发送邮件
function NetManager:getFetchSendMailsPromise(fromIndex)
    return get_blocking_request_promise("logic.playerHandler.getSendMails", {
        fromIndex = fromIndex
    }, "获取已发送邮件失败!")
end
-- 删除邮件
function NetManager:getDeleteMailsPromise(mailIds)
    return get_blocking_request_promise("logic.playerHandler.deleteMails", {
        mailIds = mailIds
    }, "删除邮件失败!"):done(get_response_delete_mail_msg)
end
-- 发送联盟邮件
function NetManager:getSendAllianceMailPromise(title, content)
    return get_blocking_request_promise("logic.allianceHandler.sendAllianceMail", {
        title = title,
        content = content,
    }, "发送联盟邮件失败!"):done(get_player_response_msg):done(function ( response )
        GameGlobalUI:showTips(_("提示"),_("发送邮件成功"))
        return response
    end)
end
-- 阅读战报
function NetManager:getReadReportsPromise(reportIds)
    return get_none_blocking_request_promise("logic.playerHandler.readReports", {
        reportIds = reportIds
    }, "阅读战报失败!"):done(get_response_report_msg)
end
-- 收藏战报
function NetManager:getSaveReportPromise(reportId)
    return get_blocking_request_promise("logic.playerHandler.saveReport", {
        reportId = reportId
    }, "收藏战报失败!"):done(get_response_report_msg)
end
-- 取消收藏战报
function NetManager:getUnSaveReportPromise(reportId)
    return get_blocking_request_promise("logic.playerHandler.unSaveReport", {
        reportId = reportId
    }, "取消收藏战报失败!"):done(get_response_report_msg)
end
-- 获取玩家战报
function NetManager:getReportsPromise(fromIndex)
    return get_blocking_request_promise("logic.playerHandler.getReports", {
        fromIndex = fromIndex
    }, "获取玩家战报失败!")
end
-- 获取玩家已存战报
function NetManager:getSavedReportsPromise(fromIndex)
    return get_blocking_request_promise("logic.playerHandler.getSavedReports", {
        fromIndex = fromIndex
    }, "获取玩家已存战报失败!")
end
-- 删除战报
function NetManager:getDeleteReportsPromise(reportIds)
    return get_blocking_request_promise("logic.playerHandler.deleteReports", {
        reportIds = reportIds
    }, "删除战报失败!"):done(get_response_delete_report_msg)
end
-- 请求加速
function NetManager:getRequestAllianceToSpeedUpPromise(eventType, eventId)
    return get_blocking_request_promise("logic.allianceHandler.requestAllianceToSpeedUp", {
        eventType = eventType,
        eventId = eventId,
    }, "请求加速失败!"):done(get_player_response_msg)
end
-- 免费加速建筑升级
function NetManager:getFreeSpeedUpPromise(eventType, eventId)
    return get_blocking_request_promise("logic.playerHandler.freeSpeedUp", {
        eventType = eventType,
        eventId = eventId,
    }, "请求免费加速失败!"):done(get_player_response_msg)
end
-- 协助玩家加速
function NetManager:getHelpAllianceMemberSpeedUpPromise(eventId)
    return get_none_blocking_request_promise("logic.allianceHandler.helpAllianceMemberSpeedUp", {
        eventId = eventId,
    }, "协助玩家加速失败!"):done(get_player_response_msg)
end
-- 协助所有玩家加速
function NetManager:getHelpAllAllianceMemberSpeedUpPromise()
    return get_none_blocking_request_promise("logic.allianceHandler.helpAllAllianceMemberSpeedUp", {}
        , "协助所有玩家加速失败!"):done(get_player_response_msg)
end
-- 解锁玩家第二条行军队列
function NetManager:getUnlockPlayerSecondMarchQueuePromise()
    return get_blocking_request_promise("logic.playerHandler.unlockPlayerSecondMarchQueue", {}
        , "解锁玩家第二条行军队列失败!"):done(get_player_response_msg)
end
-- 创建联盟
function NetManager:getCreateAlliancePromise(name, tag, language, terrain, flag)
    return get_blocking_request_promise("logic.allianceHandler.createAlliance", {
        name = name,
        tag = tag,
        language = language,
        terrain = terrain,
        flag = flag
    }, "创建联盟失败!"):done(get_player_response_msg):done(get_alliance_response_msg)
end
-- 退出联盟
function NetManager:getQuitAlliancePromise()
    return get_blocking_request_promise("logic.allianceHandler.quitAlliance", nil
        , "退出联盟失败!"):done(get_player_response_msg)
end
-- 修改联盟加入条件
function NetManager:getEditAllianceJoinTypePromise(join_type)
    return get_blocking_request_promise("logic.allianceHandler.editAllianceJoinType", {
        joinType = join_type
    }, "修改联盟加入条件失败!"):done(get_player_response_msg)
end
-- 拒绝玩家
function NetManager:getRemoveJoinAllianceReqeustsPromise(requestEventIds)
    return get_blocking_request_promise("logic.allianceHandler.removeJoinAllianceReqeusts",{
        requestEventIds = requestEventIds}, "拒绝玩家失败!")
        :done(get_alliance_response_msg)
end
-- 接受玩家
function NetManager:getApproveJoinAllianceRequestPromise(requestEventId)
    return get_blocking_request_promise("logic.allianceHandler.approveJoinAllianceRequest", {
        requestEventId = requestEventId
    }, "接受玩家失败!"):done(get_alliance_response_msg)
end
-- 踢出玩家
function NetManager:getKickAllianceMemberOffPromise(memberId)
    return get_blocking_request_promise("logic.allianceHandler.kickAllianceMemberOff", {
        memberId = memberId,
    }, "踢出玩家失败!"):done(get_player_response_msg)
end
-- 搜索特定标签联盟
function NetManager:getSearchAllianceByTagPromsie(tag)
    return get_blocking_request_promise("logic.allianceHandler.searchAllianceByTag", {
        tag = tag
    }, "搜索特定标签联盟失败!")
end
-- 搜索能直接加入联盟
function NetManager:getFetchCanDirectJoinAlliancesPromise(fromIndex)
    return get_blocking_request_promise("logic.allianceHandler.getCanDirectJoinAlliances", {fromIndex = fromIndex},"搜索直接加入联盟失败!")
end
-- 邀请加入联盟
function NetManager:getInviteToJoinAlliancePromise(memberId)
    return get_blocking_request_promise("logic.allianceHandler.inviteToJoinAlliance", {
        memberId = memberId
    }, "邀请加入联盟联盟失败!")
end
-- 直接加入联盟
function NetManager:getJoinAllianceDirectlyPromise(allianceId)
    return get_blocking_request_promise("logic.allianceHandler.joinAllianceDirectly", {
        allianceId = allianceId
    }, "直接加入联盟失败!"):done(get_enemy_alliance_response_msg):done(get_player_response_msg):done(get_alliance_response_msg)
end
-- 请求加入联盟
function NetManager:getRequestToJoinAlliancePromise(allianceId)
    return get_blocking_request_promise("logic.allianceHandler.requestToJoinAlliance", {
        allianceId = allianceId
    }, "请求加入联盟失败!"):done(get_player_response_msg)
end
-- 获取玩家信息
function NetManager:getPlayerInfoPromise(memberId)
    return get_blocking_request_promise("logic.playerHandler.getPlayerInfo", {
        memberId = memberId
    }, "获取玩家信息失败!"):done(get_player_response_msg)
end
-- 获取玩家城市信息
function NetManager:getPlayerCityInfoPromise(targetPlayerId)
    return get_blocking_request_promise("logic.playerHandler.getPlayerViewData", {
        targetPlayerId = targetPlayerId
    }, "获取玩家城市信息失败!")
end
-- 移交萌主
function NetManager:getHandOverAllianceArchonPromise(memberId)
    return get_blocking_request_promise("logic.allianceHandler.handOverAllianceArchon", {
        memberId = memberId,
    }, "移交萌主失败!"):done(get_player_response_msg)
end
-- 修改成员职位
function NetManager:getEditAllianceMemberTitlePromise(memberId, title)
    return get_blocking_request_promise("logic.allianceHandler.editAllianceMemberTitle", {
        memberId = memberId,
        title = title
    }, "修改成员职位失败!"):done(get_player_response_msg)
end
-- 修改联盟公告
function NetManager:getEditAllianceNoticePromise(notice)
    return get_blocking_request_promise("logic.allianceHandler.editAllianceNotice", {
        notice = notice
    }, "修改联盟公告失败!"):done(get_player_response_msg)
end
-- 修改联盟描述
function NetManager:getEditAllianceDescriptionPromise(description)
    return get_blocking_request_promise("logic.allianceHandler.editAllianceDescription", {
        description = description
    }, "修改联盟描述失败!"):done(get_player_response_msg)
end
-- 修改职位名字
function NetManager:getEditAllianceTitleNamePromise(title, titleName)
    return get_blocking_request_promise("logic.allianceHandler.editAllianceTitleName", {
        title = title,
        titleName = titleName
    }, "修改职位名字失败!"):done(get_player_response_msg)
end
-- 发送秘籍
function NetManager:getSendGlobalMsgPromise(text)
    return get_blocking_request_promise("chat.chatHandler.send", {
        ["text"] = text,
        ["channel"] = "global"
    }, "发送世界聊天信息失败!")
end
--发送聊天信息
function NetManager:getSendChatPromise(channel,text)
    return get_none_blocking_request_promise("chat.chatHandler.send", {
        ["text"] = text,
        ["channel"] = channel
    }, "发送聊天信息失败!")
end
--获取所有聊天信息
function NetManager:getFetchChatPromise(channel)
    return get_none_blocking_request_promise("chat.chatHandler.getAll",{channel = channel}, "获取聊天信息失败!")
end
-- 获取所有请求加入联盟的申请
function NetManager:getJoinRequestEventsPromise(allianceId)
    return get_blocking_request_promise("logic.allianceHandler.getJoinRequestEvents", {
        allianceId = allianceId
    }, "获取所有请求加入联盟的申请失败!"):done(get_alliance_joinrequestevents_response_msg)
end
-- 获取联盟战历史记录
function NetManager:getAllianceFightReportsPromise(allianceId)
    return get_blocking_request_promise("logic.allianceHandler.getAllianceFightReports", {
        allianceId = allianceId
    }, "获取联盟战历史记录失败!"):done(get_alliance_alliancefightreports_response_msg)
end
--获取联盟圣地战历史记录
function NetManager:getShrineReportsPromise()
    return get_blocking_request_promise("logic.allianceHandler.getShrineReports",nil,
        "获取联盟圣地战历史记录失败!"):done(get_alliance_allianceshrinereports_response_msg)
end
-- 获取联盟商店买入卖出记录
function NetManager:getItemLogsPromise(allianceId)
    return get_blocking_request_promise("logic.allianceHandler.getItemLogs", {
        allianceId = allianceId
    }, "获取联盟商店买入卖出记录失败!"):done(get_alliance_itemlogs_response_msg)
end
--处理联盟的对玩家的邀请
local function getHandleJoinAllianceInvitePromise(allianceId, agree)
    return get_blocking_request_promise("logic.allianceHandler.handleJoinAllianceInvite", {
        ["allianceId"] = allianceId,
        ["agree"] = agree,
    }, "处理联盟的对玩家的邀请失败!"):done(get_enemy_alliance_response_msg):done(get_alliance_response_msg):done(get_player_response_msg)
end
function NetManager:getHandleJoinAllianceInvitePromise(allianceId, agree)
    return getHandleJoinAllianceInvitePromise(allianceId, agree)
end
function NetManager:getAgreeJoinAllianceInvitePromise(allianceId)
    return getHandleJoinAllianceInvitePromise(allianceId, true)
end
function NetManager:getDisagreeJoinAllianceInvitePromise(allianceId)
    return getHandleJoinAllianceInvitePromise(allianceId, false)
end
--取消申请联盟
function NetManager:getCancelJoinAlliancePromise(allianceId)
    return get_blocking_request_promise("logic.allianceHandler.cancelJoinAllianceRequest", {
        ["allianceId"] = allianceId,
    }, "取消申请联盟失败!"):done(get_player_response_msg)
end
--修改联盟基本信息
function NetManager:getEditAllianceBasicInfoPromise(name, tag, language, flag)
    return get_blocking_request_promise("logic.allianceHandler.editAllianceBasicInfo", {
        name = name,
        tag = tag,
        language = language,
        flag = flag
    }, "修改联盟基本信息失败!"):done(get_player_response_msg)
end
-- 移动联盟建筑
function NetManager:getMoveAllianceBuildingPromise(mapObjectId, locationX, locationY)
    return get_blocking_request_promise("logic.allianceHandler.moveAllianceBuilding", {
        mapObjectId = mapObjectId,
        locationX = locationX,
        locationY = locationY
    }, "移动联盟建筑失败!"):done(get_player_response_msg):done(get_alliance_response_msg)
end
-- 激活联盟事件
function NetManager:getActivateAllianceShrineStagePromise(stageName)
    return get_blocking_request_promise("logic.allianceHandler.activateAllianceShrineStage", {
        stageName = stageName
    }, "激活联盟事件失败!"):done(get_player_response_msg)
end
-- 升级联盟建筑
function NetManager:getUpgradeAllianceBuildingPromise(buildingName)
    return get_blocking_request_promise("logic.allianceHandler.upgradeAllianceBuilding", {
        buildingName = buildingName
    }, "升级联盟建筑失败!"):done(get_player_response_msg):done(get_alliance_response_msg)
end
-- 升级联盟村落
function NetManager:getUpgradeAllianceVillagePromise(villageType)
    return get_blocking_request_promise("logic.allianceHandler.upgradeAllianceVillage", {
        villageType = villageType
    }, "升级联盟村落失败!"):done(get_player_response_msg)
end
-- 联盟捐赠
function NetManager:getDonateToAlliancePromise(donateType)
    return get_blocking_request_promise("logic.allianceHandler.donateToAlliance", {
        donateType = donateType
    }, "联盟捐赠失败!"):done(get_player_response_msg)
end
-- 编辑联盟地形
function NetManager:getEditAllianceTerrianPromise(terrain)
    return get_blocking_request_promise("logic.allianceHandler.editAllianceTerrian", {
        terrain = terrain
    }, "编辑联盟地形失败!")
end

function NetManager:getMarchToShrinePromose(shrineEventId,dragonType,soldiers)
    return get_blocking_request_promise("logic.allianceHandler.attackAllianceShrine", {
        dragonType = dragonType,
        shrineEventId = shrineEventId,
        soldiers = soldiers
    }, "圣地派兵失败!"):done(get_player_response_msg)
end
--查找合适的联盟进行战斗
function NetManager:getFindAllianceToFightPromose()
    return get_blocking_request_promise("logic.allianceHandler.findAllianceToFight",
        {}, "查找合适的联盟进行战斗失败!"):done(get_player_response_msg):done(get_alliance_response_msg)
end
--获取对手联盟数据
function NetManager:getFtechAllianceViewDataPromose(targetAllianceId)
    return get_blocking_request_promise("logic.allianceHandler.getAllianceViewData",
        {targetAllianceId = targetAllianceId,
            includeMoonGateData = true
        },"获取对手联盟数据失败!")
end
--请求联盟进行联盟战
function NetManager:getRequestAllianceToFightPromose()
    return get_blocking_request_promise("logic.allianceHandler.requestAllianceToFight",{},
        "请求联盟进行联盟战失败!"):done(get_player_response_msg)
end

--请求联盟数据
function NetManager:getAllianceInfoPromise(allianceId)
    return get_blocking_request_promise("logic.allianceHandler.getAllianceInfo",{allianceId = allianceId},
        "请求联盟数据失败!",false,0)
end
--协防
function NetManager:getHelpAllianceMemberDefencePromise(dragonType, soldiers, targetPlayerId)
    return get_blocking_request_promise("logic.allianceHandler.helpAllianceMemberDefence",
        {
            dragonType = dragonType,
            soldiers   = soldiers,
            targetPlayerId = targetPlayerId,
        },
        "协防玩家失败!"):done(get_player_response_msg)
end
--撤销协防
function NetManager:getRetreatFromHelpedAllianceMemberPromise(beHelpedPlayerId)
    return get_blocking_request_promise("logic.allianceHandler.retreatFromBeHelpedAllianceMember",
        {
            beHelpedPlayerId = beHelpedPlayerId,
        },
        "撤销协防失败!"):done(get_player_response_msg)
end
--复仇其他联盟
function NetManager:getRevengeAlliancePromise(reportId)
    return get_blocking_request_promise("logic.allianceHandler.revengeAlliance",
        {
            reportId = reportId,
        },
        "复仇其他联盟失败!"):done(get_player_response_msg)
end
--查看战力相近的高低3个联盟的数据
function NetManager:getNearedAllianceInfosPromise()
    return get_blocking_request_promise("logic.allianceHandler.getNearedAllianceInfos",
        {},
        "查看战力相近的高低3个联盟的数据失败!"):done(get_player_response_msg)
end
--根据Tag搜索联盟战斗数据
function NetManager:getSearchAllianceInfoByTagPromise(tag)
    return get_blocking_request_promise("logic.allianceHandler.searchAllianceInfoByTag",
        {tag=tag},
        "根据Tag搜索联盟战斗数据失败!")
end
--突袭玩家城市
function NetManager:getStrikePlayerCityPromise(dragonType,defencePlayerId)
    return get_blocking_request_promise("logic.allianceHandler.strikePlayerCity",
        {dragonType=dragonType,defencePlayerId=defencePlayerId},
        "突袭玩家城市失败!"):done(get_player_response_msg)
end
--攻打玩家城市
function NetManager:getAttackPlayerCityPromise(dragonType, soldiers,defencePlayerId)
    return get_blocking_request_promise("logic.allianceHandler.attackPlayerCity",
        {defencePlayerId=defencePlayerId,dragonType=dragonType,soldiers = soldiers},"攻打玩家城市失败!"):done(get_player_response_msg)
end

--设置驻防使用的龙
function NetManager:getSetDefenceDragonPromise(dragonType)
    return get_none_blocking_request_promise("logic.playerHandler.setDefenceDragon",
        {dragonType=dragonType},
        "设置驻防使用的龙失败!"):done(get_player_response_msg)
end
--取消龙驻防
function NetManager:getCancelDefenceDragonPromise()
    return get_none_blocking_request_promise("logic.playerHandler.cancelDefenceDragon",
        nil,
        "取消龙驻防失败!"):done(get_player_response_msg)
end
--攻击村落
function NetManager:getAttackVillagePromise(dragonType,soldiers,defenceAllianceId,defenceVillageId)
    return get_blocking_request_promise("logic.allianceHandler.attackVillage",
        {defenceVillageId = defenceVillageId,defenceAllianceId=defenceAllianceId,dragonType=dragonType,soldiers = soldiers},"攻打村落失败!"):done(get_player_response_msg)
end
--从村落撤退
function NetManager:getRetreatFromVillagePromise(allianceId,eventId)
    return get_blocking_request_promise("logic.allianceHandler.retreatFromVillage",
        {villageEventId = eventId},"村落撤退失败!"):done(get_player_response_msg)
end
--突袭村落
function NetManager:getStrikeVillagePromise(dragonType,defenceAllianceId,defenceVillageId)
    return get_blocking_request_promise("logic.allianceHandler.strikeVillage",
        {dragonType = dragonType,defenceAllianceId = defenceAllianceId,defenceVillageId=defenceVillageId},"突袭村落失败!"):done(get_player_response_msg)
end
--查看敌方进攻行军事件详细信息
function NetManager:getAttackMarchEventDetailPromise(eventId,enemyAllianceId)
    return get_blocking_request_promise("logic.allianceHandler.getAttackMarchEventDetail",
        {eventId = eventId,enemyAllianceId = enemyAllianceId},"获取行军事件数据失败!"):done(get_player_response_msg)
end
--查看敌方突袭行军事件详细信息
function NetManager:getStrikeMarchEventDetailPromise(eventId,enemyAllianceId)
    return get_blocking_request_promise("logic.allianceHandler.getStrikeMarchEventDetail",
        {eventId = eventId,enemyAllianceId = enemyAllianceId},"获取突袭事件数据失败!"):done(get_player_response_msg)
end
--查看协助部队行军事件详细信息
function NetManager:getHelpDefenceMarchEventDetailPromise(eventId,allianceId)
    return get_blocking_request_promise("logic.allianceHandler.getHelpDefenceMarchEventDetail",
        {eventId = eventId,allianceId = allianceId},"获取协防事件数据失败!"):done(get_player_response_msg)
end
--查看协防部队详细信息
function NetManager:getHelpDefenceTroopDetailPromise(playerId,helpedByPlayerId)
    return get_blocking_request_promise("logic.allianceHandler.getHelpDefenceTroopDetail",
        {playerId = playerId,helpedByPlayerId = helpedByPlayerId},"查看协防部队详细信息失败!"):done(get_player_response_msg)
end
-- 出售商品
function NetManager:getSellItemPromise(type,name,count,price)
    return get_blocking_request_promise("logic.playerHandler.sellItem", {
        type = type,
        name = name,
        count = count,
        price = price,
    }, "出售商品失败!"):done(get_player_response_msg)
end
-- 获取商品列表
function NetManager:getGetSellItemsPromise(type,name)
    return get_blocking_request_promise("logic.playerHandler.getSellItems", {
        type = type,
        name = name,
    }, "获取商品列表失败!"):done(get_player_response_msg)
end
-- 购买出售的商品
function NetManager:getBuySellItemPromise(itemId)
    return get_blocking_request_promise("logic.playerHandler.buySellItem", {
        itemId = itemId
    }, "购买出售的商品失败!"):done(get_player_response_msg)
end
-- 获取出售后赚取的银币
function NetManager:getGetMyItemSoldMoneyPromise(itemId)
    return get_blocking_request_promise("logic.playerHandler.getMyItemSoldMoney", {
        itemId = itemId
    }, "获取出售后赚取的银币失败!"):done(get_player_response_msg)
end
-- 下架商品
function NetManager:getRemoveMySellItemPromise(itemId)
    return get_blocking_request_promise("logic.playerHandler.removeMySellItem", {
        itemId = itemId
    }, "下架商品失败!"):done(get_player_response_msg)
end
--升级生产科技
function NetManager:getUpgradeProductionTechPromise(techName,finishNow)
    return get_blocking_request_promise("logic.playerHandler.upgradeProductionTech", {
        techName = techName,
        finishNow = finishNow,
    }, "升级生产科技失败!"):done(get_player_response_msg):done(function()
        if finishNow then
            app:GetAudioManager():PlayeEffectSoundWithKey("COMPLETE")
        end
    end)
end
-- 升级军事科技
local function upgrade_military_tech_promise(techName,finishNow)
    return get_blocking_request_promise("logic.playerHandler.upgradeMilitaryTech", {
        techName = techName,
        finishNow = finishNow,
    }, "升级军事科技失败!"):done(get_player_response_msg):done(function()
        if finishNow then
            app:GetAudioManager():PlayeEffectSoundWithKey("COMPLETE")
        end
    end)
end


function NetManager:getInstantUpgradeMilitaryTechPromise(techName)
    return upgrade_military_tech_promise(techName,true)
end
function NetManager:getUpgradeMilitaryTechPromise(techName)
    return upgrade_military_tech_promise(techName,false)
end
-- 士兵晋级
local function upgrade_soldier_star_promise(soldierName,finishNow)
    return get_blocking_request_promise("logic.playerHandler.upgradeSoldierStar", {
        soldierName = soldierName,
        finishNow = finishNow,
    }, "士兵晋级失败!"):done(get_player_response_msg)
end
function NetManager:getInstantUpgradeSoldierStarPromise(soldierName)
    return upgrade_soldier_star_promise(soldierName,true)
end
function NetManager:getUpgradeSoldierStarPromise(soldierName)
    return upgrade_soldier_star_promise(soldierName,false)
end
--设置pve数据
function NetManager:getSetPveDataPromise(pveData, is_none_blocking, need_catch)
    if is_none_blocking then
        return get_none_blocking_request_promise("logic.playerHandler.setPveData",
            pveData, "设置pve数据失败!", need_catch):done(get_player_response_msg)
    else
        return get_blocking_request_promise("logic.playerHandler.setPveData",
            pveData, "设置pve数据失败!", need_catch):done(get_player_response_msg)
    end
end
--为联盟成员添加荣耀值
function NetManager:getGiveLoyaltyToAllianceMemberPromise(memberId,count)
    return get_blocking_request_promise("logic.allianceHandler.giveLoyaltyToAllianceMember",
        {
            memberId=memberId,
            count=count
        },
        "为联盟成员添加荣耀值失败!"):done(get_player_response_msg)
end
--购买道具
function NetManager:getBuyItemPromise(itemName,count)
    return get_blocking_request_promise("logic.playerHandler.buyItem", {
        itemName = itemName,
        count = count,
    }, "购买道具失败!"):done(get_player_response_msg):done(function ()
        GameGlobalUI:showTips(_("提示"),string.format(_("购买%s道具成功"),Localize_item.item_name[itemName]))
        ext.market_sdk.onPlayerBuyGameItems(itemName,count,DataUtils:GetItemPriceByItemName(itemName))
        app:GetAudioManager():PlayeEffectSoundWithKey("BUY_ITEM")
    end)
end
--使用道具
function NetManager:getUseItemPromise(itemName,params)
    return get_blocking_request_promise("logic.playerHandler.useItem", {
        itemName = itemName,
        params = params,
    }, "使用道具失败!"):done(get_player_response_msg):done(function ()
        if not (string.find(itemName,"dragonChest") or string.find(itemName,"chest")) then
            GameGlobalUI:showTips(_("提示"),string.format(_("使用%s道具成功"),Localize_item.item_name[itemName]))
        end
        if itemName == "torch" then
            app:GetAudioManager():PlayeEffectSoundWithKey("UI_BUILDING_DESTROY")
        else
            app:GetAudioManager():PlayeEffectSoundWithKey("USE_ITEM")
        end
        ext.market_sdk.onPlayerUseGameItems(itemName,1)
    end)
end
--购买并使用道具
function NetManager:getBuyAndUseItemPromise(itemName,params)
    return get_blocking_request_promise("logic.playerHandler.buyAndUseItem", {
        itemName = itemName,
        params = params,
    }, "购买并使用道具失败!"):done(get_player_response_msg):done(function()
        GameGlobalUI:showTips(_("提示"),string.format(_("使用%s道具成功"),Localize_item.item_name[itemName]))
        if itemName == "torch" then
            app:GetAudioManager():PlayeEffectSoundWithKey("UI_BUILDING_DESTROY")
        else
            app:GetAudioManager():PlayeEffectSoundWithKey("USE_ITEM")
        end
        ext.market_sdk.onPlayerBuyGameItems(itemName,1,DataUtils:GetItemPriceByItemName(itemName))
        ext.market_sdk.onPlayerUseGameItems(itemName,1)
    end)
end

--联盟商店补充道具
function NetManager:getAddAllianceItemPromise(itemName,count)
    return get_blocking_request_promise("logic.allianceHandler.addShopItem",
        {
            itemName = itemName,
            count = count,
        },
        "联盟商店补充道具失败!"):done(get_player_response_msg)
end
--购买联盟商店的道具
function NetManager:getBuyAllianceItemPromise(itemName,count)
    return get_blocking_request_promise("logic.allianceHandler.buyShopItem",
        {
            itemName = itemName,
            count = count,
        },
        "购买联盟商店的道具失败!"):done(get_player_response_msg)
end
--玩家内购
function NetManager:getVerifyIAPPromise(transactionId,receiptData)
    return get_none_blocking_request_promise("logic.playerHandler.addPlayerBillingData",
        {
            transactionId=transactionId,receiptData=receiptData
        }
        ,"玩家内购失败", true):next(get_player_response_msg)
end
--获得每日登陆奖励
function NetManager:getDay60RewardPromise()
    return get_blocking_request_promise("logic.playerHandler.getDay60Reward",
        nil,
        "获得每日登陆奖励失败!"):done(get_player_response_msg)
end

-- 获取每日在线奖励
function NetManager:getOnlineRewardPromise(timePoint)
    return get_blocking_request_promise("logic.playerHandler.getOnlineReward",
        {timePoint = timePoint},
        "获取每日在线奖励失败!"):done(get_player_response_msg)
end

-- 获取在线天数奖励
function NetManager:getDay14RewardPromise()
    return get_blocking_request_promise("logic.playerHandler.getDay14Reward",
        nil,
        "获取在线天数奖励失败!"):done(get_player_response_msg)
end
-- 首充奖励
function NetManager:getFirstIAPRewardsPromise()
    return get_blocking_request_promise("logic.playerHandler.getFirstIAPRewards",
        nil,
        "获取首充奖励失败!"):done(get_player_response_msg)
end

-- 新手冲级奖励
function NetManager:getLevelupRewardPromise(levelupIndex)
    return get_blocking_request_promise("logic.playerHandler.getLevelupReward",
        {levelupIndex = levelupIndex},
        "获取新手冲级奖励失败!"):done(get_player_response_msg)
end
-- 普通gacha
function NetManager:getNormalGachaPromise()
    return get_blocking_request_promise("logic.playerHandler.gacha",
        {type = "normal"},
        "普通gacha失败!"):done(get_player_response_msg)
end
-- 高级gacha
function NetManager:getAdvancedGachaPromise()
    return get_blocking_request_promise("logic.playerHandler.gacha",
        {type = "advanced"},
        "高级gacha失败!"):done(get_player_response_msg)
end


-- 通过Selina的考验
function NetManager:getPassSelinasTestPromise()
    return get_blocking_request_promise("logic.playerHandler.passSelinasTest",
        nil,
        "通过Selina的考验!"):done(get_player_response_msg)
end
-- 获取成就任务奖励
function NetManager:getGrowUpTaskRewardsPromise(taskType, taskId)
    return get_blocking_request_promise("logic.playerHandler.getGrowUpTaskRewards",{
        taskType = taskType,
        taskId = taskId
    }, "领取奖励失败!"):done(get_player_response_msg)
end

-- 领取日常任务奖励
function NetManager:getDailyTaskRewards(taskType)
    return get_blocking_request_promise("logic.playerHandler.getDailyTaskRewards",
        {taskType = taskType},
        "领取日常任务奖励!"):done(get_player_response_msg)
end

-- 设置玩家Apple Push Notification Id
function NetManager:getSetApnIdPromise(apnId)
    return get_none_blocking_request_promise("logic.playerHandler.setApnId",{apnId=apnId},
        "设置玩家Apple Push失败"):done(get_player_response_msg)
end

-- 获取排行榜
function NetManager:getPlayerRankPromise(rankType, fromRank)
    return get_blocking_request_promise("rank.rankHandler.getPlayerRankList",{
        rankType = rankType,
        fromRank = fromRank or 0,
    },"获取排行榜失败!")
end
function NetManager:getAllianceRankPromise(rankType, fromRank)
    return get_blocking_request_promise("rank.rankHandler.getAllianceRankList",{
        allianceId = Alliance_Manager:GetMyAlliance():Id(),
        rankType = rankType,
        fromRank = fromRank or 0,
    },"获取排行榜失败!")
end
-- 获取GameCenter账号绑定状态
function NetManager:getGcBindStatusPromise(gcId)
    return get_none_blocking_request_promise("logic.playerHandler.getGcBindStatus",{gcId=gcId},
        "获取GameCenter账号绑定状态失败")
end
-- 设置GameCenter Id
function NetManager:getBindGcIdPromise(gcId)
    return get_none_blocking_request_promise("logic.playerHandler.bindGcId",{gcId=gcId},
        "设置GameCenter失败"):done(get_player_response_msg)
end

-- 切换GameCenter账号
function NetManager:getSwitchGcIdPromise(gcId)
    return get_none_blocking_request_promise("logic.playerHandler.switchGcId",{gcId=gcId},
        "切换GameCenter账号失败")
end

-- 强制切换GameCenter账号到原GameCenter账号下的玩家数据,当前未绑定的玩家账号数据会丢失
function NetManager:getForceSwitchGcIdPromise(gcId)
    return get_none_blocking_request_promise("logic.playerHandler.forceSwitchGcId",{gcId=gcId},
        "切换GameCenter账号失败")
end

-- 获取联盟其他玩家赠送的礼品
function NetManager:getIapGiftPromise(giftId)
    return get_blocking_request_promise("logic.playerHandler.getIapGift",{
        giftId = giftId,
    },"获取联盟其他玩家赠送的礼品!"):done(get_player_response_msg)
end


-- 完成fte
function NetManager:getFinishFTE()
    return get_blocking_request_promise("logic.playerHandler.finishFTE", nil,"完成fte失败!"):done(get_player_response_msg)
end


--获取服务器列表
function NetManager:getServersPromise()
    return get_blocking_request_promise("logic.playerHandler.getServers",nil,"获取服务器列表失败!")
end

-- 切换服务器
function NetManager:getSwitchServer(serverId)
    return get_none_blocking_request_promise("logic.playerHandler.switchServer",{serverId=serverId},"切换服务器失败!")
end

-- 购买联盟盟主职位
function NetManager:getBuyAllianceArchon()
    return get_blocking_request_promise("logic.allianceHandler.buyAllianceArchon"):done(get_player_response_msg)
end
--领取首次加入联盟奖励
function NetManager:getFirstJoinAllianceRewardPromise()
    return get_blocking_request_promise("logic.playerHandler.getFirstJoinAllianceReward",nil,"领取首次加入联盟奖励失败!"):done(get_player_response_msg)
end
--获取玩家城墙血量
function NetManager:getPlayerWallInfoPromise(memberId)
    return get_blocking_request_promise("logic.playerHandler.getPlayerWallInfo",{memberId = memberId},"领取首次加入联盟奖励失败!")
end
--设置玩家语言
function NetManager:getSetPlayerLanguagePromise(language_code)
    return get_blocking_request_promise("logic.playerHandler.setPlayerLanguage",{language = language_code},"设置玩家语言失败!")
end
----------------------------------------------------------------------------------------------------------------
function NetManager:getUpdateFileList(cb)
    local updateServer = self.m_updateServer.host .. ":" .. self.m_updateServer.port .. "/update/res/fileList.json"
    self.m_netService:get(updateServer, nil, function(success, statusCode, msg)
        cb(success and statusCode == 200, msg)
    end)
end
function NetManager:downloadFile(fileInfo, cb, progressCb)
    local downloadUrl = self.m_updateServer.host .. ":" .. self.m_updateServer.port .. "/update/" .. fileInfo.path
    local filePath = GameUtils:getUpdatePath() .. fileInfo.path
    local docPath = LuaUtils:getDocPathFromFilePath(filePath)
    if not ext.isDirectoryExist(docPath) then
        if not ext.createDirectory(docPath) then
            cb(false)
            return
        end
    end

    if cc.FileUtils:getInstance():isFileExist(filePath) then
        local crc32 = ext.crc32(filePath)
        if crc32 == fileInfo.crc32 then
            local file = io.open(filePath, "rb")
            if not file then
                cb(false)
                return
            end
            local fileLength = file:seek("end")
            file:close()
            progressCb(fileLength, fileLength)
            cb(true)
            return
        end
    end

    self.m_netService:get(downloadUrl, nil, function(success, statusCode, msg)
        if success and statusCode == 200 then
            local file = io.open(filePath, "w")
            if not file then
                cb(false)
                return
            end
            file:write(msg)
            file:close()
            local fileLength = string.len(msg)
            progressCb(fileLength, fileLength)
            cb(true)
        else
            cb(false)
        end
    end, function(totalSize, currentSize)
        progressCb(totalSize, currentSize)
    end)
end





























