--
-- Author: Danny He
-- Date: 2015-01-19 14:18:33
--
local WidgetSpeedUp = import("..widget.WidgetSpeedUp")
local GameUITechnologySpeedUp = class("GameUITechnologySpeedUp",WidgetSpeedUp)
local WidgetAccelerateGroup = import("..widget.WidgetAccelerateGroup")
local GameUtils = GameUtils

function GameUITechnologySpeedUp:ctor()
	GameUITechnologySpeedUp.super.ctor(self)
	if City:HaveProductionTechEvent() then
		self.technologyEvent = City:GetProductionTechEventsArray()[1]
	end
	if not self.technologyEvent then
		self:LeftButtonClicked()
	else
		local event = self.technologyEvent
		self:SetAccBtnsGroup("productionTechEvents",event:Id())
		City:AddListenOnType(self,City.LISTEN_TYPE.PRODUCTION_EVENT_CHANGED)
	    City:AddListenOnType(self,City.LISTEN_TYPE.PRODUCTION_EVENT_TIMER)
		self:SetUpgradeTip(string.format(_("正在研发%s到 Level %d"),event:Entity():GetLocalizedName(),event:Entity():GetNextLevel()))
	    self:SetProgressInfo(GameUtils:formatTimeStyle1(event:GetTime()),event:GetPercent())
		self:CheckCanSpeedUpFree()
		self:OnFreeButtonClicked(handler(self, self.FreeSpeedUpAction))
	end
end

function GameUITechnologySpeedUp:FreeSpeedUpAction()
	NetManager:getFreeSpeedUpPromise("productionTechEvents",self:GetEvent():Id()):done(function()
		self:LeftButtonClicked()
	end)
end

function GameUITechnologySpeedUp:onCleanup()
	City:RemoveListenerOnType(self,City.LISTEN_TYPE.PRODUCTION_EVENT_CHANGED)
	City:RemoveListenerOnType(self,City.LISTEN_TYPE.PRODUCTION_EVENT_TIMER)
    GameUITechnologySpeedUp.super.onCleanup(self)
end

function GameUITechnologySpeedUp:OnProductionTechnologyEventDataChanged(changed_map)
	local upgrading_event = City:GetProductionTechEventsArray()[1]
	if not upgrading_event or not self:GetEvent() or upgrading_event:Id() ~= self:GetEvent():Id() then
		self:LeftButtonClicked()
	end
end

function GameUITechnologySpeedUp:OnProductionTechnologyEventTimer(event)
	if self.progress then
		self:SetProgressInfo(GameUtils:formatTimeStyle1(event:GetTime()),event:GetPercent())
		self:CheckCanSpeedUpFree()
	end
end

function GameUITechnologySpeedUp:GetEvent()
	return self.technologyEvent
end

function GameUITechnologySpeedUp:CheckCanSpeedUpFree()
	self:SetFreeButtonEnabled(self:GetEvent():GetTime() <= DataUtils:getFreeSpeedUpLimitTime())
end

return GameUITechnologySpeedUp