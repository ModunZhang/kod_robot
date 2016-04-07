--
-- Author: Kenny Dai
-- Date: 2015-05-07 21:20:11
--
local AllianceApi = {}
local intInit = GameDatas.AllianceInitData.intInit
local moveLimit = GameDatas.AllianceMap.moveLimit
local WidgetAllianceHelper = import("app.widget.WidgetAllianceHelper")

function AllianceApi:CreateAlliance()
    if Alliance_Manager:GetMyAlliance():IsDefault() then
        local name , tag = DataUtils:randomAllianceNameTag()
        local random = math.random(3)
        local tmp = {"desert","iceField","grassLand"}
        local terrian = tmp[random]
        print("创建联盟")
        return NetManager:getCreateAlliancePromise(name,tag,"ALL",terrian,WidgetAllianceHelper.new():RandomFlagStr())
    end
end
function AllianceApi:JoinAlliance(id)
    if id then
        print("加入联盟：",id)
        return NetManager:getJoinAllianceDirectlyPromise(id)
    end
end
function AllianceApi:RequestToJoinAlliance()
    -- 从聊天中找到一个需要申请加入的联盟
    local alliance = Alliance_Manager:GetMyAlliance()
    if alliance:IsDefault() then
        NetManager:getFetchChatPromise("global"):done(function(response)
            local chat_data = response.msg.chats
            local chat_count = #chat_data
            local call_over = true
            local call_count = 1
            while call_count <= chat_count and call_over do
                call_over = false
                local chat = chat_data[call_count]
                if chat.allianceTag ~="" then
                    NetManager:getSearchAllianceByTagPromsie(chat.allianceTag):done(function ( response )
                        if #response.msg.allianceDatas == 0 then
                            return
                        end
                        local data = response.msg.allianceDatas[1]
                        print("data.joinType ",data.joinType ~= "all",data.joinType )
                        if data.joinType ~= "all" then
                            dump(User.requestToAllianceEvents,"User:RequestToAllianceEvents()")
                            local is_requested = false
                            for i,v in ipairs(User.requestToAllianceEvents) do
                                if v.id == data.id  then
                                    is_requested = true
                                end
                            end
                            if not is_requested then
                                NetManager:getRequestToJoinAlliancePromise(data.id):always(function ()
                                    call_count = call_count + 1
                                    call_over = true
                                    print("getRequestToJoinAlliancePromise!!!!!!!!!")
                                end)
                            else
                                call_count = call_count + 1
                                call_over = true
                            end
                        else
                            call_count = call_count + 1
                            call_over = true
                        end
                    end)
                else
                    call_count = call_count + 1
                    call_over = true
                end
            end
        end)
    end
end
function AllianceApi:CancelJoinAlliance()
    local alliance = Alliance_Manager:GetMyAlliance()
    if alliance:IsDefault() and math.random(100) < 5 then
        for i,v in ipairs(User.requestToAllianceEvents) do
            return NetManager:getCancelJoinAlliancePromise(v.id)
        end
    end
end
function AllianceApi:ApproveOrRejectJoinAllianceRequest()
    local alliance = Alliance_Manager:GetMyAlliance()
    if not alliance:IsDefault() and alliance:GetSelf():CanHandleAllianceApply() and alliance.basicInfo.status ~= "prepare" and alliance.basicInfo.status ~= "fight" then
        local joinRequestEvents = alliance.joinRequestEvents
        for i,v in ipairs(joinRequestEvents) do
            if math.random(2) == 2 then
                print("getApproveJoinAllianceRequestPromise")
                NetManager:getApproveJoinAllianceRequestPromise(v.id)
            else
                print("getRemoveJoinAllianceReqeustsPromise")
                NetManager:getRemoveJoinAllianceReqeustsPromise({v.id})
            end
            break
        end
    end
