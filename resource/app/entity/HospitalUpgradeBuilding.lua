
local NORMAL = GameDatas.Soldiers.normal
local SPECIAL = GameDatas.Soldiers.special
local config_function = GameDatas.BuildingFunction.hospital
local Observer = import(".Observer")
local Enum = import("..utils.Enum")
local Localize = import("..utils.Localize")
local UpgradeBuilding = import(".UpgradeBuilding")
local HospitalUpgradeBuilding = class("HospitalUpgradeBuilding", UpgradeBuilding)
HospitalUpgradeBuilding.CAN_NOT_TREAT = Enum("TREATING","LACK_RESOURCE","TREATING_AND_LACK_RESOURCE")

function HospitalUpgradeBuilding:ctor(building_info)
    self.hospital_building_observer = Observer.new()
    self.soldier_star = 1
    self.treat_event = self:CreateEvent()
    HospitalUpgradeBuilding.super.ctor(self, building_info)
end
function HospitalUpgradeBuilding:CreateEvent()
    local hospital = self
    local event = {}
    function event:Init()
        self:Reset()
    end
    function event:Reset()
        self.soldiers = nil
        self.finished_time = 0
        self.id = nil
    end
    function event:SetTreatInfo(soldiers, finish_time , id)
        local old_id = self.id
        self.soldiers = soldiers
        self.finished_time = finish_time
        self.id = id
        if soldiers and finish_time~=0 and id then
            hospital:GeneralSoldierLocalPush(self)
        else
            hospital:CancelSoldierLocalPush(old_id)
        end
    end
    function event:StartTime()
        return self.finished_time - self:GetTreatingTime()
    end
    function event:Id()
        return self.id
    end
    function event:GetTreatingTime()
        return hospital:GetTreatingTimeByTypeWithCount(self.soldiers)
    end
    function event:ElapseTime(current_time)
        return current_time - self:StartTime()
    end
    function event:LeftTime(current_time)
        return self.finished_time - current_time
    end
    function event:Percent(current_time)
        local start_time = self:StartTime()
        local elapse_time = current_time - start_time
        local total_time = self.finished_time - start_time
        return elapse_time * 100.0 / total_time
    end
    function event:FinishTime()
        return self.finished_time
    end
    function event:SetFinishTime(current_time)
        self.finished_time = current_time
    end
    function event:IsEmpty()
        return self.soldiers == nil
    end
    function event:IsTreating()
        return not not self.soldiers
    end
    function event:GetTreatInfo()
        return self.soldiers
    end
    event:Init()
    return event
end
function HospitalUpgradeBuilding:GeneralSoldierLocalPush(event)
    if ext and ext.localpush then
        local soldiers = event:GetTreatInfo()
        local pushIdentity = event:Id()
        local soldiers_desc = ""
        for k,v in pairs(soldiers) do
            local soldier_type = v.name
            local count = v.count
            soldiers_desc = soldiers_desc .. string.format(_("%s X %d "),Localize.soldier_name[soldier_type],count)
        end
        local title = string.format(_("治愈%s完成"),soldiers_desc)
        app:GetPushManager():UpdateSoldierPush(event:FinishTime(),title,pushIdentity)
    end
end
function HospitalUpgradeBuilding:CancelSoldierLocalPush(id)
    if ext and ext.localpush then
        app:GetPushManager():CancelSoldierPush(id)
    end
end
function HospitalUpgradeBuilding:ResetAllListeners()
    HospitalUpgradeBuilding.super.ResetAllListeners(self)
    self.hospital_building_observer:RemoveAllObserver()
end
function HospitalUpgradeBuilding:AddHospitalListener(listener)
    assert(listener.OnBeginTreat)
    assert(listener.OnTreating)
    assert(listener.OnEndTreat)
    self.hospital_building_observer:AddObserver(listener)
end
function HospitalUpgradeBuilding:RemoveHospitalListener(listener)
    self.hospital_building_observer:RemoveObserver(listener)
end
function HospitalUpgradeBuilding:GetTreatEvent()
    return self.treat_event
end
function HospitalUpgradeBuilding:IsTreatEventEmpty()
    return self.treat_event:IsEmpty()
end
function HospitalUpgradeBuilding:IsTreating()
    return not self.treat_event:IsEmpty()
end
function HospitalUpgradeBuilding:TreatSoldiersWithFinishTime(soldiers, finish_time, id)
    local event = self.treat_event
    event:SetTreatInfo(soldiers, finish_time, id)
    self.hospital_building_observer:NotifyObservers(function(listener)
        listener:OnBeginTreat(self, event)
    end)
end
function HospitalUpgradeBuilding:EndTreatSoldiersWithCurrentTime(current_time)
    local event = self.treat_event
    local soldiers = self.treat_event.soldiers
    event:SetTreatInfo(nil, 0,nil)
    self.hospital_building_observer:NotifyObservers(function(listener)
        listener:OnEndTreat(self, event, soldiers, current_time)
    end)
