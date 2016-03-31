--
-- Author: Kenny Dai
-- Date: 2015-05-07 21:00:02
--
local OtherApi = {}

local intInit = GameDatas.PlayerInitData.intInit

-- 个人修改地形
function OtherApi:SetCityTerrain()
    local rand = math.random(3)
    local current_t = User.basicInfo.terrain
    if rand == 1 and current_t ~= "grassLand" then
        return NetManager:getChangeToGrassPromise()
    elseif rand == 2 and current_t ~= "desert" then
        return NetManager:getChangeToDesertPromise()
    elseif current_t ~= "iceField" then
        return NetManager:getChangeToIceFieldPromise()
    end
end

-- 设置头像
function OtherApi:SetPlayerIcon()
    local icon_key = math.random(11)
    local can_set = false
    -- 前六个默认解锁
    if icon_key < 7 then
        can_set = true
    end
    if icon_key == 7 then -- 刺客
        can_set = User.basicInfo.kill >= 1000000
    elseif icon_key == 8 then -- 将军
        can_set = User.basicInfo.power >= 1000000
    elseif icon_key == 9 then -- 术士
        can_set = User:GetVipLevel() == 10
    elseif icon_key == 10 then -- 贵妇
        can_set = City:GetFirstBuildingByType("keep"):GetLevel() >= 40
    elseif icon_key == 11 then -- 旧神
        can_set = User:IsAllPassed()
    end
    if can_set then
        return NetManager:getSetPlayerIconPromise(icon_key)
    end
end

--转换生产建筑类型
function OtherApi:SwitchBuilding()
    local location_id = math.random(10,13)
    -- 建筑是否已解锁
    if not app:IsBuildingUnLocked(location_id) then
        return
    end
    local current_building = City:GetBuildingByLocationId(location_id)
    if User:GetGemValue() < intInit.switchProductionBuilding.value then
        return
    elseif (City:GetMaxHouseCanBeBuilt(current_building:GetHouseType())-current_building:GetMaxHouseNum())<#City:GetBuildingByType(current_building:GetHouseType()) then
        return
    elseif current_building:IsUpgrading() then
        return
    end
    local switch_to_building_type
    local types = {
        "foundry",
        "stoneMason",
        "lumbermill",
        "mill",
    }
    while switch_to_building_type == current_building:GetType() or not switch_to_building_type do
        switch_to_building_type = types[math.random(4)]
    end
    local config
    for i,v in ipairs(GameDatas.Buildings.buildings) do
        if v.name == switch_to_building_type then
            config = v
        end
    end
    -- 等级大于5级时有升级前置条件
    if current_building:GetLevel()>5 then
        local configParams = string.split(config.preCondition,"_")
        local preType = configParams[1]
        local preName = configParams[2]
        local preLevel = tonumber(configParams[3])
        local limit
        if preType == "building" then
            local find_buildings = City:GetBuildingByType(preName)
            for i,v in ipairs(find_buildings) do
                if v:GetLevel()>=current_building:GetLevel()+preLevel then
                    limit = true
                end
            end
        else
            City:IteratorDecoratorBuildingsByFunc(function (index,house)
                if house:GetType() == preName and house:GetLevel()>=current_building:GetLevel()+preLevel then
                    limit = true
                end
            end)
        end
        if not limit then
            return
        end
    end
    print("SwitchBuilding ",current_building:GetType()," to ",switch_to_building_type)
    return NetManager:getSwitchBuildingPromise(location_id,switch_to_building_type)
end
-- 抽奖
function OtherApi:Gacha()
    local normal_gacha = math.random(2) == 2
    if normal_gacha then
        if User:GetOddFreeNormalGachaCount() > 0
            or User:GetResValueByType("casinoToken") >= intInit.casinoTokenNeededPerNormalGacha.value then
            return NetManager:getNormalGachaPromise()
        end
    else
        if User:GetResValueByType("casinoToken") >= intInit.casinoTokenNeededPerAdvancedGacha.value then
            return NetManager:getAdvancedGachaPromise()
        end
    end
