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
-- function AllianceApi:RequestSpeedUp()
--     if not Alliance_Manager:GetMyAlliance():IsDefault() and
--         -- 城市建筑升级

--      local eventType = building:EventType()
--     if self:IsAbleToFreeSpeedup(building) then
--         NetManager:getFreeSpeedUpPromise(eventType,building:UniqueUpgradingKey())
--     else
--         if not Alliance_Manager:GetMyAlliance():IsDefault() then
--             -- 是否已经申请过联盟加速
--             local isRequested = Alliance_Manager:GetMyAlliance()
--                 :HasBeenRequestedToHelpSpeedup(building:UniqueUpgradingKey())
--             if not isRequested then
--                 NetManager:getRequestAllianceToSpeedUpPromise(eventType,building:UniqueUpgradingKey())
--                 return
--             end
--         end
--         -- 没加入联盟或者已加入联盟并且申请过帮助时执行使用道具加速
--         UIKit:newGameUI("GameUIBuildingSpeedUp", building):AddToCurrentScene(true)
--     end

--     end
-- endp

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
-- getQuitAlliancePromise,
}



