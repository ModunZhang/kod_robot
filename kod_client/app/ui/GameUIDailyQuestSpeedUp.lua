--
-- Author: Kenny Dai
-- Date: 2015-05-06 09:04:00
--
local WidgetSpeedUp = import("..widget.WidgetSpeedUp")
local Localize = import("..utils.Localize")
local GameUIDailyQuestSpeedUp = class("GameUIDailyQuestSpeedUp",WidgetSpeedUp)
local GameUtils = GameUtils

function GameUIDailyQuestSpeedUp:ctor(quest)
    GameUIDailyQuestSpeedUp.super.ctor(self)
    dump(quest)
    self.quest = quest
    self:SetAccBtnsGroup(self:GetEventType(),quest.id)
    self:SetAccTips(_("每日任务不能免费加速"))
    self:SetUpgradeTip(string.format(_("正在%s"),Localize.daily_quests_name[quest.index]))

    User:AddListenOnType(self, "dailyQuestEvents")

    scheduleAt(self, function()
        local current_time = app.timer:GetServerTime()
        local quest = self.quest
        local show_time = quest.finishTime/1000-current_time <0 and 0 or quest.finishTime/1000-current_time
        if show_time == 0 then
            self:LeftButtonClicked()
            return
        end
        self:SetProgressInfo(GameUtils:formatTimeStyle1(show_time), 100-(quest.finishTime-current_time*1000)/(quest.finishTime-quest.startTime)*100 )
    end)
end

function GameUIDailyQuestSpeedUp:GetEventType()
    return "dailyQuestEvents"
end
function GameUIDailyQuestSpeedUp:onCleanup()
    GameUIDailyQuestSpeedUp.super.onCleanup(self)
end
function GameUIDailyQuestSpeedUp:onExit()
    User:RemoveListenerOnType(self, "dailyQuestEvents")
    GameUIDailyQuestSpeedUp.super.onExit(self)
end
function GameUIDailyQuestSpeedUp:CheckCanSpeedUpFree()
    return false
end
function GameUIDailyQuestSpeedUp:OnTimer(current_time)
    local quest = self.quest
    local show_time = quest.finishTime/1000-current_time <0 and 0 or quest.finishTime/1000-current_time
    if show_time == 0 then
        self:LeftButtonClicked()
        return
    end
    self:SetProgressInfo(GameUtils:formatTimeStyle1(show_time), 100-(quest.finishTime-current_time*1000)/(quest.finishTime-quest.startTime)*100 )
end
function GameUIDailyQuestSpeedUp:OnUserDataChanged_dailyQuestEvents(userData, deltaData)
    local quest = self.quest
    local ok, value = deltaData("dailyQuestEvents.edit")
    if ok then
        for k,v in pairs(value) do
            if v.id == quest.id then
            	self.quest = v
                local show_time = v.finishTime/1000-app.timer:GetServerTime() <0 and 0 or v.finishTime/1000-app.timer:GetServerTime()
                if show_time == 0 then
                    self:LeftButtonClicked()
                    return
                end
                self:SetProgressInfo(GameUtils:formatTimeStyle1(show_time), 100-(v.finishTime-app.timer:GetServerTime()*1000)/(v.finishTime-v.startTime)*100 )
            end
        end
    end

    local ok, value = deltaData("dailyQuestEvents.remove")
    if ok then
        for k,v in pairs(value) do
            if v.id == quest.id then
                self:LeftButtonClicked()
                return
            end
        end
    end
end
return GameUIDailyQuestSpeedUp



