--
-- Author: Kenny Dai
-- Date: 2015-01-17 10:46:42
--
local WidgetPopDialog = import(".WidgetPopDialog")
local WidgetProgress= import(".WidgetProgress")
local WidgetPushButton= import(".WidgetPushButton")
local WidgetAccelerateGroup = import(".WidgetAccelerateGroup")
local window = import("..utils.window")
local WidgetSpeedUp = class("WidgetSpeedUp", WidgetPopDialog)

function WidgetSpeedUp:ctor()
	WidgetSpeedUp.super.ctor(self,540,_("加速"),window.top-200)
	local body = self.body
	local size = body:getContentSize()
	self.upgrade_tip = UIKit:ttfLabel({
        size = 20,
        color = 0x403c2f
    }):align(display.LEFT_CENTER, 30,490)
        :addTo(body)
	--进度条
	self.progress = WidgetProgress.new(UIKit:hex2c3b(0xffedae), nil, nil, {
        icon_bg = "back_ground_43x43.png",
        icon = "hourglass_39x46.png",
        bar_pos = {x = 0,y = 0}
    }):addTo(body)
    :align(display.LEFT_CENTER, 40, 450)

    -- 免费加速按钮
    local  IMAGES  = {
        normal = "purple_btn_up_148x76.png",
        pressed = "purple_btn_down_148x76.png",
    }
    self.free_speedUp_btn = WidgetPushButton.new(IMAGES, {scale9 = false},
        {
            disabled = { name = "GRAY", params = {0.2, 0.3, 0.5, 0.1} }
        })
        :setButtonLabel(ui.newTTFLabel({
            text = _("免费加速"),
            size = 24,
            color = UIKit:hex2c3b(0xffedae)
        }))
       :align(display.CENTER, 510,468):addTo(body)
    -- 默认不可用
    self.free_speedUp_btn:setButtonEnabled(false)

    -- 大提示框
    self.tip_bg = display.newScale9Sprite("back_ground_166x84.png", size.width/2, 360,cc.size(546,90),cc.rect(15,10,136,64))
        :align(display.CENTER)
        :addTo(body)
    self.acc_tip_label = UIKit:ttfLabel({
        size = 20,
        dimensions = cc.size(530, 0),
        color = 0x403c2f
    }):align(display.LEFT_CENTER, 10,self.tip_bg:getContentSize().height/2)
        :addTo(self.tip_bg)
    self:SetAccTips(string.format(_("小于%dmin时可以使用免费加速"),User:GetVIPFreeSpeedUpTime()))

end

function WidgetSpeedUp:SetProgressInfo(time_label, percent)
	if math.floor(percent) ==100 then
		self:LeftButtonClicked()
		return
	end
    self.progress:SetProgressInfo(time_label, percent)
    return self
end
function WidgetSpeedUp:SetFreeButtonEnabled(enable)
    self.free_speedUp_btn:setButtonEnabled(enable)
	return self
end
function WidgetSpeedUp:OnFreeButtonClicked(func)
    self.free_speedUp_btn:onButtonClicked(function(event)
            if event.name == "CLICKED_EVENT" then
               func()
            end
        end)
	return self
end
function WidgetSpeedUp:SetAccTips(tip)
	self.acc_tip_label:setString(tip)
	return self
end
function WidgetSpeedUp:SetUpgradeTip(tip)
	self.upgrade_tip:setString(tip)
	return self
end
function WidgetSpeedUp:SetAccBtnsGroup(eventType,eventId)
    self.acc_buttons = WidgetAccelerateGroup.new(eventType,eventId):addTo(self.body):align(display.BOTTOM_CENTER,self.body:getContentSize().width/2,10)
	return self
end
return WidgetSpeedUp