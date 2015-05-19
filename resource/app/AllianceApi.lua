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
        return NetManager:getQuitAlliancePromise()
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
-- 修改联盟地形
function AllianceApi:EditTerrain()
    local alliance = Alliance_Manager:GetMyAlliance()
    if not alliance:IsDefault() and alliance:GetSelf():CanEditAlliance() and alliance:Status() ~= "fight" then
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
                local event = can_help[#math.random(#can_help)]
                return NetManager:getHelpAllianceMemberSpeedUpPromise(event:Id())
            end
        end

    end
end

local function setRun()
    app:setRun()
end

-- 联盟方法组
local function JoinAlliance()
    if Alliance_Manager:GetMyAlliance():IsDefault() then
        NetManager:getFetchCanDirectJoinAlliancesPromise():done(function(response)
            if not response.msg or not response.msg.allianceDatas then setRun() return end
            if response.msg.allianceDatas then
                local find_alliance = response.msg.allianceDatas[math.random(#response.msg.allianceDatas)]
                if find_alliance.members == find_alliance.membersMax then
                    setRun()
                    return
                end
                local find_id = find_alliance.id
                local p = AllianceApi:JoinAlliance(find_id)
                if p then
                    p:always(setRun)
                else
                    setRun()
                end
            end
        end)
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
function Contribute()
    local p = AllianceApi:Contribute()
    if p then
        p:always(setRun)
    else
        setRun()
    end
end
function UpgradeAllianceBuilding()
    local p = AllianceApi:UpgradeAllianceBuilding()
    if p then
        p:always(setRun)
    else
        setRun()
    end
end
function UpgradeAllianceVillage()
    local p = AllianceApi:UpgradeAllianceVillage()
    if p then
        p:always(setRun)
    else
        setRun()
    end
end
function EditTerrain()
    local p = AllianceApi:EditTerrain()
    if p then
        p:always(setRun)
    else
        setRun()
    end
end
function GiveLoyalty()
    local p = AllianceApi:GiveLoyalty()
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
    EditTerrain,
    GiveLoyalty,
-- getQuitAlliancePromise,
}

















