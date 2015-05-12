local NORMAL = GameDatas.Soldiers.normal
local SPECIAL = GameDatas.Soldiers.special
local Enum = import("..utils.Enum")
local Localize = import("..utils.Localize")
local MultiObserver = import(".MultiObserver")
local MilitaryTechnology = import(".MilitaryTechnology")
local MilitaryTechEvents = import(".MilitaryTechEvents")
local SoldierStarEvents = import(".SoldierStarEvents")

local SoldierManager = class("SoldierManager", MultiObserver)

SoldierManager.LISTEN_TYPE = Enum("SOLDIER_CHANGED",
    "TREAT_SOLDIER_CHANGED",
    "SOLDIER_STAR_CHANGED",
    "MILITARY_TECHS_EVENTS_CHANGED",
    "MILITARY_TECHS_EVENTS_ALL_CHANGED",
    "MILITARY_TECHS_DATA_CHANGED",
    "SOLDIER_STAR_EVENTS_CHANGED",
    "OnSoldierStarEventsTimer",
    "OnMilitaryTechEventsTimer",
    "ALL_SOLDIER_STAR_EVENTS_CHANGED")

function SoldierManager:ctor()
    SoldierManager.super.ctor(self)
    self.soldier_map = {
        ["sentinel"] = 0,
        ["deathKnight"] = 0,
        ["lancer"] = 0,
        ["crossbowman"] = 0,
        ["horseArcher"] = 0,
        ["steamTank"] = 0,
        ["meatWagon"] = 0,
        ["catapult"] = 0,
        ["ballista"] = 0,
        ["ranger"] = 0,
        ["swordsman"] = 0,
        ["skeletonArcher"] = 0,
        ["demonHunter"] = 0,
        ["paladin"] = 0,
        ["priest"] = 0,
        ["skeletonWarrior"] = 0,
    }
    self.treatSoldiers_map = {
        ["ballista"] = 0,
        ["ranger"] = 0,
        ["catapult"] = 0,
        ["crossbowman"] = 0,
        ["horseArcher"] = 0,
        ["swordsman"] = 0,
        ["sentinel"] = 0,
        ["lancer"] = 0,
        ["skeletonWarrior"] = 0,
        ["skeletonArcher"] = 0,
        ["deathKnight"] = 0,
        ["meatWagon"] = 0,
    }
    self.soldierStars = {
        ["ballista"]    = 1,
        ["catapult"]    = 1,
        ["crossbowman"] = 1,
        ["horseArcher"] = 1,
        ["lancer"]     = 1,
        ["ranger"]     = 1,
        ["sentinel"]    = 1,
        ["swordsman"]   = 1,
    }
    self.soldierStarEvents = {}
    self.militaryTechEvents = {}
    self.militaryTechs = {}

    if app then
        app.timer:AddListener(self)
    end
end
function SoldierManager:IteratorSoldiers(func)
    for k, v in pairs(self:GetSoldierMap()) do
        if func(k, v) then
            return
        end
    end
end
function SoldierManager:GetSoldierMap()
    return self.soldier_map
end
function SoldierManager:GetTreatSoldierMap()
    return self.treatSoldiers_map
end
function SoldierManager:GetCountBySoldierType(soldier_type)
    return self.soldier_map[soldier_type]
end
function SoldierManager:GetTreatCountBySoldierType(soldier_type)
    return self.treatSoldiers_map[soldier_type]
end
function SoldierManager:GetMarchSoldierCount()
    return 0
end
function SoldierManager:GetSoldierConfig(soldier_type)
    local star = self:GetStarBySoldierType(soldier_type)
    local config_name = soldier_type.."_"..star
    local config = NORMAL[config_name] or SPECIAL[soldier_type]
    return config
end
function SoldierManager:GetStarBySoldierType(soldier_type)
    return SPECIAL[soldier_type] and SPECIAL[soldier_type].star or self.soldierStars[soldier_type]
end
function SoldierManager:GetGarrisonSoldierCount()
    return self:GetTotalSoldierCount()
end
-- 获取派兵上限
function SoldierManager:GetTroopPopulation()
    local armyCamps = City:GetBuildingByType("armyCamp")
    local troopPopulation = 0
    for k,v in pairs(armyCamps) do
        troopPopulation = troopPopulation + v:GetTroopPopulation()
    end
    return troopPopulation
