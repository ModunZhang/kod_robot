--
-- Author: Kenny Dai
-- Date: 2015-01-21 20:24:34
--
local WidgetSpeedUp = import("..widget.WidgetSpeedUp")
local WidgetMilitrayTechSpeedUp = class("WidgetMilitrayTechSpeedUp",WidgetSpeedUp)
local WidgetAccelerateGroup = import("..widget.WidgetAccelerateGroup")

function WidgetMilitrayTechSpeedUp:ctor()
	WidgetMilitrayTechSpeedUp.super.ctor(self)
	local soldier_manager = City:GetSoldierManager()
	if soldier_manager:IsUpgradingMilitaryTech() then
		self.militaryTechEvent = soldier_manager:GetUpgradingMilitaryTech()
	end
	self:SetAccBtnsGroup(WidgetAccelerateGroup.SPEEDUP_TYPE.TECHNOLOGY,function()end)
	if not self.militaryTechEvent then
		self:LeftButtonClicked()
	else
		local event = self.militaryTechEvent
		City:AddListenOnType(self,City.LISTEN_TYPE.PRODUCTION_EVENT_CHANGED)
	    City:AddListenOnType(self,City.LISTEN_TYPE.PRODUCTION_EVENT_TIMER)
		self:SetUpgradeTip(string.format(_("正在研发%s到 Level %d"),event:Entity():GetLocalizedName(),event:Entity():GetNextLevel()))
	    self:SetProgressInfo(GameUtils:formatTimeStyle1(event:GetTime()),event:GetPercent())
		self:CheckCanSpeedUpFree()
		self:OnFreeButtonClicked(handler(self, self.FreeSpeedUpAction))
	end
end

function WidgetMilitrayTechSpeedUp:FreeSpeedUpAction()
	NetManager:getFreeSpeedUpPromise("productionTechEvents",self:GetEvent():Id()):done(function()
		self:LeftButtonClicked()
	end)
end

function WidgetMilitrayTechSpeedUp:onCleanup()
	City:RemoveListenerOnType(self,City.LISTEN_TYPE.PRODUCTION_EVENT_CHANGED)
	City:RemoveListenerOnType(self,City.LISTEN_TYPE.PRODUCTION_EVENT_TIMER)
end

function WidgetMilitrayTechSpeedUp:OnProductionTechnologyEventDataChanged(changed_map)

end

function WidgetMilitrayTechSpeedUp:OnProductionTechnologyEventTimer(event)
	if self.progress then
		self:SetProgressInfo(GameUtils:formatTimeStyle1(event:GetTime()),event:GetPercent())
		self:CheckCanSpeedUpFree()
	end
end

function WidgetMilitrayTechSpeedUp:GetEvent()
	return self.technologyEvent
end

function WidgetMilitrayTechSpeedUp:CheckCanSpeedUpFree()
	self:SetFreeButtonEnabled(self:GetEvent():GetTime() <= 60 * 5)
end

return WidgetMilitrayTechSpeedUp