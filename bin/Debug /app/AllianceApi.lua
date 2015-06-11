--
-- Author: Kenny Dai
-- Date: 2015-05-07 21:20:11
--
local AllianceApi = {}
local Flag = import("app.entity.Flag")

function AllianceApi:CreateAlliance()
    if Alliance_Manager:GetMyAlliance():IsDefault() then
        local name , tag = DataUtils:randomAllianceNameTag()
        local random = math.random(3)
        local tmp = {"desert","iceField","grassLand"}
        local terrian = tmp[random]
        print("创建联盟")
        return NetManager:getCreateAlliancePromise(name,tag,"all",terrian,Flag:RandomFlag():EncodeToJson())
    end
end
function AllianceApi:JoinAlliance(id)
    if id then
        print("加入联盟：",id)
        return NetManager:getJoinAllianceDirectlyPromise(id)
    end
end
function AllianceApi:getQuitAlliancePromise()
    if not Alliance_Manager:GetMyAlliance():IsDefault() and
        Alliance_Manager:GetMyAlliance():Status() ~= "prepare" and
        Alliance_Manager:GetMyAlliance():Status() ~= "fight" then
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
    if not alliance:IsDefault() then
        local members = alliance:GetAllMembers()
        local member_index = math.random(LuaUtils:table_size(members))
        local count = 0
        local member
        local me = alliance:GetSelf()
        while not member do
            alliance:IteratorAllMembers(function ( id,v )
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
        local excute_fun = math.random(10)
        if excute_fun ~= 1 then
            -- 职位改变
            local up_or_down = math.random(2)
            if up_or_down == 1 then
                -- 降级
                local auth,title_can = me:CanDemotionMemberLevel(member:Title())
                local isLow = member:IsTitleLowest()
                if auth and title_can and not isLow then
                    print("职位降级",member:Name(),member:TitleDegrade())
                    return NetManager:getEditAllianceMemberTitlePromise(member:Id(), member:TitleDegrade())
                end
            else
                -- 晋级
                local auth,title_can = me:CanUpgradeMemberLevel(member:TitleUpgrade())
                local isHighest = member:IsTitleHighest()
                if auth and title_can and not isHighest then
                    print("职位晋级",member:Name(),member:TitleUpgrade())
                    return NetManager:getEditAllianceMemberTitlePromise(member:Id(), member:TitleUpgrade())
                end

            end
        else
            -- 踢出
            local auth,title_can = me:CanKickOutMember(member:Title())
            if not title_can or not auth then
                return
            end
            return NetManager:getAllianceMemberApiPromise(member:Id())
        end
    end
end
-- 联盟捐赠
function AllianceApi:Contribute()
    if not Alliance_Manager:GetMyAlliance():IsDefault() then
        local donate_types = {
            "wood",
            "stone",
            "food",
            "iron",
            "coin",
            "gem",
        }
        local ResourceManager = City:GetResourceManager()
        local CON_TYPE = {
            wood = ResourceManager.RESOURCE_TYPE.WOOD,
            food = ResourceManager.RESOURCE_TYPE.FOOD,
            iron = ResourceManager.RESOURCE_TYPE.IRON,
            stone = ResourceManager.RESOURCE_TYPE.STONE,
            coin = ResourceManager.RESOURCE_TYPE.COIN,
            gem = ResourceManager.RESOURCE_TYPE.GEM,
        }
        local r_type = donate_types[math.random(#donate_types)]

        local donate_status = User:AllianceDonate()
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
            r_count = User:GetGemResource():GetValue()
        else
            r_count = City.resource_manager:GetResourceByType(CON_TYPE[r_type]):GetResourceValueByCurrentTime(app.timer:GetServerTime())
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
        local alliance_map = alliance:GetAllianceMap()
        local building_names = {
            "orderHall",
            "palace",
            "shop",
            "shrine",
        }
        local building_name = building_names[math.random(#building_names)]
        local building = alliance_map:FindAllianceBuildingInfoByName(building_name)
        local building_config = GameDatas.AllianceBuilding[building.name]
        local now_c = building_config[building.level+1]
        if not alliance:GetSelf():CanUpgradeAllianceBuilding() then
            return
        elseif alliance:Honour() < now_c.needHonour then
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
        if alliance:Honour () >= level_config.needHonour then
            print("升级联盟村落:",village_type,to_level)
            return NetManager:getUpgradeAllianceVillagePromise(village_type)
        end
    end
end
-- 修改联盟设置
function AllianceApi:EditAllianceInfo()
    local alliance = Alliance_Manager:GetMyAlliance()
    local me = alliance:GetSelf()
    if not alliance:IsDefault()  and alliance:Status() ~= "fight" and alliance:Status() ~= "prepare" then
        local excute_fun = math.random(100)
        if excute_fun <= 5 then
            local need_honour =GameDatas.AllianceInitData.intInit.editAllianceTerrianHonour.value
            if me:CanEditAlliance() and need_honour <= alliance:Honour() then
                local terrains = {
                    "grassLand",
                    "desert",
                    "iceField",
                }
                local current_terrain = alliance:Terrain()
                local to_terrain = clone(current_terrain)
                while to_terrain == current_terrain do
                    to_terrain = terrains[math.random(#terrains)]
                end
                print("修改联盟地形:",current_terrain,"到",to_terrain)
                return NetManager:getEditAllianceTerrianPromise(to_terrain)
            end
        elseif excute_fun <= 10 then
            if me:CanEditAllianceJoinType() then
                if alliance:JoinType() == "all" then
                -- print("修改联盟加入type到:audit")
                -- return NetManager:getEditAllianceJoinTypePromise("audit")
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
        elseif excute_fun <= 25 and me:CanEditAllianceMemeberTitle() then
            local titles = alliance:Titles()
            local title_keys = {
                "supervisor",
                "quartermaster",
                "elite",
                "member",
                "archon",
                "general",
            }
            local change_title = title_keys[math.random(#title_keys)]
            print("修改联盟职位名称",change_title)
            return NetManager:getEditAllianceTitleNamePromise(change_title,"机器人"..change_title)
        elseif excute_fun <= 30 then
            return NetManager:getItemLogsPromise(alliance:Id())
        elseif excute_fun <= 35 then
            return NetManager:getNearedAllianceInfosPromise()
        end
    end
end
-- 发忠诚值给联盟成员
function AllianceApi:GiveLoyalty()
    local alliance = Alliance_Manager:GetMyAlliance()
    if not alliance:IsDefault() and alliance:GetSelf():IsArchon() and alliance:Honour() > 0 then
        local members = alliance:GetAllMembers()
        local member_index = math.random(LuaUtils:table_size(members))
        local count = 0
        local member
        alliance:IteratorAllMembers(function ( id,v )
            count = count + 1
            if count == member_index then
                member = v
            end
        end)
        local loyalty_value = math.random(alliance:Honour())
        print("奖励",member:Name(),loyalty_value,"忠诚值")
        return NetManager:getGiveLoyaltyToAllianceMemberPromise(member:Id(),loyalty_value)
    end
end
function AllianceApi:RequestSpeedUp()
    local alliance = Alliance_Manager:GetMyAlliance()
    if not alliance:IsDefault() then
        -- 城市建筑升级
        local can_request = {}
        City:IteratorCanUpgradeBuildings(function ( building )
            -- 正在升级
            if building:IsUpgrading() then
                local eventType = building:EventType()
                -- 可以免费加速则不申请联盟协助加速
                if not building:IsAbleToFreeSpeedUpByTime(app.timer:GetServerTime()) then
                    -- 是否已经申请过联盟加速
                    local isRequested = alliance:HasBeenRequestedToHelpSpeedup(building:UniqueUpgradingKey())
                    if not isRequested then
                        table.insert(can_request, building)
                    end
                end
            end
        end)
        if #can_request > 0 then
            -- 随机一个申请
            local building = can_request[math.random(#can_request)]
            return NetManager:getRequestAllianceToSpeedUpPromise(building:EventType(),building:UniqueUpgradingKey())
        end

        -- 军事科技
        local soldier_manager = City:GetSoldierManager()
        local can_request = {}
        soldier_manager:IteratorMilitaryTechEvents(function ( event )
            if DataUtils:getFreeSpeedUpLimitTime() < event:GetTime() then
                -- 是否已经申请过联盟加速
                local isRequested = alliance
                    :HasBeenRequestedToHelpSpeedup(event:Id())
                if not isRequested then
                    table.insert(can_request, event)
                end
            end
        end)
        if #can_request > 0 then
            -- 随机一个申请
            local event = can_request[math.random(#can_request)]
            return NetManager:getRequestAllianceToSpeedUpPromise(event:GetEventType(),event:Id())
        end

        -- 士兵晋升
        local can_request = {}
        soldier_manager:IteratorSoldierStarEvents(function ( event )
            if DataUtils:getFreeSpeedUpLimitTime() < event:GetTime() then
                -- 是否已经申请过联盟加速
                local isRequested = alliance
                    :HasBeenRequestedToHelpSpeedup(event:Id())
                if not isRequested then
                    table.insert(can_request, event)
                end
            end
        end)
        if #can_request > 0 then
            -- 随机一个申请
            local event = can_request[math.random(#can_request)]
            return NetManager:getRequestAllianceToSpeedUpPromise(event:GetEventType(),event:Id())
        end

        -- 生产科技
        local can_request = {}
        City:IteratorProductionTechEvents(function ( event )
            if DataUtils:getFreeSpeedUpLimitTime() < event:GetTime() then
                -- 是否已经申请过联盟加速
                local isRequested = alliance
                    :HasBeenRequestedToHelpSpeedup(event:Id())
                if not isRequested then
                    table.insert(can_request, event)
                end
            end
        end)
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
            if User:Id() ~= event:GetPlayerData():Id() then
                table.insert(can_help, event)
            end
        end
        if #can_help > 0 then
            local help_all = math.random(2) == 2
            if help_all then
                return NetManager:getHelpAllAllianceMemberSpeedUpPromise()
            else
                local event = can_help[math.random(#can_help)]
                return NetManager:getHelpAllianceMemberSpeedUpPromise(event:Id())
            end
        end

    end
end
function AllianceApi:AllianceOtherApi()
    local alliance = Alliance_Manager:GetMyAlliance()
    if not alliance:IsDefault() then
        local member = alliance:GetSelf()
        local random = math.random(100)
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
            if alliance:Status() == 'fight' then
                return
            end
            local locationX = math.random(24)
            local locationY = math.random(24)
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
-- 联盟商店进货
function AllianceApi:ShopStock()
    local alliance = Alliance_Manager:GetMyAlliance()
    if not alliance:IsDefault() then

        local shop = alliance:GetAllianceMap():FindAllianceBuildingInfoByName("shop")
        local shop_config = GameDatas.AllianceBuilding.shop
        -- 所有解锁的可进货道具
        local unlock_items = {}
        for i=1,shop.level do
            local unlock = string.split(shop_config[i].itemsUnlock, ",")
            for i,v in ipairs(unlock) do
                unlock_items[v] = true
            end
        end
        local super_items = alliance:GetItemsManager():GetAllSuperItems()
        local stock_items = {}
        for i=1,#super_items do
            local super_item = super_items[i]
            if unlock_items[super_item:Name()] then
                table.insert(stock_items,super_item)
            end
        end

        local item = stock_items[math.random(#stock_items)]
        if item:IsAdvancedItem() and  alliance:GetSelf():CanAddAdvancedItemsToAllianceShop() and alliance:Honour() >= item:BuyPriceInAlliance() then
            print("联盟商店进货：",item:Name())
            return NetManager:getAddAllianceItemPromise(item:Name(),1)
        end
    end
end
function AllianceApi:BuyAllianceItem()
    local alliance = Alliance_Manager:GetMyAlliance()
    if not alliance:IsDefault() then

        local shop = alliance:GetAllianceMap():FindAllianceBuildingInfoByName("shop")
        local shop_config = GameDatas.AllianceBuilding.shop
        -- 所有解锁的道具
        local unlock_items = {}
        for i=1,shop.level do
            local unlock = string.split(shop_config[i].itemsUnlock, ",")
            for i,v in ipairs(unlock) do
                table.insert(unlock_items, alliance:GetItemsManager():GetItemByName(v))
            end
        end
        local item = unlock_items[math.random(#unlock_items)]
        if item:IsAdvancedItem() and not alliance:GetSelf():CanBuyAdvancedItemsFromAllianceShop() then
            return
        end
        if User:Loyalty() >= item:SellPriceInAlliance() then
            print("购买联盟商店道具：",item:Name())
            return NetManager:getBuyAllianceItemPromise(item:Name(),1)
        else
            return self:Contribute()
        end
    end
end
-- 获取其他玩家重置送的礼物
function AllianceApi:GetGift()
    local gifts = User:GetIapGifts()
    if not LuaUtils:table_empty(gifts) then
        for k,data in pairs(gifts) do
            print("获取其他玩家重置送的礼物",data:Id())
            return NetManager:getIapGiftPromise(data:Id())
        end
    end
end
-- 获取首次加入联盟奖励
function AllianceApi:FirstJoinAllianceReward()
    if not User:GetCountInfo().firstJoinAllianceRewardGeted then
        return NetManager:getFirstJoinAllianceRewardPromise()
    end
end
local function setRun()
    app:setRun()
end

-- 联盟方法组
local function JoinAlliance()
    if Alliance_Manager:GetMyAlliance():IsDefault() then
        local page = 0
        local joined = false
        local function join()
            if joined then
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



return {
    setRun,
    JoinAlliance,
    CreateAlliance,
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
}

















