end
-- 获取治疗士兵时间
function HospitalUpgradeBuilding:GetTreatingTimeByTypeWithCount(soldiers)
    local treat_time = 0
    for k,v in pairs(soldiers) do
        local soldier_type = v.name
        local count = v.count
        local soldier_config = self:GetSoldierConfigByType(soldier_type)
        treat_time = treat_time + soldier_config["treatTime"] * count
    end
    return treat_time
end
function HospitalUpgradeBuilding:GetSoldierConfigByType(soldier_type)
     local star = City:GetSoldierManager():GetStarBySoldierType(soldier_type)
    local config_name = soldier_type.."_"..star
    local config = NORMAL[config_name] or SPECIAL[soldier_type]
    return config
end
function HospitalUpgradeBuilding:OnTimer(current_time)
    local event = self.treat_event
    if event:IsTreating() then
        self.hospital_building_observer:NotifyObservers(function(listener)
            listener:OnTreating(self, event, current_time)
        end)
    end
    HospitalUpgradeBuilding.super.OnTimer(self, current_time)
end

function HospitalUpgradeBuilding:OnUserDataChanged(...)
    HospitalUpgradeBuilding.super.OnUserDataChanged(self, ...)
    local userData, current_time, location_id, sub_location_id, deltaData = ...

    if not userData.treatSoldierEvents then return end

    local is_fully_update = deltaData == nil
    local is_delta_update = self:IsUnlocked() and deltaData and deltaData.treatSoldierEvents
    if not is_fully_update and not is_delta_update then
        return
    end
    local soldierEvent = userData.treatSoldierEvents[1]
    if soldierEvent then
        local finished_time = soldierEvent.finishTime / 1000
        if self.treat_event:IsEmpty() then
            self:TreatSoldiersWithFinishTime(soldierEvent.soldiers, finished_time,soldierEvent.id)
        else
            self.treat_event:SetTreatInfo(soldierEvent.soldiers, finished_time ,soldierEvent.id)
        end
    else
        if self.treat_event:IsTreating() then
            self:EndTreatSoldiersWithCurrentTime(current_time)
        end
    end
end

function HospitalUpgradeBuilding:IsAbleToTreat(soldiers)
    local total_coin = City:GetSoldierManager():GetTreatResource(soldiers)
    local resource_state =  City:GetResourceManager():GetCoinResource():GetResourceValueByCurrentTime(app.timer:GetServerTime())<total_coin

    if self:IsTreating() and resource_state then
        return HospitalUpgradeBuilding.CAN_NOT_TREAT.TREATING_AND_LACK_RESOURCE
    elseif self:IsTreating() then
        return HospitalUpgradeBuilding.CAN_NOT_TREAT.TREATING
    elseif resource_state then
        return HospitalUpgradeBuilding.CAN_NOT_TREAT.LACK_RESOURCE
    end
end
-- 普通治疗需要的金龙币
function HospitalUpgradeBuilding:GetTreatGems(soldiers)
    local total_coin = City:GetSoldierManager():GetTreatResource(soldiers)
    local resource_state =  City:GetResourceManager():GetCoinResource():GetResourceValueByCurrentTime(app.timer:GetServerTime())<total_coin

    local need_gems = 0
    if resource_state then
        need_gems = DataUtils:buyResource({coin=total_coin},{coin=City:GetResourceManager():GetCoinResource()})
    end
    if self:IsTreating() then
        need_gems = need_gems +DataUtils:getGemByTimeInterval(self:GetTreatEvent():LeftTime(app.timer:GetServerTime()))
    end
    return need_gems
end
--  立即治疗需要金龙币
function HospitalUpgradeBuilding:GetTreatNowGems(soldiers)
    local total_time = City:GetSoldierManager():GetTreatTime(soldiers)
    need_gems = DataUtils:getGemByTimeInterval(total_time)
    local total_coin = City:GetSoldierManager():GetTreatResource(soldiers)
    need_gems = need_gems + DataUtils:buyResource({coin=total_coin},{})
    return need_gems
end

--获取下一级伤病最大上限
function HospitalUpgradeBuilding:GetNextLevelMaxCasualty()
    return config_function[self:GetNextLevel()].maxCitizen
end
--获取伤病最大上限
function HospitalUpgradeBuilding:GetMaxCasualty()
    if self:GetLevel() > 0 then
        return config_function[self:GetEfficiencyLevel()].maxCitizen
    end
    return 0
end
--获取战斗伤病比例
function HospitalUpgradeBuilding:GetCasualtyRate()
    if self:GetLevel() > 0 then
        return config_function[self:GetEfficiencyLevel()].casualtyRate
    end
    return 0
end

return HospitalUpgradeBuilding












