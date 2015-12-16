--
-- Author: Danny He
-- Date: 2015-05-03 10:03:02
--
local promise = import("..utils.promise")
local WidgetPushButton = import("..widget.WidgetPushButton")
local manager = ccs.ArmatureDataManager:getInstance()
local UILib = import(".UILib")
local GameUIShowDragonUpStarAnimation = UIKit:createUIClass("GameUIShowDragonUpStarAnimation","UIAutoClose")

function GameUIShowDragonUpStarAnimation:ctor(dragon)
	self:DisableAutoClose()
	GameUIShowDragonUpStarAnimation.super.ctor(self)
	local add_strenth,add_vitality,add_leadershiip = dragon:GetPromotionedDifferentVal()
	self.buff_value = {
		string.format("%d(+%d)",dragon:Strength(),add_strenth),
		string.format("%d(+%d)",dragon:Vitality(),add_vitality),
		string.format("%d(+%d)",dragon:Leadership(),add_leadershiip),
	}
	self.dragon_iamge = UILib.dragon_head[dragon:Type()]
	self:setNodeEventEnabled(true)
	manager:addArmatureFileInfo(DEBUG_GET_ANIMATION_PATH("animations/jinjichenggong.ExportJson"))
	self.star_val = dragon:Star()
end

function GameUIShowDragonUpStarAnimation:onEnter()
	GameUIShowDragonUpStarAnimation.super.onEnter(self)
	self:DisableAutoClose()
	--构建UI
	local node = display.newNode()
	self:addTouchAbleChild(node)
	local bg = ccs.Armature:create("jinjichenggong"):addTo(node):center() -- 201 
	local juhua = ccs.Armature:create("jinjichenggong"):addTo(node):center()
	local header = ccs.Armature:create("jinjichenggong"):addTo(node):center() -- 301
	local star = ccs.Armature:create("jinjichenggong"):addTo(node):center()
	self.dragon_icon = display.newSprite(self.dragon_iamge):pos(0,202):addTo(header):zorder(100):hide()
	self.title_label = UIKit:ttfLabel({
		text = _("晋级成功"),
		color= 0xffffff,
		size = 38
	}):addTo(header):align(display.CENTER_BOTTOM, 0, 50):hide()

	self.ok_button = WidgetPushButton.new({normal = "transparent_1x1.png"}):setButtonLabel("normal", UIKit:commonButtonLable({
		text = _("确定"),
		size = 22,
		color= 0xfff3c7,
	})):addTo(header):align(display.CENTER_BOTTOM, 0, -140):onButtonClicked(function()
		self:removeSelf()
	end):hide()

	self.strength_title_label = UIKit:ttfLabel({
		text = _("力量"),
		size = 20,
		color= 0xffedae
	}):addTo(header):align(display.LEFT_CENTER, -200, 15):hide()

	self.strength_val_label = UIKit:ttfLabel({
		text = self.buff_value[1],
		size = 22,
		color= 0x7eff00
	}):addTo(header):align(display.LEFT_CENTER, 100, 15):hide()

	self.vitality_title_label = UIKit:ttfLabel({
		text = _("活力"),
		size = 20,
		color= 0xffedae
	}):addTo(header):align(display.LEFT_CENTER, -200, -35):hide()

	self.vitality_val_label = UIKit:ttfLabel({
		text = self.buff_value[2],
		size = 22,
		color= 0x7eff00
	}):addTo(header):align(display.LEFT_CENTER, 100, -35):hide()

	self.leadship_title_label = UIKit:ttfLabel({
		text = _("领导力"),
		size = 20,
		color= 0xffedae
	}):addTo(header):align(display.LEFT_CENTER, -200, -85):hide()

	self.leadship_val_label = UIKit:ttfLabel({
		text = self.buff_value[3],
		size = 22,
		color= 0x7eff00
	}):addTo(header):align(display.LEFT_CENTER, 100, -85):hide()
	-- 开始播放
	juhua:getAnimation():play("ceng_2", -1, -1) 
	self:PlayAnimationWithFrameEventCallFunc(header,"ceng_1",301):next(function() -- 301 时出现龙头
		self.dragon_icon:show()
	end)
	self:PlayAnimationWithFrameEventCallFunc(bg,"ceng_3",201):next(function() -- 201时出现文字
		self.title_label:show()
		self.ok_button:show()
		self.strength_title_label:show()
		self.vitality_title_label:show()
		self.leadship_title_label:show()
		self.strength_val_label:show()
		self.vitality_val_label:show()
		self.leadship_val_label:show()
		self:DisableAutoClose(false)
	end)
	self:PlayStarPromise(star,tonumber(self.star_val))
end

function GameUIShowDragonUpStarAnimation:onCleanup()
	GameUIShowDragonUpStarAnimation.super.onCleanup(self)
	manager:removeArmatureFileInfo(DEBUG_GET_ANIMATION_PATH("animations/jinjichenggong.ExportJson"))
end


function GameUIShowDragonUpStarAnimation:PlayStarPromise(armature,star)
	local p = promise.new()
	local animation = armature:getAnimation()
	animation:play("ceng_4", -1, 0)
	animation:setFrameEventCallFunc(function(bone,frameEventName,originFrameIndex,currentFrameIndex)
		if tonumber(frameEventName) - 100 == star then -- 101 ～ 105 表示每一颗星级
			animation:stop()
			p:resolve()
		end
	end)
	return p
end

function GameUIShowDragonUpStarAnimation:PlayAnimationWithFrameEventCallFunc(armature,name,frameIndex)
	frameIndex = tonumber(frameIndex)
	local p = promise.new()
	local animation = armature:getAnimation()
	animation:play(name, -1, 0)
	animation:setFrameEventCallFunc(function(bone,frameEventName,originFrameIndex,currentFrameIndex)
		if tonumber(frameEventName) == frameIndex then
			animation:stop()
			p:resolve()
		end
	end)
	return p
end

return GameUIShowDragonUpStarAnimation