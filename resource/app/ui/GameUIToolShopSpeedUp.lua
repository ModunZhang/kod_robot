--
-- Author: Kenny Dai
-- Date: 2015-02-11 16:50:55
--
local WidgetSpeedUp = import("..widget.WidgetSpeedUp")
local SoldierManager = import("..entity.SoldierManager")
local Localize = import("..utils.Localize")
local GameUIToolShopSpeedUp = class("GameUIToolShopSpeedUp",WidgetSpeedUp)
local GameUtils = GameUtils

function GameUIToolShopSpeedUp:ctor(building)
    GameUIToolShopSpeedUp.super.ctor(self)
    self.building = building

    local technology_event = building:GetTechnologyEvent()
    local building_event = building:GetBuildingEvent()

    local event = (technology_event:IsMaking(app.timer:GetServerTime()) and technology_event) or (building_event:IsMaking(app.timer:GetServerTime()) and building_event)
    self:SetAccBtnsGroup(self:GetEventType(),event:Id())
    self:SetAccTips(_("生产材料不能免费加速"))
    self:SetUpgradeTip(_("制造材料").."X 1")
    self:SetProgressInfo(GameUtils:formatTimeStyle1(event:LeftTime(app.timer:GetServerTime())),event:Percent(app.timer:GetServerTime()))
    building:AddToolShopListener(self)
end

function GameUIToolShopSpeedUp:GetEventType()
    return "materialEvents"
end
function GameUIToolShopSpeedUp:onCleanup()
    self.building:RemoveToolShopListener(self)
    GameUIToolShopSpeedUp.super.onCleanup(self)
end

function GameUIToolShopSpeedUp:CheckCanSpeedUpFree()
	return false
end
function GameUIToolShopSpeedUp:OnBeginMakeMaterialsWithEvent(tool_shop, event)
    self:OnRecruiting(tool_shop, event, app.timer:GetServerTime())
end
function GameUIToolShopSpeedUp:OnMakingMaterialsWithEvent(tool_shop, event, current_time)
    self:SetProgressInfo(GameUtils:formatTimeStyle1(event:LeftTime(current_time)),event:Percent(current_time))
end

function GameUIToolShopSpeedUp:OnEndMakeMaterialsWithEvent(tool_shop, event, current_time)
    self:LeftButtonClicked()
end
function GameUIToolShopSpeedUp:OnGetMaterialsWithEvent(tool_shop, event)
end
return GameUIToolShopSpeedUp





