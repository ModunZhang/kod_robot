--
-- Author: Kenny Dai
-- Date: 2015-02-09 19:46:14
--
local Observer = import(".Observer")
local Localize = import("..utils.Localize")
local HelpEvent = class("HelpEvent",Observer)
local property = import("..utils.property")

function HelpEvent:ctor()
    HelpEvent.super.ctor(self)
    property(self,"id","")
    local playerData = {}
    property(playerData,"id","")
    property(playerData,"name","")
    property(playerData,"vipExp",0)
    function playerData:OnPropertyChange()
    end
    self.playerData = playerData

    local eventData = {}
    property(eventData,"type","")
    property(eventData,"id","")
    property(eventData,"name","")
    property(eventData,"level",0)
    property(eventData,"maxHelpCount",0)
    property(eventData,"helpedMembers",{})
    function eventData:OnPropertyChange()
    end
    self.eventData = eventData
end

function HelpEvent:OnPropertyChange()
end

function HelpEvent:UpdateData(json_data)
    local json_data = clone(json_data)
    self:SetId(json_data.id)
    local playerData = json_data.playerData
    self.playerData:SetId(playerData.id)
    self.playerData:SetName(playerData.name)
    self.playerData:SetVipExp(playerData.vipExp)
    local eventData = json_data.eventData
    self.eventData:SetType(eventData.type)
    self.eventData:SetId(eventData.id)
    self.eventData:SetName(eventData.name)
    self.eventData:SetLevel(eventData.level)
    self.eventData:SetMaxHelpCount(eventData.maxHelpCount)

    -- 被帮助提示
    local effective_events = Alliance_Manager:GetMyAlliance():GetCouldShowHelpEvents()
    local is_live = false
    for i,v in ipairs(effective_events) do
        if v:Id()==self:Id() then
            is_live = true
            break
        end
    end
    if is_live and #eventData.helpedMembers~= #self.eventData:HelpedMembers() and playerData.id == User:Id() then
        local new_help_member
        for i,new in ipairs(eventData.helpedMembers) do
            new_help_member = clone(new)
            for k,old in ipairs(self.eventData:HelpedMembers()) do
                if old==new then
                    new_help_member = nil
                    break
                end
            end
            if new_help_member then
                local event_name
                if eventData.type == "buildingEvents" or eventData.type == "houseEvents" then
                    event_name = Localize.building_name[eventData.name]
                elseif eventData.type == "militaryTechEvents" then
                    local soldiers = string.split(eventData.name, "_")
                    local soldier_category = Localize.soldier_category
                    if soldiers[2] == "hpAdd" then
                        event_name = string.format(_("%s血量增加"),soldier_category[soldiers[1]])
                    else
                        event_name = string.format(_("%s对%s的攻击"),soldier_category[soldiers[1]],soldier_category[soldiers[2]])
                    end
                elseif eventData.type == "soldierStarEvents" then
                    event_name = string.format(_("晋升%s的星级"),Localize.soldier_name[eventData.name])
                elseif eventData.type == "productionTechEvents" then
                    event_name = Localize.productiontechnology_name[eventData.name]
                end
                local name = Alliance_Manager:GetMyAlliance():GetMemeberById(new_help_member):Name()
                GameGlobalUI:showTips(_("提示"),string.format(_("%s帮助升级%s成功"),name,event_name))
                break
            end
        end
    end
    self.eventData:SetHelpedMembers(eventData.helpedMembers)
    return self
end

function HelpEvent:GetPlayerData()
    return self.playerData
end
function HelpEvent:GetEventData()
    return self.eventData
end
function HelpEvent:IsHelpedByMe()
    local _id = User:Id()
    local helpedMembers = self.eventData:HelpedMembers()
    for k,id in pairs(helpedMembers) do
        if id == _id then
            return true
        end
    end
end
return HelpEvent