end

-- 所有邮箱api
function OtherApi:MailApi()
    local api_type = {
        "send_mail",
        "get_inbox_mail",
        "read_mail",
        "save_mail",
        "un_save_mail",
        "get_saved_mail",
        "get_send_mail",
        "delete_mail",
        "read_report",
        "save_report",
        "un_save_report",
        "delete_report",
        "get_report",
        "get_saved_report",
    }

    local excute_index = api_type[math.random(#api_type)]
    if excute_index == "send_mail" then
        -- 给联盟成员发送
        if not Alliance_Manager:GetMyAlliance():IsDefault() then
            local send_count = math.random(Alliance_Manager:GetMyAlliance():GetMembersCount())
            local count = 1
            local memberId
            Alliance_Manager:GetMyAlliance():IteratorAllMembers(function ( member )
                if count == send_count and member.id ~= User:Id() then
                    memberId = member.id
                    return true
                end
            end)
            if not memberId then
                return
            end
            return NetManager:getSendPersonalMailPromise(memberId, "机器人邮件", "只是一封邮件" )
        end
    elseif excute_index == "get_inbox_mail"then
        local fromIndex = MailManager:GetMails() and #MailManager:GetMails() or 0
        return NetManager:getFetchMailsPromise(fromIndex)
    elseif excute_index == "read_mail"then
        if MailManager:GetMails() then
            local read_mails_id = {}
            for i,mail in ipairs(MailManager:GetMails()) do
                if not mail.isRead then
                    table.insert(read_mails_id, mail.id)
                end
            end
            if #read_mails_id > 0 then
                return NetManager:getReadMailsPromise(read_mails_id)
            end
        end
    elseif excute_index == "save_mail"then
        if MailManager:GetMails() then
            for i,mail in ipairs(MailManager:GetMails()) do
                if not mail.isSaved then
                    return NetManager:getSaveMailPromise(mail.id)
                end
            end
        end
    elseif excute_index == "un_save_mail"then
        if MailManager:GetMails() then
            for i,mail in ipairs(MailManager:GetMails()) do
                if mail.isSaved then
                    return NetManager:getUnSaveMailPromise(mail.id)
                end
            end
        end
    elseif excute_index == "get_saved_mail"then
        local fromIndex = MailManager:GetSavedMails() and #MailManager:GetSavedMails() or 0
        return NetManager:getFetchSavedMailsPromise(fromIndex)
    elseif excute_index == "get_send_mail"then
        local fromIndex = MailManager:GetSendMails() and #MailManager:GetSendMails() or 0
        return NetManager:getFetchSendMailsPromise(fromIndex)
    elseif excute_index == "delete_mail"then
        local mails = MailManager:GetMails()
        if mails and #mails > 0 then
            local delete_count = math.random(#mails)
            local ids = {}
            for i=1,delete_count do
                table.insert(ids, mails[i].id)
            end
            return NetManager:getDeleteMailsPromise(ids)
        end
    elseif excute_index == "read_report"then
        if MailManager:GetReports() then
            local read_reports_id = {}
            for i,report in ipairs(MailManager:GetReports()) do
                if not report:IsRead() then
                    table.insert(read_reports_id, report:Id())
                end
            end
            if #read_reports_id > 0 then
                return NetManager:getReadReportsPromise(read_reports_id)
            end
        end
    elseif excute_index == "save_report"then
        if MailManager:GetReports() then
            for i,report in ipairs(MailManager:GetReports()) do
                if not report:IsSaved() then
                    return NetManager:getSaveReportPromise(report:Id())
                end
            end
        end
    elseif excute_index == "un_save_report"then
        if MailManager:GetReports() then
            for i,report in ipairs(MailManager:GetReports()) do
                if report:IsSaved() then
                    return NetManager:getUnSaveReportPromise(report:Id())
                end
            end
        end
    elseif excute_index == "delete_report"then
        local reports = MailManager:GetReports()
        if reports and #reports > 0 then
            local delete_count = math.random(#reports)
            local ids = {}
            for i=1,delete_count do
                table.insert(ids, reports[i]:Id())
            end
            return NetManager:getDeleteReportsPromise(ids)
        end
    elseif excute_index == "get_report"then
        local fromIndex = MailManager:GetReports() and #MailManager:GetReports() or 0
        return NetManager:getReportsPromise(fromIndex)
    elseif excute_index == "get_saved_report"then
        local fromIndex = MailManager:GetSavedReports() and #MailManager:GetSavedReports() or 0
        return NetManager:getSavedReportsPromise(fromIndex)
    end
end

-- 道具api
function OtherApi:Items()
    local is_buy = math.random(2) == 2
    if is_buy then
        local item_index = math.random(4)
        local items
        if item_index == 1 then
            items = UtilsForItem:GetBuffItemsInfo()
        elseif item_index == 2 then
            items = UtilsForItem:GetResourcetItemsInfo()
        elseif item_index == 3 then
            items = UtilsForItem:GetSpeedUpItemsInfo()
        elseif item_index == 4 then
            items = UtilsForItem:GetSpecialItemsInfo()
        end
        local buy_index = math.random(LuaUtils:table_size(items))
        local count = 0
        for k,v in pairs(items) do
            count = count + 1
            if count == buy_index then
                print("购买一个道具：",v.name)
                return NetManager:getBuyItemPromise(v.name,1)
            end
        end
    end
end
-- 获取排行榜
function OtherApi:GetRank()
    local random = math.random(4)
    print("获取排行榜信息",random)
    if random == 1 then
        return NetManager:getPlayerRankPromise("power")
    elseif random == 2 then
        return NetManager:getAllianceRankPromise("power")
    elseif random == 3 then
        return NetManager:getPlayerRankPromise("kill")
    elseif random == 4 then
        return NetManager:getAllianceRankPromise("kill")
    end
end
-- vip
function OtherApi:VIP()
    if UtilsForVip:IsVipActived(User) then
        -- 增加vip点数
        return  NetManager:getBuyAndUseItemPromise("vipPoint_"..math.random(3,4),{})
    else
        return  NetManager:getBuyAndUseItemPromise("vipActive_"..math.random(3,5),{})
    end
end
-- 聊天
function OtherApi:Chat()
    local channels =
        {
            "global",
            "alliance",
        }

    local alliance = Alliance_Manager:GetMyAlliance()
    local channel
    if not alliance:IsDefault() then
        channel = channels[math.random(2)]
    else
        channel = channels[1]
    end
    if math.random(10) < 3 then
        return NetManager:getSendChatPromise(channel,"我是"..User.basicInfo.name)
    end
end
local function setRun()
    app:setRun()
end

-- 散乱操作方法组
local function SetCityTerrain()
    local p = OtherApi:SetCityTerrain()
    if p then
        p:always(setRun)
    else
        setRun()
    end
end
local function SwitchBuilding()
    local p = OtherApi:SwitchBuilding()
    if p then
        p:always(setRun)
    else
        setRun()
    end
end

local function SetPlayerIcon()
    local p = OtherApi:SetPlayerIcon()
    if p then
        p:always(setRun)
    else
        setRun()
    end
end
local function Gacha()
    local p = OtherApi:Gacha()
    if p then
        p:always(setRun)
    else
        setRun()
    end
end
local function MailApi()
    local p = OtherApi:MailApi()
    if p then
        p:always(setRun)
    else
        setRun()
    end
end
local function GetRank()
    local p = OtherApi:GetRank()
    if p then
        p:always(setRun)
    else
        setRun()
    end
end
local function VIP()
    local p = OtherApi:VIP()
    if p then
        p:always(setRun)
    else
        setRun()
    end
end
local function Chat()
    local p = OtherApi:Chat()
    if p then
        p:always(setRun)
    else
        setRun()
    end
end

return {
    setRun,
    SetCityTerrain,
    -- SwitchBuilding,
    SetPlayerIcon,
    MailApi,
    Gacha,
    GetRank,
    VIP,
    Chat,
}
















