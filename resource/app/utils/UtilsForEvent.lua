UtilsForEvent = {}
local Localize = import(".Localize")

function UtilsForEvent:IsHouseEvent(event)
    return event.buildingLocation
end
function UtilsForEvent:IsBuildingEvent(event)
    return event.location
end

function UtilsForEvent:GetEventInfo(event)
    local start = event.startTime/1000
    local finish = (event.finishTime or event.arriveTime) / 1000
    local time = app.timer:GetServerTime()
    local left = finish - time
    if left < 0 then
        left = 0
    end
    return math.ceil(left), (time - start) * 100.0 / (finish - start)
end
function UtilsForEvent:GetMilitaryTechEventLocalize(tech_name, level)
    local category, tech_type = unpack(string.split(tech_name, "_"))
    if tonumber(tech_type) then
        return string.format(_("晋升%s的星级 star %d"),
            Localize.soldier_name[tech_name], level + 1)
    end
    if tech_type == "hpAdd" then
        return string.format(
            _("研发科技-%s血量增加到 Lv %d"),
            Localize.soldier_category[category],
            level + 1)
    end
    return string.format(
        _("研发科技-%s对%s的攻击到 Lv %d"),
        Localize.soldier_category[category],
        Localize.soldier_category[tech_type],
        level + 1)
end

local monsters = GameDatas.AllianceInitData.monsters
function UtilsForEvent:GetMarchEventPrefix(event, eventType)
    if eventType == "shrineEvents" then
        local location = event.playerTroops[1].location
        local x,y = DataUtils:GetAbsolutePosition(
            Alliance_Manager:GetMyAlliance().mapIndex,
            location.x,
            location.y
        )
        local target_pos = string.format("%s,%s", x,y)
        local target_str = Localize.shrine_desc[event.stageName][1]
        return string.format(_("正在参加圣地战 %s(%s)"), target_str, target_pos)
    end
    if eventType == "villageEvents" then
        return _("正在进行村落采集")
    end
    if eventType == "helpToTroops" then
        return  string.format(_("正在协防玩家%s"),event.beHelpedPlayerData.name)
    end
    if eventType == "strikeMarchReturnEvents" or eventType == "attackMarchReturnEvents" then
        local march_type = event.marchType
        if march_type == 'city' then
            return _("进攻玩家城市(返回中)")
        elseif march_type == 'helpDefence' then
            return _("协防玩家城市(返回中)")
        elseif march_type == 'village' then
            return _("占领村落(返回中)")
        elseif march_type == 'shrine' then
            return _("攻打联盟圣地(返回中)")
        elseif march_type == 'monster' then
            return _("攻打黑龙军团(返回中)")
        end
    end
    local x,y = DataUtils:GetAbsolutePosition(event.toAlliance.mapIndex,
        event.toAlliance.location.x,
        event.toAlliance.location.y)
    local target_pos = string.format("%s,%s", x, y)
    if event.marchType == "village" then
        local target_str = string.format("%sLv%s",
            Localize.village_name[event.defenceVillageData.name],
            event.defenceVillageData.level)
        if eventType == "strikeMarchEvents" then
            return string.format(_("正在突袭 %s(%s)"), target_str, target_pos)
        end
        return string.format(_("正在进攻 %s(%s)"), target_str, target_pos)
    elseif event.marchType == "monster" then
        local corps = string.split(monsters[event.defenceMonsterData.level].soldiers, ";")
        local soldiers = string.split(corps[event.defenceMonsterData.index + 1], ",")
        local soldierName = string.split(soldiers[1],":")[1]
        local target_str = string.format("%sLv%s",
            Localize.soldier_name[soldierName],
            event.defenceMonsterData.level)
        return string.format(_("正在进攻 %s(%s)"), target_str, target_pos)
    elseif event.marchType == "helpDefence" then
        return string.format(_("前往协防 %s (%s)"),
            event.defencePlayerData.name, target_pos)
    elseif event.marchType == "city" then
        local target_str = event.defencePlayerData.name
        if eventType == "strikeMarchEvents" then
            return string.format(_("正在突袭 %s(%s)"), target_str, target_pos)
        end
        return string.format(_("正在进攻 %s(%s)"), target_str, target_pos)
    elseif event.marchType == "shrine" then
        return string.format(_("进军圣地 (%s)"), target_pos)
    end
end
function UtilsForEvent:GetMarchReturnEventPrefix(event)
    local x,y = DataUtils:GetAbsolutePosition(event.toAlliance.mapIndex,
        event.toAlliance.location.x,
        event.toAlliance.location.y)
    local target_pos = string.format("%s,%s", x, y)
    return string.format(_("返回中 (%s)"), target_pos)
end

function UtilsForEvent:GetCollectPercent(event)
    local collectTime = app.timer:GetServerTime() - event.startTime / 1000
    local time = (event.finishTime - event.startTime) / 1000
    local speed = event.villageData.collectTotal / time
    local collectCount = math.floor(speed * collectTime)
    local collectPercent = math.floor(collectCount / event.villageData.collectTotal * 100)
    return collectCount, collectPercent
end
function UtilsForEvent:GetVillageEventPrefix(event)
    local x,y = DataUtils:GetAbsolutePosition(event.toAlliance.mapIndex,
        event.toAlliance.location.x,
        event.toAlliance.location.y)
    local target_pos = string.format("%s,%s", x, y)
    return string.format(_("正在采集%sLv%s (%s)"),
        Localize.village_name[event.villageData.name],
        event.villageData.level,target_pos)
