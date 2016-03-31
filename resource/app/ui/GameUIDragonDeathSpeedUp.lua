--
-- Author: Danny He
-- Date: 2015-02-14 09:08:03
--
local WidgetSpeedUp = import("..widget.WidgetSpeedUp")
local GameUIDragonDeathSpeedUp = class("GameUIDragonDeathSpeedUp", WidgetSpeedUp)
local GameUtils = GameUtils
local Localize = import("..utils.Localize")
local DragonManager = import("..entity.DragonManager")

function GameUIDragonDeathSpeedUp:ctor(dragonType)
	GameUIDragonDeathSpeedUp.super.ctor(self)
	local event 
	for i,v in ipairs(User.dragonDeathEvents) do
		if v.dragonType == dragonType then
			event = v
		end
	end
	if not event then
		self:LeftButtonClicked()
	end
	self.event = event
	self:SetAccBtnsGroup(self:GetEventType(), event.id)
    self:SetAccTips(_("龙的复活没有免费加速"))
    self:SetUpgradeTip(Localize.dragon[dragonType] .. _("正在复活"))
	scheduleAt(self, function()
        local time, percent = UtilsForEvent:GetEventInfo(self.event)
        self:SetProgressInfo(GameUtils:formatTimeStyle1(time), percent)
    end)

    User:AddListenOnType(self, "dragonDeathEvents")
end
function GameUIDragonDeathSpeedUp:CheckCanSpeedUpFree()
	return false
end
function GameUIDragonDeathSpeedUp:onExit()
    User:RemoveListenerOnType(self, "dragonDeathEvents")
    GameUIDragonDeathSpeedUp.super.onExit(self)
end
function GameUIDragonDeathSpeedUp:GetEventType()
	return "dragonDeathEvents"
end
function GameUIDragonDeathSpeedUp:OnUserDataChanged_dragonDeathEvents(userData, deltaData)
	local ok, value = deltaData("dragonDeathEvents.remove")
    if ok then
        for i,v in ipairs(value) do
            if v.id == self.event.id then
                self:LeftButtonClicked()
                return
            end
        end
    end
    local ok, value = deltaData("dragonDeathEvents.edit")
    if ok then
        for i,v in ipairs(value) do
            if v.id == self.event.id then
                self.event = v
            end
        end
    end
end

return GameUIDragonDeathSpeedUp