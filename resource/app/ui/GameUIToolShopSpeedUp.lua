--
-- Author: Kenny Dai
-- Date: 2015-02-11 16:50:55
--
local Localize = import("..utils.Localize")
local WidgetSpeedUp = import("..widget.WidgetSpeedUp")
local GameUIToolShopSpeedUp = class("GameUIToolShopSpeedUp",WidgetSpeedUp)
local GameUtils = GameUtils

function GameUIToolShopSpeedUp:ctor(building)
    GameUIToolShopSpeedUp.super.ctor(self)
    local User = User
    local event = User:GetMakingMaterialsEvent()
    if not event then
        self:LeftButtonClicked()
        return 
    end
    self.event = event
    self:SetAccBtnsGroup(self:GetEventType(), event.id)
    self:SetAccTips(_("生产材料不能免费加速"))
    self:SetUpgradeTip(_("制造材料").."X "..building:GetProduction())

    User:AddListenOnType(self, "materialEvents")
    scheduleAt(self, function()
        local event = User:GetMakingMaterialsEvent()
        if not event then
            self:LeftButtonClicked()
            return 
        end
        local time, percent = UtilsForEvent:GetEventInfo(event)
        self:SetProgressInfo(GameUtils:formatTimeStyle1(time), percent)
    end)
end
function GameUIToolShopSpeedUp:GetEventType()
    return "materialEvents"
end
function GameUIToolShopSpeedUp:onCleanup()
    User:RemoveListenerOnType(self, "materialEvents")
    GameUIToolShopSpeedUp.super.onCleanup(self)
end

function GameUIToolShopSpeedUp:CheckCanSpeedUpFree()
	return false
end
function GameUIToolShopSpeedUp:OnUserDataChanged_materialEvents(userData, deltaData)
    local ok, value = deltaData("materialEvents.edit")
    if ok then
        for i,v in ipairs(value) do
            if v.id == self.event.id then
                self.event = v
                if v.finishTime == 0 then
                    self:LeftButtonClicked()
                end
                return
            end
        end
    end
end
return GameUIToolShopSpeedUp