end
function UtilsForEvent:GetEventTime(event)
    if event.eventType == "shrineEvents" then
        return GameUtils:formatTimeStyle1(math.ceil(event.startTime / 1000.0 - app.timer:GetServerTime()))
    else
        LuaUtils:outputTable("GetEventTime", event)
        return GameUtils:formatTimeStyle1(math.ceil((event.finishTime or event.arriveTime)/ 1000.0 - app.timer:GetServerTime()))
    end
end
function UtilsForEvent:IsFriendEvent(event)
    return event.fromAlliance.id == Alliance_Manager:GetMyAlliance()._id
end
function UtilsForEvent:IsMyVillageEvent(event)
    return event.playerData.id == User._id
end
function UtilsForEvent:IsMyMarchEvent(event)
    return event.attackPlayerData.id == User._id
end
function UtilsForEvent:GetDestination(event)
    local eventType = event.eventType
    if eventType == "helpToTroops" then
        return event.beHelpedPlayerData.name
    elseif eventType == "villageEvents" then
        return Localize.village_name[event.villageData.name] .. "Lv" .. event.villageData.level
    elseif eventType == "strikeMarchEvents" or eventType == "attackMarchEvents" then
        if event.marchType == 'city' or event.marchType == 'helpDefence' then
            return event.defencePlayerData.name
        elseif event.marchType == 'village' then
            local village_data = event.defenceVillageData
            return Localize.village_name[village_data.name] .. "Lv" .. village_data.level
        elseif event.marchType == 'shrine' then
            return _("圣地")
        elseif event.marchType == 'monster' then
            local corps = string.split(monsters[event.defenceMonsterData.level].soldiers, ";")
            local soldiers = string.split(corps[event.defenceMonsterData.index + 1], ",")
            local infos = string.split(soldiers[1],":")
            return string.format("%s Lv%s",Localize.soldier_name[infos[1]], event.defenceMonsterData.level)
        end
    elseif eventType == "strikeMarchReturnEvents" or eventType == "attackMarchReturnEvents" then
        return event.attackPlayerData.name
    elseif eventType == "shrineEvents" then
        return _("圣地")
    end
end

function UtilsForEvent:GetDestinationLocation(event)
    local eventType = event.eventType
    if eventType == "villageEvents" then
        local mapIndex = event.toAlliance.mapIndex
        local location = event.toAlliance.location
        local x , y = DataUtils:GetAbsolutePosition(mapIndex, location.x, location.y)
        return x .. "," .. y
    elseif eventType == "strikeMarchEvents" or eventType == "attackMarchEvents" then
        local mapIndex = event.toAlliance.mapIndex
        local location = event.toAlliance.location
        local x , y = DataUtils:GetAbsolutePosition(mapIndex, location.x, location.y)
        return x .. "," .. y
    elseif eventType == "strikeMarchReturnEvents" or eventType == "attackMarchReturnEvents" then
        local mapIndex = event.fromAlliance.mapIndex
        local location = event.fromAlliance.location
        local x , y = DataUtils:GetAbsolutePosition(mapIndex, location.x, location.y)
        return x .. "," .. y
    elseif eventType == "helpToTroops" then
        local location = event.beHelpedPlayerData.location
        local mapIndex = Alliance_Manager:GetMyAlliance().mapIndex
        local x , y = DataUtils:GetAbsolutePosition(mapIndex, location.x, location.y)
        return x .. "," .. y
    elseif eventType == "shrineEvents" then
        local mapIndex = Alliance_Manager:GetMyAlliance().mapIndex
        local x , y = DataUtils:GetAbsolutePosition(mapIndex, 13,17)
        return string.format("%d,%d",x,y)
    end
end
function UtilsForEvent:GetDragonType(event)
    local eventType = event.eventType
    if eventType == "villageEvents" then
        return event.playerData.dragon.type
    elseif eventType == "strikeMarchEvents" or eventType == "attackMarchEvents" or eventType == "strikeMarchReturnEvents" or eventType == "attackMarchReturnEvents" then
        return event.attackPlayerData.dragon.type
    elseif eventType == "helpToTroops" then
        return event.playerDragon
    elseif eventType == "shrineEvents" then
        for i,troop in ipairs(event.playerTroops) do
            if troop.id == User:Id() then
                return troop.dragon.type
            end
        end
    end
end
function UtilsForEvent:GetAllMyMarchEvents()
    local marchEvents = Alliance_Manager:GetMyAlliance().marchEvents
    local shrineEvents = Alliance_Manager:GetMyAlliance().shrineEvents
    local villageEvents = Alliance_Manager:GetMyAlliance().villageEvents
    local helpToTroops = User.helpToTroops
    local events = {}
    if marchEvents then
        for eventType,bigTypeEvent in pairs(marchEvents) do
            for i,event in ipairs(bigTypeEvent) do
                if self:IsMyMarchEvent(event) then
                    event.eventType = eventType
                    table.insert(events, event)
                end
            end
        end
    end
    if shrineEvents then
        for __,event in pairs(shrineEvents) do
            for i,troop in ipairs(event.playerTroops) do
                if troop.id == User:Id() then
                    event.eventType = "shrineEvents"
                    table.insert(events, event)
                end
            end
        end
    end
    if villageEvents then
        for __,event in pairs(villageEvents) do
            if self:IsMyVillageEvent(event) then
                event.eventType = "villageEvents"
                table.insert(events, event)
            end
        end
    end
    if helpToTroops then
        for __,event in pairs(helpToTroops) do
            event.eventType = "helpToTroops"
            table.insert(events, event)
        end
    end
    return events
end