end
function SoldierManager:GetTotalUpkeep()
    local total = 0
    for k, v in pairs(self.soldier_map) do
        local config = self:GetSoldierConfig(k)
        total = total + config.consumeFoodPerHour * v
    end
    if ItemManager:IsBuffActived("quarterMaster") then
        total = math.ceil(total * (1 - ItemManager:GetBuffEffect("quarterMaster")))
    end
    -- vip效果
    if User:IsVIPActived() then
        total = total * (1-User:GetVIPSoldierConsumeSub())
    end
    return total
end
function SoldierManager:GetTreatResource(soldiers)
    local treatCoin = 0
    dump(soldiers)
    for k, v in pairs(soldiers) do
        local config = self:GetSoldierConfig(v.name)
        if config then
            treatCoin = treatCoin + config.treatCoin*v.count
        end
    end
    return treatCoin
end
function SoldierManager:GetTreatTime(soldiers)
    local treat_time = 0
    for k, v in pairs(soldiers) do
        local config = self:GetSoldierConfig(v.name)
        total_iron = total_iron + config.treatTime*v.count
    end
    return treat_time
end
function SoldierManager:GetTreatAllTime()
    local total_time= 0
    for k, v in pairs(self.treatSoldiers_map) do
        local config = self:GetSoldierConfig(k)
        total_time = total_time + config.treatTime*v
    end
    return total_time
end
function SoldierManager:GetTotalSoldierCount()
    local total_count = 0
    for k, v in pairs(self.soldier_map) do
        total_count = total_count + v
    end
    return total_count
end
function SoldierManager:GetTotalTreatSoldierCount()
    local total_count = 0
    for k, v in pairs(self.treatSoldiers_map) do
        total_count = total_count + v
    end
    return total_count
end
function SoldierManager:GeneralMilitaryTechLocalPush(event)
    if ext and ext.localpush then
        local pushIdentity = event:Id()..event:Name()
        local title = string.format(_("%s完成"), event:GetLocalizeDesc())
        app:GetPushManager():UpdateTechnologyPush(event:FinishTime(),title,pushIdentity)
    end
end
function SoldierManager:CancelMilitaryTechLocalPush(event)
    if ext and ext.localpush then
        local pushIdentity = event:Id()..event:Name()
        app:GetPushManager():CancelTechnologyPush(pushIdentity)
    end
end
function SoldierManager:GeneralSoldierLocalPush(event)
    if ext and ext.localpush then
        local pushIdentity = event:Id()..event:Name()
        local title = string.format(_("%s完成"), event:GetLocalizeDesc())
        app:GetPushManager():UpdateSoldierPush(event:FinishTime(),title,pushIdentity)
    end
end
function SoldierManager:CancelSoldierLocalPush(event)
    if ext and ext.localpush then
        local pushIdentity = event:Id()..event:Name()
        app:GetPushManager():CancelSoldierPush(pushIdentity)
    end
