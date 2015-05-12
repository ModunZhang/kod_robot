--
-- Author: Danny He
-- Date: 2014-09-10 21:05:17
--
import('app.utils.Minheap')
local Localize = import("..utils.Localize")
local GameGlobalUIUtils = class('GameGlobalUIUtils')
local GameUICommonTips = import(".GameUICommonTips")

function GameGlobalUIUtils:ctor()
	self.tipsHeap = Minheap.new(function(a,b)
		return a.time < b.time
	end)
	self.increase_index = 0
end

function GameGlobalUIUtils:showTips(title,content)
	local instance = cc.Director:getInstance():getRunningScene():getChildByTag(1020)
	if not instance then
		self.commonTips = GameUICommonTips.new(self,2)
		assert(self.commonTips)
		cc.Director:getInstance():getRunningScene():addChild(self.commonTips, 1000000, 1020)
		-- self.commonTips:setVisible(false)
	end
	if self.commonTips:IsOpen() then
		self.increase_index = self.increase_index + 1
		self.tipsHeap:push({title=title,content = content,time = self.increase_index})
	else
		self.increase_index = 0
		self.commonTips:showTips(title,content)
	end
end

function GameGlobalUIUtils:onTipsMoveOut(tipsUI)
	if not self.tipsHeap:empty() then
		local message = self.tipsHeap:pop()
		tipsUI:showTips(message.title,message.content)
		return true
	end
	return false
end

function GameGlobalUIUtils:showMessageDialog(title,tips,ok_callback,cancel_callback,visible_x_button)
	return UIKit:showMessageDialog(title,tips,ok_callback,cancel_callback,visible_x_button)
end

function GameGlobalUIUtils:showBuildingLevelUp(msg)
	local buildingName = Localize.getBuildingLocalizedKeyByBuildingType(msg.buildingType)
    self:showTips(_("建筑升级完成"),string.format('%s(LV %d)',_(buildingName),msg.level))
end

function GameGlobalUIUtils:showWallLevelUp(msg)
	local buildingName = Localize.getBuildingLocalizedKeyByBuildingType(msg.buildingType)
    self:showTips(_("建筑升级完成"),string.format('%s(LV %d)',_(buildingName),msg.level))
end

function GameGlobalUIUtils:showHouseLevelUp(msg)
  	local houseName = Localize.getHouseLocalizedKeyByBuildingType(msg.houseType)
    self:showTips(_("小屋升级完成"),string.format('%s(LV %d)',_(houseName),msg.level))
end

GameGlobalUI = GameGlobalUIUtils.new()