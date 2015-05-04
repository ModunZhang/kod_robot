--
-- Author: Danny He
-- Date: 2015-02-24 08:49:25
--
local GameUISettingPush = UIKit:createUIClass("GameUISettingPush")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local window = import("..utils.window")
local UICheckBoxButton = import(".UICheckBoxButton")

local CHECKBOX_BUTTON_IMAGES = {
    off = "CheckBoxButtonOff_100x56.png",
    on = "CheckBoxButtonOn_100x56.png",
}

function GameUISettingPush:onEnter()
	GameUISettingPush.super.onEnter(self)
	self:BuildUI()
end

function GameUISettingPush:BuildUI()
	local shadowLayer = UIKit:shadowLayer():addTo(self)
	local bg = WidgetUIBackGround.new({height=762}):addTo(shadowLayer)
	bg:pos(((display.width - bg:getContentSize().width)/2),window.bottom_top)
	local titleBar = display.newSprite("title_blue_600x52.png"):align(display.LEFT_BOTTOM,3,747):addTo(bg)
	local closeButton = cc.ui.UIPushButton.new({normal = "X_1.png",pressed = "X_2.png"}, {scale9 = false})
	   	:addTo(titleBar)
	   	:align(display.BOTTOM_RIGHT,titleBar:getContentSize().width,0)
	   	:onButtonClicked(function ()
	   		self:LeftButtonClicked()
	   	end)
	UIKit:ttfLabel({
		text = _("推送通知"),
		size = 22,
		shadow = true,
		color = 0xffedae
	}):addTo(titleBar):align(display.CENTER,300,24)
 	local building_push_bg = UIKit:CreateBoxPanelWithBorder({width = 556,height = 96})
 		:align(display.CENTER_TOP,304,732)
 		:addTo(bg)
 	UIKit:ttfLabel({
 		text = _("建筑队列完成提醒"),
 		size = 20,
 		color= 0x797154
 	}):align(display.CENTER_LEFT,15,48):addTo(building_push_bg)
 	local building_push_button = UICheckBoxButton.new(CHECKBOX_BUTTON_IMAGES)
	    :setButtonLabelAlignment(display.CENTER)
    	:onButtonStateChanged(function(event)
            self:onButtonStateChanged(event.target)
    	end)
    	:align(display.RIGHT_CENTER, 540, 48)
    	:addTo(building_push_bg)
    	:setButtonSelected(app:GetPushManager():GetBuildPushState(),true)
    building_push_button:setTag(1)
    local soldier_push_bg = UIKit:CreateBoxPanelWithBorder({width = 556,height = 96})
 		:align(display.CENTER_TOP,304,624)
 		:addTo(bg)
 	UIKit:ttfLabel({
 		text = _("招募兵种完成提醒"),
 		size = 20,
 		color= 0x797154
 	}):align(display.CENTER_LEFT,15,48):addTo(soldier_push_bg)
 	local soldier_push_button = UICheckBoxButton.new(CHECKBOX_BUTTON_IMAGES)
	    :setButtonLabelAlignment(display.CENTER)
    	:onButtonStateChanged(function(event)
            self:onButtonStateChanged(event.target)
    	end)
    	:align(display.RIGHT_CENTER, 540, 48)
    	:addTo(soldier_push_bg)
    	:setButtonSelected(app:GetPushManager():GetSoldierPushState(),true)
    soldier_push_button:setTag(2)
    local technology_push_bg = UIKit:CreateBoxPanelWithBorder({width = 556,height = 96})
 		:align(display.CENTER_TOP,304,516)
 		:addTo(bg)
 	UIKit:ttfLabel({
 		text = _("科技研发完成提醒"),
 		size = 20,
 		color= 0x797154
 	}):align(display.CENTER_LEFT,15,48):addTo(technology_push_bg)
 	local technology_push_button = UICheckBoxButton.new(CHECKBOX_BUTTON_IMAGES)
	    :setButtonLabelAlignment(display.CENTER)
    	:onButtonStateChanged(function(event)
            self:onButtonStateChanged(event.target)
    	end)
    	:align(display.RIGHT_CENTER, 540, 48)
    	:addTo(technology_push_bg)
    	:setButtonSelected(app:GetPushManager():GetTechnologyPushState(),true)
    technology_push_button:setTag(3)
end
function GameUISettingPush:onButtonStateChanged(button)
    local tag = button:getTag()
    local isOn = button:isButtonSelected()
    if tag == 1 then
        app:GetPushManager():SwitchBuildPush(isOn)
    elseif tag == 2 then
        app:GetPushManager():SwitchSoldierPush(isOn)
    elseif tag == 3 then
        app:GetPushManager():SwitchTechnologyPush(isOn)
    end
end

return GameUISettingPush