end
function AllianceApi:InviteToJoinAlliance()
    local alliance = Alliance_Manager:GetMyAlliance()
    if not alliance:IsDefault() and alliance:GetSelf():CanInvatePlayer()then
        NetManager:getFetchChatPromise("global"):done(function(response)
            local chat_data = response.msg.chats
            local chat_count = #chat_data
            local call_over = true
            local call_count = 1
            while call_count <= chat_count and call_over do
                call_over = false
                local chat = chat_data[call_count]
                if chat.allianceTag == "" and chat.id ~= User:Id() then
                    NetManager:getInviteToJoinAlliancePromise(chat.id):always(function ()
                        call_count = call_count + 1
                        call_over = true
                    end)
                else
                    call_count = call_count + 1
                    call_over = true
                end
            end
        end)
    end
end
function AllianceApi:getQuitAlliancePromise()
    if not Alliance_Manager:GetMyAlliance():IsDefault() and
        Alliance_Manager:GetMyAlliance().basicInfo.status ~= "prepare" and
        Alliance_Manager:GetMyAlliance().basicInfo.status ~= "fight" and not Alliance_Manager:HasToMyCityEvents() then
        if math.random(100) < 5 then
            local members = Alliance_Manager:GetMyAlliance():GetAllMembers()
            if LuaUtils:table_size(members) == 1 or not Alliance_Manager:GetMyAlliance():GetSelf():IsArchon() then
                return NetManager:getQuitAlliancePromise()
            end
        end
    end
end
-- 踢出或者改变成员职位
function AllianceApi:AllianceMemberApi()
    local alliance = Alliance_Manager:GetMyAlliance()
    if not alliance:IsDefault() and math.random(100) < 5 then
        local members = alliance:GetAllMembers()
        if LuaUtils:table_size(members) == 1 then
            return
        end
        local member_index = math.random(LuaUtils:table_size(members))
        local count = 0
        local member
        local me = alliance:GetSelf()
        while not member do
            alliance:IteratorAllMembers(function ( v )
                count = count + 1
                if count == member_index then
                    if v:Id() == me:Id() then
                        member_index = member_index + 1
                    else
                        member = v
                    end
                end
            end)
        end
        -- 踢出
        local auth,title_can = me:CanKickOutMember(member:Title())
        if not title_can or not auth or alliance.basicInfo.status == "fight" or alliance.basicInfo.status == "prepare" then
            return
        end
        return NetManager:getKickAllianceMemberOffPromise(member:Id())
    end
