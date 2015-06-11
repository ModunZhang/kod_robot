--
-- Author: Danny He
-- Date: 2015-02-14 09:08:03
--
local WidgetSpeedUp = import("..widget.WidgetSpeedUp")
local GameUIDragonDeathSpeedUp = class("GameUIDragonDeathSpeedUp", WidgetSpeedUp)
local GameUtils = GameUtils
local Localize = import("..utils.Localize")
local DragonManager = import("..entity.DragonManager")

function GameUIDragonDeathSpeedUp:ctor(dragon_manager,dragon_type)
	GameUIDragonDeathSpeedUp.super.ctor(self)
	local dragonDeathEvent = dragon_manager:GetDragonDeathEventByType(dragon_type) 
	self:SetAccBtnsGroup(self:GetEventType(),dragonDeathEvent:Id())
    self:SetAccTips(_("龙的复活没有免费加速"))
    self:SetUpgradeTip(Localize.dragon[dragonDeathEvent:DragonType()] .. _("正在复活"))
    self.dragonDeathEvent = dragonDeathEvent
    self.dragon_manager = City:GetDragonEyrie():GetDragonManager()
	self.dragon_manager:AddListenOnType(self,DragonManager.LISTEN_TYPE.OnDragonDeathEventChanged)
	self:SetProgressInfo(GameUtils:formatTimeStyle1(dragonDeathEvent:GetTime()),dragonDeathEvent:GetPercent())
	self.dragon_type = dragonDeathEvent:DragonType()
end

function GameUIDragonDeathSpeedUp:CheckCanSpeedUpFree()
	return false
end

function GameUIDragonDeathSpeedUp:onEnter()
	GameUIDragonDeathSpeedUp.super.onEnter(self)
	self.dragonDeathEvent:AddObserver(self)
end

function GameUIDragonDeathSpeedUp:GetEventType()
	return "dragonDeathEvents"
end

function GameUIDragonDeathSpeedUp:onCleanup()
    self.dragonDeathEvent:RemoveObserver(self)
    self.dragon_manager:RemoveListenerOnType(self,DragonManager.LISTEN_TYPE.OnDragonDeathEventChanged)
    GameUIDragonDeathSpeedUp.super.onCleanup(self)
end

function GameUIDragonDeathSpeedUp:OnDragonDeathEventChanged(changed_map)
	local dragonDeathEvent = self.dragon_manager:GetDragonDeathEventByType(self.dragon_type)
	if not dragonDeathEvent then 
		self:LeftButtonClicked()
	end
end

function GameUIDragonDeathSpeedUp:OnDragonDeathEventTimer(event)
	if event:GetTime() >= 0 then
	 	self:SetProgressInfo(GameUtils:formatTimeStyle1(event:GetTime()),event:GetPercent())
	end
end

return GameUIDragonDeathSpeedUp