end
function SoldierManager:OnUserDataChanged(user_data,current_time, deltaData)
    local is_fully_update = deltaData == nil
    if is_fully_update then
        local soldiers = {}
        local woundedSoldiers = {}
        local soldierStars = {}
        soldiers = user_data.soldiers
        woundedSoldiers = user_data.woundedSoldiers
        soldierStars = user_data.soldierStars
        if soldiers then
            local changed = {}
            local soldier_map = self.soldier_map
            for k, old in pairs(soldier_map) do
                local new = soldiers[k]
                if new and old ~= new then
                    soldier_map[k] = new
                    table.insert(changed, k)
                end
            end
            if #changed > 0 then
                self:NotifyListeneOnType(SoldierManager.LISTEN_TYPE.SOLDIER_CHANGED,function(listener)
                    listener:OnSoliderCountChanged(self, changed)
                end)
            end
        end
        if woundedSoldiers then
            -- 伤兵列表
            local treat_soldier_changed = {}
            local treatSoldiers_map = self.treatSoldiers_map
            for k, old in pairs(treatSoldiers_map) do
                local new = woundedSoldiers[k]
                if new and old ~= new then
                    treatSoldiers_map[k] = new
                    table.insert(treat_soldier_changed, k)
                end
            end

            if #treat_soldier_changed > 0 then
                self:NotifyListeneOnType(SoldierManager.LISTEN_TYPE.TREAT_SOLDIER_CHANGED,function(listener)
                    listener:OnTreatSoliderCountChanged(self, treat_soldier_changed)
                end)
            end
        end
        if soldierStars then
            local soldier_star_changed = {}
            for k,v in pairs(soldierStars) do
                self.soldierStars[k] = v
                table.insert(soldier_star_changed, k)
            end
            if #soldier_star_changed > 0 then
                self:NotifyListeneOnType(SoldierManager.LISTEN_TYPE.SOLDIER_STAR_CHANGED,function(listener)
                    listener:OnSoliderStarCountChanged(self, soldier_star_changed)
                end)
            end
        end
    end
    local is_delta_update = not is_fully_update and deltaData.soldiers ~= nil
    if is_delta_update then
        local soldier_map = self.soldier_map
        local changed = {}
        local old_soldier = {}
        for k, new in pairs(deltaData.soldiers) do
            local old = soldier_map[k]
            soldier_map[k] = new
            table.insert(changed, k)
            old_soldier[k] = {old = old,new = new}
        end
        if #changed > 0 then
            -- 士兵增加提示
            if display.getRunningScene().__cname ~= "MainScene" then
                local get_list = ""
                for k,v in pairs(old_soldier) do
                    local add = v.new-v.old
                    if add>0 then
                        local m_name = Localize.soldier_name[k]
                        get_list = get_list .. m_name .. "X"..add.." "
                    end
                end
                if get_list ~="" then
                    if deltaData.treatSoldierEvents and deltaData.treatSoldierEvents.remove then
                        GameGlobalUI:showTips(_("治愈士兵完成"),get_list)
                    elseif deltaData.soldierEvents and deltaData.soldierEvents.remove then
                        GameGlobalUI:showTips(_("招募士兵完成"),get_list)
                    end
                end
            end
            self:NotifyListeneOnType(SoldierManager.LISTEN_TYPE.SOLDIER_CHANGED,function(listener)
                listener:OnSoliderCountChanged(self, changed)
            end)
        end
    end
    is_delta_update = not is_fully_update and deltaData.woundedSoldiers ~= nil
    if is_delta_update then
        -- 伤兵列表
        local treat_soldier_changed = {}
        local treatSoldiers_map = self.treatSoldiers_map
        for k, new in pairs(deltaData.woundedSoldiers) do
            treatSoldiers_map[k] = new
            table.insert(treat_soldier_changed, k)
        end

        if #treat_soldier_changed > 0 then
            self:NotifyListeneOnType(SoldierManager.LISTEN_TYPE.TREAT_SOLDIER_CHANGED,function(listener)
                listener:OnTreatSoliderCountChanged(self, treat_soldier_changed)
            end)
        end
    end
    is_delta_update = not is_fully_update and deltaData.soldierStars ~= nil
    if is_delta_update then
        local soldier_star_changed = {}
        for k,new in pairs(deltaData.soldierStars) do
            local old = self.soldierStars[k]
            if old ~= new then
                self.soldierStars[k] = new
                table.insert(soldier_star_changed, k)
            end
        end
        if #soldier_star_changed > 0 then
            GameGlobalUI:showTips(_("士兵晋级完成"),string.format(_("晋级%s至%d星完成"),Localize.soldier_name[soldier_star_changed[1]],self:GetStarBySoldierType(soldier_star_changed[1])))
            self:NotifyListeneOnType(SoldierManager.LISTEN_TYPE.SOLDIER_STAR_CHANGED,function(listener)
                listener:OnSoliderStarCountChanged(self, soldier_star_changed)
            end)
        end
    end

    is_delta_update = not is_fully_update and deltaData.militaryTechs ~= nil
    --军事科技
    if is_fully_update then
        self:OnMilitaryTechsDataChanged(user_data.militaryTechs)
        self:OnMilitaryTechEventsChanged(user_data.militaryTechEvents)
        self:OnSoldierStarEventsChanged(user_data.soldierStarEvents)
    elseif is_delta_update then
        self:OnPartOfMilitaryTechsDataChanged(deltaData.militaryTechs)
    end


    is_delta_update = not is_fully_update and deltaData.militaryTechEvents ~= nil
    if is_delta_update then
        self:__OnMilitaryTechEventsChanged(deltaData.militaryTechEvents)
    end

    -- 士兵升星
    is_delta_update = not is_fully_update and deltaData.soldierStarEvents ~= nil
    if is_delta_update then
        self:__OnSoldierStarEventsChanged(deltaData.soldierStarEvents)
    end

