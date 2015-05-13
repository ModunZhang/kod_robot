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

return {
    setRun,
    JoinAlliance,
    CreateAlliance,
    RequestSpeedUp,
    HelpSpeedUp,
-- getQuitAlliancePromise,
}