end
-- 联盟捐赠
function AllianceApi:Contribute()
    if not Alliance_Manager:GetMyAlliance():IsDefault() and Alliance_Manager:GetMyAlliance().basicInfo.status ~= "fight" and Alliance_Manager:GetMyAlliance().basicInfo.status ~= "prepare"  then
        local donate_types = {
            "wood",
            "stone",
            "food",
            "iron",
            "coin",
            "gem",
        }
        local r_type = donate_types[math.random(#donate_types)]

        local donate_status = User.allianceDonate
        local donate_level = donate_status[r_type]
        local donate
        for _,v in pairs(GameDatas.AllianceInitData.donate) do
            if v.level == donate_level and r_type == v.type then
                donate = v
            end
        end
        local count  = donate.count
        local r_count
        if r_type == "gem" then
            r_count = User:GetGemValue()
        else
            r_count = User:GetResValueByType(r_type)
        end
        if r_count < count then
            return
        end
        print("联盟捐赠成功:",r_type,count,donate_level)
        return NetManager:getDonateToAlliancePromise(r_type)
    end
end
-- 升级联盟建筑
function AllianceApi:UpgradeAllianceBuilding()
    if not Alliance_Manager:GetMyAlliance():IsDefault() then
        local alliance = Alliance_Manager:GetMyAlliance()
        local building_names = {
            "orderHall",
            "palace",
            "shop",
            "shrine",
            "watchTower",
        }
        local building_name = building_names[math.random(#building_names)]
        local building = alliance:GetAllianceBuildingInfoByName(building_name)
        local building_config = GameDatas.AllianceBuilding[building.name]
        local now_c = building_config[building.level+1]
        if not alliance:GetSelf():CanUpgradeAllianceBuilding() then
            return
        elseif alliance.basicInfo.honour < now_c.needHonour then
            return
        end
        print("升级联盟建筑:",building.name,"到",building.level+1)
        return NetManager:getUpgradeAllianceBuildingPromise(building.name)
    end
end
-- 升级联盟村落
function AllianceApi:UpgradeAllianceVillage()
    local alliance = Alliance_Manager:GetMyAlliance()
    if not alliance:IsDefault() and alliance:GetSelf():CanUpgradeAllianceBuilding() then
        local villages = {
            "foodVillage",
            "ironVillage",
            "stoneVillage",
            "woodVillage",
        }
        local village_type = villages[math.random(#villages)]
        local village_level = alliance:GetVillageLevels()[village_type]
        local config = GameDatas.AllianceVillage[village_type]
        local to_level = village_level + 1 > #config and village_level or (village_level + 1)
        local level_config = config[to_level]
        if village_level == #config then
            return
        end
        if alliance.basicInfo.honour >= level_config.needHonour then
            print("升级联盟村落:",village_type,to_level)
            return NetManager:getUpgradeAllianceVillagePromise(village_type)
        end
    end
end
-- 修改联盟设置
function AllianceApi:EditAllianceInfo()
    local alliance = Alliance_Manager:GetMyAlliance()
    local me = alliance:GetSelf()
    if not alliance:IsDefault()  and alliance.basicInfo.status ~= "fight" and alliance.basicInfo.status ~= "prepare" then
        local excute_fun = math.random(100)
        -- local excute_fun = 9
        if excute_fun <= 5 then
            local need_honour = intInit.editAllianceTerrianHonour.value
            if me:CanEditAlliance() and need_honour <= alliance.basicInfo.honour then
                local terrains = {
                    "grassLand",
                    "desert",
                    "iceField",
                }
                local current_terrain = alliance.basicInfo.terrain
                local to_terrain = clone(current_terrain)
                while to_terrain == current_terrain do
                    to_terrain = terrains[math.random(#terrains)]
                end
                print("修改联盟地形:",current_terrain,"到",to_terrain)
                return NetManager:getEditAllianceTerrianPromise(to_terrain)
            end
        elseif excute_fun <= 10 then
            if me:CanEditAllianceJoinType() then
                if alliance.basicInfo.joinType == "all" then
                    print("修改联盟加入type到:audit")
                    return NetManager:getEditAllianceJoinTypePromise("audit")
                else
                    print("修改联盟加入type到:all")
                    return NetManager:getEditAllianceJoinTypePromise("all")
                end
            end
        elseif excute_fun <= 15 then
            if me:CanEditAllianceNotice() then
                return NetManager:getEditAllianceNoticePromise("机器人联盟公告")
            end
        elseif excute_fun <= 20 then
            if me:CanEditAllianceNotice() then
                return NetManager:getEditAllianceDescriptionPromise("机器人联盟描述")
            end
        elseif excute_fun <= 30 then
            return NetManager:getItemLogsPromise(alliance._id)
        end
    end
end
-- 发忠诚值给联盟成员
function AllianceApi:GiveLoyalty()
    local alliance = Alliance_Manager:GetMyAlliance()
    if not alliance:IsDefault() and alliance:GetSelf():IsArchon() and alliance.basicInfo.honour > 0 then
        local members = alliance:GetAllMembers()
        local member_index = math.random(LuaUtils:table_size(members))
        local count = 0
        local member
        alliance:IteratorAllMembers(function ( v )
            count = count + 1
            if count == member_index then
                member = v
            end
        end)
        local loyalty_value = math.random(alliance.basicInfo.honour)
        print("奖励",member.name,loyalty_value,"忠诚值")
        return NetManager:getGiveLoyaltyToAllianceMemberPromise(member:Id(),loyalty_value)
    end
end
function AllianceApi:RequestSpeedUp()
    local alliance = Alliance_Manager:GetMyAlliance()
    if not alliance:IsDefault() then
        -- 城市建筑升级
        local can_request = {}
        local buildingEvents = User.buildingEvents
        local houseEvents = User.houseEvents
        for i,event in ipairs(buildingEvents) do
            local leftTime = UtilsForEvent:GetEventInfo(event)
            if leftTime < DataUtils:getFreeSpeedUpLimitTime() then
                -- 是否已经申请过联盟加速
                local isRequested = User:IsRequestHelped(event.id)
                if not isRequested then
                    event.EventType = "buildingEvents"
                    table.insert(can_request, event)
                end
            end
        end
        for i,event in ipairs(houseEvents) do
            local leftTime = UtilsForEvent:GetEventInfo(event)
            if leftTime < DataUtils:getFreeSpeedUpLimitTime() then
                -- 是否已经申请过联盟加速
                local isRequested = User:IsRequestHelped(event.id)
                if not isRequested then
                    event.EventType = "houseEvents"
                    table.insert(can_request, event)
                end
            end
        end

        if #can_request > 0 then
            -- 随机一个申请
            local event = can_request[math.random(#can_request)]
            return NetManager:getRequestAllianceToSpeedUpPromise(event.EventType,event.id)
        end

        -- 军事科技
        local can_request = {}
        for _,event in pairs(User.militaryTechEvents) do
            if DataUtils:getFreeSpeedUpLimitTime() < event:GetTime() then
                -- 是否已经申请过联盟加速
                local isRequested = User:IsRequestHelped(event:Id())
                if not isRequested then
                    table.insert(can_request, event)
                end
            end
        end

        if #can_request > 0 then
            -- 随机一个申请
            local event = can_request[math.random(#can_request)]
            return NetManager:getRequestAllianceToSpeedUpPromise(event:GetEventType(),event:Id())
        end

        -- 士兵晋升
        local can_request = {}
        for _,event in pairs(User.soldierStarEvents) do
            if DataUtils:getFreeSpeedUpLimitTime() < event:GetTime() then
                -- 是否已经申请过联盟加速
                local isRequested = User:IsRequestHelped(event:Id())
                if not isRequested then
                    table.insert(can_request, event)
                end
            end
        end
        if #can_request > 0 then
            -- 随机一个申请
            local event = can_request[math.random(#can_request)]
            return NetManager:getRequestAllianceToSpeedUpPromise(event:GetEventType(),event:Id())
        end

        -- 生产科技
        local can_request = {}
        for _,event in ipairs(User.productionTechEvents) do
            if DataUtils:getFreeSpeedUpLimitTime() < event:GetTime() then
                -- 是否已经申请过联盟加速
                local isRequested = User:IsRequestHelped(event:Id())
                if not isRequested then
                    table.insert(can_request, event)
                end
            end
        end
        if #can_request > 0 then
            -- 随机一个申请
            local event = can_request[math.random(#can_request)]
            return NetManager:getRequestAllianceToSpeedUpPromise("productionTechEvents",event:Id())
        end
    end
end
-- 协助加速
function AllianceApi:HelpSpeedUp()
    local alliance = Alliance_Manager:GetMyAlliance()
    if not alliance:IsDefault() then
        -- 帮助全部
        local help_events = alliance:GetCouldShowHelpEvents()
        local can_help = {}
        for k,event in pairs(help_events) do
            if User:Id() ~= event.playerData.id then
                table.insert(can_help, event)
            end
        end
        if #can_help > 0 then
            local help_all = math.random(2) == 2
            if help_all then
                return NetManager:getHelpAllAllianceMemberSpeedUpPromise()
            else
                local event = can_help[math.random(#can_help)]
                return NetManager:getHelpAllianceMemberSpeedUpPromise(event.id)
            end
        end

    end
end
function AllianceApi:AllianceOtherApi()
    local alliance = Alliance_Manager:GetMyAlliance()
    if not alliance:IsDefault() then
        local member = alliance:GetSelf()
        local random = math.random(100)
        -- local random = 12
        -- 发联盟邮件
        if member:CanSendAllianceMail() and random < 5 then
            return NetManager:getSendAllianceMailPromise("机器人联盟邮件", "机器人联盟邮件")
        elseif random < 10 then
            local members = alliance:GetAllMembers()
            local member
            for k,v in pairs(members) do
                member = v
                break
            end
            return NetManager:getPlayerWallInfoPromise(member:Id())
        elseif random < 15 then
            if alliance.basicInfo.status == 'fight' or alliance.basicInfo.status == 'prepare' then
                return
            end
            if #alliance:GetMyMarchEvents() > 0 then
                return
            end
            local locationX = math.random(GameDatas.AllianceInitData.intInit.allianceRegionMapWidth.value-2)
            local locationY = math.random(GameDatas.AllianceInitData.intInit.allianceRegionMapHeight.value-2)
            local mapObjects = alliance.mapObjects
            local can_move = true
            for i,v in ipairs(mapObjects) do
                if v.location.x == locationX and v.location.y == locationY then
                    can_move = false
                    break
                end
            end
            local terrainStyle = alliance.basicInfo.terrainStyle
            local terrainStyle_map = GameDatas.AllianceMap["allianceMap_"..terrainStyle]
            local buildingName = GameDatas.AllianceMap.buildingName
            for i,v in ipairs(terrainStyle_map) do
                local sizeInfo = buildingName[v.name]
                for i=v.x,v.x - sizeInfo.width + 1,-1 do
                    for j=v.y,v.y - sizeInfo.height + 1,-1 do
                        if i==locationX and j==locationY then
                            can_move = false
                            break
                        end
                    end
                end
            end
            if #UtilsForEvent:GetAllMyMarchEvents() > 0 then
                can_move = false
            end
            if can_move then
                print("移动自己城市",locationX,locationY)
                return NetManager:getBuyAndUseItemPromise("moveTheCity",{
                    ["moveTheCity"]={
                        locationX = locationX,
                        locationY = locationY
                    }
                })
            end
        end
    end
end
-- 联盟商店进货
function AllianceApi:ShopStock()
    local alliance = Alliance_Manager:GetMyAlliance()
    if not alliance:IsDefault() then

        local shop = alliance:GetAllianceBuildingInfoByName("shop")
        local shop_config = GameDatas.AllianceBuilding.shop
        -- 所有解锁的可进货道具
        local unlock_items = {}
        for i=1,shop.level do
            local unlock = string.split(shop_config[i].itemsUnlock, ",")
            for i,v in ipairs(unlock) do
                unlock_items[v] = true
            end
        end
        local super_items = UtilsForItem:GetAdvanceItems()
        local stock_items = {}
        for i=1,#super_items do
            local super_item = super_items[i]
            if unlock_items[super_item.name] then
                table.insert(stock_items,super_item)
            end
        end
        if #stock_items < 1 then
            return
        end
        local item = stock_items[math.random(#stock_items)]
        if item.isAdvancedItem and  alliance:GetSelf():CanAddAdvancedItemsToAllianceShop() and alliance.basicInfo.honour >= item.buyPriceInAlliance then
            print("联盟商店进货：",item.name)
            return NetManager:getAddAllianceItemPromise(item.name,1)
        end
    end
end
function AllianceApi:BuyAllianceItem()
    local alliance = Alliance_Manager:GetMyAlliance()
    if not alliance:IsDefault() then

        local shop = alliance:GetAllianceBuildingInfoByName("shop")
        local shop_config = GameDatas.AllianceBuilding.shop
        -- 所有解锁的道具
        local unlock_items = {}
        for i=1,shop.level do
            local unlock = string.split(shop_config[i].itemsUnlock, ",")
            for i,v in ipairs(unlock) do
                table.insert(unlock_items, UtilsForItem:GetItemInfoByName(v))
            end
        end
        local item = unlock_items[math.random(#unlock_items)]
        if item.isAdvancedItem and not alliance:GetSelf():CanBuyAdvancedItemsFromAllianceShop() then
            return
        end
        if User:Loyalty() >= item.sellPriceInAlliance and alliance:GetItemCount(item.name) > 0 then
            print("购买联盟商店道具：",item.name)
            return NetManager:getBuyAllianceItemPromise(item.name,1)
        else
            return self:Contribute()
        end
    end
end
-- 获取其他玩家重置送的礼物
function AllianceApi:GetGift()
    local gifts = User.iapGifts
    if not LuaUtils:table_empty(gifts) then
        for k,data in pairs(gifts) do
            print("获取其他玩家重置送的礼物",data:Id())
            return NetManager:getIapGiftPromise(data:Id())
        end
    end
end
-- 获取首次加入联盟奖励
function AllianceApi:FirstJoinAllianceReward()
    local alliance = Alliance_Manager:GetMyAlliance()
    if not User.countInfo.firstJoinAllianceRewardGeted and not alliance:IsDefault() then
        return NetManager:getFirstJoinAllianceRewardPromise()
    end
end
-- 绝句或者同意加入联盟
function AllianceApi:AcceptAllianceInvite()
    local alliance = Alliance_Manager:GetMyAlliance()
    if alliance:IsDefault() and User.inviteToAllianceEvents and #User.inviteToAllianceEvents > 0 then
        local event = User.inviteToAllianceEvents[math.random(#User.inviteToAllianceEvents)]
        return NetManager:getHandleJoinAllianceInvitePromise(event.id,math.random(2) ~= 1)
    end
end
-- 迁移联盟
function AllianceApi:MoveAlliance()
    local alliance = Alliance_Manager:GetMyAlliance()
    if not alliance:IsDefault() then
        local bigMapLength = GameDatas.AllianceInitData.intInit.bigMapLength.value
        local mapIndex = math.random(0,bigMapLength * bigMapLength - 1)
        if mapIndex == alliance.mapIndex then
            return
        end
        local canMove = alliance.basicInfo.status ~= "prepare" and  alliance.basicInfo.status ~= "fight"
        if not canMove then
            return
        end
        local time = intInit.allianceMoveColdMinutes.value * 60 + alliance.basicInfo.allianceMoveTime/1000.0 - app.timer:GetServerTime()
        local canMove = alliance.basicInfo.allianceMoveTime == 0 or time <= 0
        if not canMove then
            return
        end
        local palaceLevel = alliance:GetAllianceBuildingInfoByName("palace").level
        print("DataUtils:getMapRoundByMapIndex(mapIndex)",DataUtils:getMapRoundByMapIndex(mapIndex))
        local canMove1 = palaceLevel >= moveLimit[DataUtils:getMapRoundByMapIndex(mapIndex)].needPalaceLevel
        if not canMove1 then
            return
        end
        local canMove1 = alliance:GetSelf():CanMoveAlliance()
        if not canMove1 then
            return
        end
        return NetManager:getEnterMapIndexPromise(mapIndex):done(function ( response )
            NetManager:getLeaveMapIndexPromise(mapIndex)
            local allianceData = response.msg.allianceData
            if not allianceData or allianceData == json.null then
                return NetManager:getMoveAlliancePromise(mapIndex)
            end
        end)
    end
end
local function setRun()
    app:setRun()
end
local function setRun()
    app:setRun()
end

-- 联盟方法组
local function RequestToJoinAlliance()
    local p = AllianceApi:RequestToJoinAlliance()
    if p then
        p:always(setRun)
    else
        setRun()
    end
end
local function ApproveOrRejectJoinAllianceRequest()
    local p = AllianceApi:ApproveOrRejectJoinAllianceRequest()
    if p then
        p:always(setRun)
    else
        setRun()
    end
end
local function InviteToJoinAlliance()
    local p = AllianceApi:InviteToJoinAlliance()
    if p then
        p:always(setRun)
    else
        setRun()
    end
end
local function CreateAlliance()
    local p = AllianceApi:CreateAlliance()
    if p then
        p:always(setRun)
    else
        setRun()
    end
end

local function JoinAlliance()
    if Alliance_Manager:GetMyAlliance():IsDefault() then
        -- 没有联盟前的操作
        local excute = math.random(100)
        if excute < 10 then
            local page = 0
            local joined = false
            local function join()
                if joined then
                    if Alliance_Manager:GetMyAlliance():IsDefault() then
                        CreateAlliance()
                    end
                    return
                end
                NetManager:getFetchCanDirectJoinAlliancesPromise(page):done(function(response)
                    if not response.msg or not response.msg.allianceDatas then
                        setRun()
                        return
                    end
                    if response.msg.allianceDatas then
                        if #response.msg.allianceDatas == 0 then
                            setRun()
                            return
                        end
                        for i,find_alliance in ipairs(response.msg.allianceDatas) do
                            if find_alliance.members < find_alliance.membersMax then
                                local find_id = find_alliance.id
                                local p = AllianceApi:JoinAlliance(find_id)
                                if p then
                                    p:always(setRun)
                                    joined = true
                                    return
                                end
                            end
                        end
                        page = page + 10
                        join()
                    end
                end)
            end
            join()
        elseif excute < 98 then
            RequestToJoinAlliance()
        else
            CreateAlliance()
        end
    else
        setRun()
    end
end
local function RequestSpeedUp()
    local p = AllianceApi:RequestSpeedUp()
    if p then
        p:always(setRun)
    else
        setRun()
    end
end
local function HelpSpeedUp()
    local p = AllianceApi:HelpSpeedUp()
    if p then
        p:always(setRun)
    else
        setRun()
    end
end
local function getQuitAlliancePromise()
    local p = AllianceApi:getQuitAlliancePromise()
    if p then
        p:always(setRun)
    else
        setRun()
    end
end
local function Contribute()
    local p = AllianceApi:Contribute()
    if p then
        p:always(setRun)
    else
        setRun()
    end
end
local function UpgradeAllianceBuilding()
    local p = AllianceApi:UpgradeAllianceBuilding()
    if p then
        p:always(setRun)
    else
        setRun()
    end
end
local function UpgradeAllianceVillage()
    local p = AllianceApi:UpgradeAllianceVillage()
    if p then
        p:always(setRun)
    else
        setRun()
    end
end
local function EditAllianceInfo()
    local p = AllianceApi:EditAllianceInfo()
    if p then
        p:always(setRun)
    else
        setRun()
    end
end
local function GiveLoyalty()
    local p = AllianceApi:GiveLoyalty()
    if p then
        p:always(setRun)
    else
        setRun()
    end
end
local function AllianceMemberApi()
    local p = AllianceApi:AllianceMemberApi()
    if p then
        p:always(setRun)
    else
        setRun()
    end
end
local function AllianceOtherApi()
    local p = AllianceApi:AllianceOtherApi()
    if p then
        p:always(setRun)
    else
        setRun()
    end
end
local function ShopStock()
    local p = AllianceApi:ShopStock()
    if p then
        p:always(setRun)
    else
        setRun()
    end
end
local function BuyAllianceItem()
    local p = AllianceApi:BuyAllianceItem()
    if p then
        p:always(setRun)
    else
        setRun()
    end
end
local function GetGift()
    local p = AllianceApi:GetGift()
    if p then
        p:always(setRun)
    else
        setRun()
    end
end
local function FirstJoinAllianceReward()
    local p = AllianceApi:FirstJoinAllianceReward()
    if p then
        p:always(setRun)
    else
        setRun()
    end
end
local function CancelJoinAlliance()
    local p = AllianceApi:CancelJoinAlliance()
    if p then
        p:always(setRun)
    else
        setRun()
    end
end
local function MoveAlliance()
    local p = AllianceApi:MoveAlliance()
    if p then
        p:always(setRun)
    else
        setRun()
    end
end
local function AcceptAllianceInvite()
    local p = AllianceApi:AcceptAllianceInvite()
    if p then
        p:always(setRun)
    else
        setRun()
    end
end

return {
    setRun,
    JoinAlliance,
    ApproveOrRejectJoinAllianceRequest,
    InviteToJoinAlliance,
    AcceptAllianceInvite,
    CancelJoinAlliance,
    RequestSpeedUp,
    HelpSpeedUp,
    Contribute,
    UpgradeAllianceBuilding,
    UpgradeAllianceVillage,
    EditAllianceInfo,
    GiveLoyalty,
    AllianceMemberApi,
    getQuitAlliancePromise,
    AllianceOtherApi,
    ShopStock,
    BuyAllianceItem,
    GetGift,
    FirstJoinAllianceReward,
    MoveAlliance,
}







































