end

function SoldierManager:OnMilitaryTechsDataChanged(militaryTechs)
    if not militaryTechs then return end
    self.militaryTechs = {}
    for name,v in pairs(militaryTechs) do
        local militaryTechnology = MilitaryTechnology.new()
        militaryTechnology:UpdateData(name,v)
        self.militaryTechs[name] = militaryTechnology
    end

    self:NotifyListeneOnType(SoldierManager.LISTEN_TYPE.MILITARY_TECHS_DATA_CHANGED, function(listener)
        listener:OnMilitaryTechsDataChanged(self,self.militaryTechs)
    end)
end
function SoldierManager:OnPartOfMilitaryTechsDataChanged(militaryTechs)
    local changed_map = {}
    for k,v in pairs(militaryTechs) do
        if self.militaryTechs[k] then
            self.militaryTechs[k]:UpdateData(k,v)
            changed_map[k] = self.militaryTechs[k]
        end
    end
    for k,v in pairs(changed_map) do
        GameGlobalUI:showTips(_("军事科技升级完成"),v:GetTechLocalize().."Lv"..v:Level())
    end
    self:NotifyListeneOnType(SoldierManager.LISTEN_TYPE.MILITARY_TECHS_DATA_CHANGED, function(listener)
        listener:OnMilitaryTechsDataChanged(self,changed_map)
    end)
end
function SoldierManager:GetMilitaryTechsLevelByName(name)
    return self.militaryTechs[name]:Level()
end
function SoldierManager:GetMilitaryTechsByName(name)
    return self.militaryTechs[name]
end
function SoldierManager:IteratorMilitaryTechs(func)
    for name,v in pairs(self.militaryTechs) do
        func(name,v)
    end
end

function SoldierManager:GetAllMilitaryBuffData()
    local all_military_buff = {}
    self:IteratorMilitaryTechs(function(name,tech)
        if tech:Level() > 0 then
            local effect_soldier,buff_field = unpack(string.split(name,"_"))
            table.insert(all_military_buff,{effect_soldier,buff_field,tech:GetAtkEff()})
        end
    end)
    return all_military_buff
end

function SoldierManager:GetMilitaryTechByName(name)
    return self.militaryTechs[name]
end
function SoldierManager:FindMilitaryTechsByBuildingType(building_type)
    local techs = {}
    self:IteratorMilitaryTechs(function ( name,v )
        if building_type == v:Building() then
            local _,focus_field = unpack(string.split(name,"_"))
            if focus_field == "infantry" then
                techs[1] = v
            elseif focus_field == "archer" then
                techs[2] = v
            elseif focus_field == "cavalry" then
                techs[3] = v
            elseif focus_field == "siege" then
                techs[4] = v
            elseif focus_field == "hpAdd" then
                techs[5] = v
            end
        end
    end)
    return techs
end
function SoldierManager:GetTechPointsByType(building_type)
    local config = GameDatas.MilitaryTechs.militaryTechs
    local techs = self:FindMilitaryTechsByBuildingType(building_type)

    local tech_points = 0
    for k,v in pairs(techs) do
        tech_points = tech_points + config[v:Name()].techPointPerLevel * v:Level()
    end
    return tech_points
end
function SoldierManager:GetMilitaryTechEvents()
    return self.militaryTechEvents
end
function SoldierManager:IteratorMilitaryTechEvents(func)
    for _,v in pairs(self.militaryTechEvents) do
        func(v)
    end
end
function SoldierManager:GetLatestMilitaryTechEvents(building_type)
    for _,event in pairs(self.militaryTechEvents) do
        if self.militaryTechs[event:Name()]:Building() == building_type then
            return event
        end
    end
end
function SoldierManager:GetUpgradingMilitaryTechNum(building_type)
    local count = 0
    for _,event in pairs(self.militaryTechEvents) do
        if self.militaryTechs[event:Name()]:Building() == building_type then
            count = count + 1
        end
    end
    for _,event in pairs(self.soldierStarEvents) do
        if self:FindSoldierBelongBuilding(event:Name()) == building_type then
            count = count + 1
        end
    end
    return count
end
function SoldierManager:IsUpgradingAnyMilitaryTech()
    return LuaUtils:table_size(self.militaryTechEvents) >0 or LuaUtils:table_size(self.soldierStarEvents) > 0
end
function SoldierManager:GetTotalUpgradingMilitaryTechNum()
    local count = LuaUtils:table_size(self.militaryTechEvents) + LuaUtils:table_size(self.soldierStarEvents)
    return count >4 and 4 or count
end
-- 对应建筑可以升级对应军事科技和兵种星级
function SoldierManager:IsUpgradingMilitaryTech(building_type)
    for _,event in pairs(self.militaryTechEvents) do
        if self.militaryTechs[event:Name()]:Building() == building_type then
            return true
        end
    end
    for _,event in pairs(self.soldierStarEvents) do
        if self:FindSoldierBelongBuilding(event:Name()) == building_type then
            return true
        end
    end
end
function SoldierManager:GetUpgradingMilitaryTech(building_type)
    local military_tech_event = self:GetLatestMilitaryTechEvents(building_type)
    local soldier_star_event = self:GetLatestSoldierStarEvents(building_type)
    local tech_start_time = military_tech_event and military_tech_event.startTime or 0
    local soldier_star_start_time = soldier_star_event and soldier_star_event.startTime or 0
    return  tech_start_time>soldier_star_start_time and military_tech_event or soldier_star_event
end
function SoldierManager:GetSoldierMaxStar()
    return 3
end
function SoldierManager:GetUpgradingMitiTaryTechLeftTimeByCurrentTime(building_type)
    local left_time = 0
    local event = self:GetUpgradingMilitaryTech(building_type)
    if event then
        left_time = left_time + event:FinishTime() - app.timer:GetServerTime()
    end
    return left_time
end
function SoldierManager:OnMilitaryTechEventsChanged(militaryTechEvents)
    if not militaryTechEvents then return end
    self.militaryTechEvents = {}
    for i,v in ipairs(militaryTechEvents) do
        local event = MilitaryTechEvents.new()
        event:UpdateData(v)
        event:AddObserver(self)
        self.militaryTechEvents[event:Id()] = event
        self:GeneralMilitaryTechLocalPush(event)
    end
    self:NotifyListeneOnType(SoldierManager.LISTEN_TYPE.MILITARY_TECHS_EVENTS_ALL_CHANGED, function(listener)
        listener:OnMilitaryTechEventsAllChanged(self,self.militaryTechEvents)
    end)
end
function SoldierManager:__OnMilitaryTechEventsChanged(__militaryTechEvents)
    if not __militaryTechEvents then return end
    local added,edited,removed = {},{},{}
    local changed_map = {added,edited,removed}
    local add = __militaryTechEvents.add
    local edit = __militaryTechEvents.edit
    local remove = __militaryTechEvents.remove
    if add then
        for k,data in pairs(add) do
            local event = MilitaryTechEvents.new()
            event:UpdateData(data)
            self.militaryTechEvents[event:Id()] = event
            event:AddObserver(self)
            table.insert(added, event)

            self:GeneralMilitaryTechLocalPush(event)
        end
    end
    if edit then
        for k,data in pairs(edit) do
            local event = self.militaryTechEvents[data.id]
            event:UpdateData(data)
            table.insert(edited, event)
            self:GeneralMilitaryTechLocalPush(event)
        end
    end
    if remove then
        for k,data in pairs(remove) do
            local event = self.militaryTechEvents[data.id]
            event:Reset()
            self.militaryTechEvents[data.id] = nil
            event = MilitaryTechEvents.new()
            event:UpdateData(data)
            table.insert(removed, event)
            self:CancelMilitaryTechLocalPush(event)
        end
    end
    self:NotifyListeneOnType(SoldierManager.LISTEN_TYPE.MILITARY_TECHS_EVENTS_CHANGED, function(listener)
        listener:OnMilitaryTechEventsChanged(self,changed_map)
    end)
end

function SoldierManager:FindSoldierStarByBuildingType(building_type)
    local soldiers_star = {}
    if building_type=="trainingGround" then
        soldiers_star.sentinel = self:GetStarBySoldierType("sentinel")
        soldiers_star.swordsman = self:GetStarBySoldierType("swordsman")
    elseif building_type=="stable" then
        soldiers_star.horseArcher = self:GetStarBySoldierType("horseArcher")
        soldiers_star.lancer = self:GetStarBySoldierType("lancer")
    elseif building_type=="hunterHall" then
        soldiers_star.ranger = self:GetStarBySoldierType("ranger")
        soldiers_star.crossbowman = self:GetStarBySoldierType("crossbowman")
    elseif building_type=="workshop" then
        soldiers_star.ballista = self:GetStarBySoldierType("ballista")
        soldiers_star.catapult = self:GetStarBySoldierType("catapult")
    end
    return soldiers_star
end
function SoldierManager:FindSoldierBelongBuilding(soldier_type)
    if soldier_type=="sentinel" or soldier_type=="swordsman" then
        return "trainingGround"
    elseif soldier_type=="horseArcher" or soldier_type=="lancer" then
        return "stable"
    elseif soldier_type=="ranger" or soldier_type=="crossbowman" then
        return "hunterHall"
    elseif soldier_type=="ballista" or soldier_type=="catapult"then
        return "workshop"
    end
end
function SoldierManager:GetSoldierStarEvents()
    return self.soldierStarEvents
end
function SoldierManager:IteratorSoldierStarEvents(func)
    for _,v in pairs(self.soldierStarEvents) do
        func(v)
    end
end
function SoldierManager:GetLatestSoldierStarEvents(building_type)
    for _,event in pairs(self.soldierStarEvents) do
        if self:FindSoldierBelongBuilding(event:Name()) == building_type then
            return event
        end
    end
end
function SoldierManager:OnSoldierStarEventsChanged(soldierStarEvents)
    if not soldierStarEvents then return end
    self.soldierStarEvents = {}
    for i,v in ipairs(soldierStarEvents) do
        local event = SoldierStarEvents.new()
        event:UpdateData(v)
        event:AddObserver(self)
        self.soldierStarEvents[event:Id()] = event
        self:GeneralSoldierLocalPush(event)
    end
    self:NotifyListeneOnType(SoldierManager.LISTEN_TYPE.ALL_SOLDIER_STAR_EVENTS_CHANGED, function(listener)
        listener:OnAllSoldierStarEventsChanged(self,self.soldierStarEvents)
    end)
end
function SoldierManager:GetPromotingSoldierName(building_type)
    local event = self:GetLatestSoldierStarEvents(building_type)
    if event then
        return event:Name()
    end
end
function SoldierManager:__OnSoldierStarEventsChanged(__soldierStarEvents)
    if not __soldierStarEvents then return end
    local added,edited,removed = {},{},{}
    local changed_map = {added,edited,removed}
    local add = __soldierStarEvents.add
    local edit = __soldierStarEvents.edit
    local remove = __soldierStarEvents.remove
    if add then
        for k,data in pairs(add) do
            local event = SoldierStarEvents.new()
            event:UpdateData(data)
            event:AddObserver(self)
            self.soldierStarEvents[event:Id()] = event
            table.insert(added, event)
            self:GeneralSoldierLocalPush(event)
        end
    end
    if edit then
        for k,data in pairs(edit) do
            local event = self.soldierStarEvents[data.id]
            event:UpdateData(data)
            table.insert(edited, event)
            self:GeneralSoldierLocalPush(event)
        end
    end
    if remove then
        for k,data in pairs(remove) do
            local event = self.soldierStarEvents[data.id]
            event:Reset()
            self.soldierStarEvents[data.id] = nil
            local event = SoldierStarEvents.new()
            event:UpdateData(data)
            table.insert(removed, event)
            self:CancelSoldierLocalPush(event)
        end
    end

    self:NotifyListeneOnType(SoldierManager.LISTEN_TYPE.SOLDIER_STAR_EVENTS_CHANGED, function(listener)
        listener:OnSoldierStarEventsChanged(self,changed_map)
    end)
end

function SoldierManager:OnTimer(current_time)
    self:IteratorSoldierStarEvents(function(star_event)
        star_event:OnTimer(current_time)
    end)
    self:IteratorMilitaryTechEvents(function(tech_event)
        tech_event:OnTimer(current_time)
    end)
end
function SoldierManager:OnSoldierStarEventsTimer(star_event)
    self:NotifyListeneOnType(SoldierManager.LISTEN_TYPE.OnSoldierStarEventsTimer,function(listener)
        listener.OnSoldierStarEventsTimer(listener,star_event)
    end)
end
function SoldierManager:OnMilitaryTechEventsTimer(tech_event)
    self:NotifyListeneOnType(SoldierManager.LISTEN_TYPE.OnMilitaryTechEventsTimer,function(listener)
        listener.OnMilitaryTechEventsTimer(listener,tech_event)
    end)
end
return SoldierManager

































