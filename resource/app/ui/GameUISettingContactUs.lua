--
-- Author: Danny He
-- Date: 2015-02-25 09:14:44
--
local GameUISettingContactUs = UIKit:createUIClass("GameUISettingContactUs")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local window = import("..utils.window")
local UIListView = import(".UIListView")
local WidgetPushButton = import("..widget.WidgetPushButton")

function GameUISettingContactUs:onEnter()
	GameUISettingContactUs.super.onEnter(self)
	self:BuildUI()
end

function GameUISettingContactUs:BuildUI()
	local shadowLayer = UIKit:shadowLayer():addTo(self)
	local bg = WidgetUIBackGround.new({height=762}):addTo(shadowLayer)
	bg:pos(((display.width - bg:getContentSize().width)/2),window.bottom_top)
	local titleBar = display.newSprite("title_blue_600x56.png"):align(display.LEFT_BOTTOM,3,747):addTo(bg)
	local closeButton = cc.ui.UIPushButton.new({normal = "X_1.png",pressed = "X_2.png"}, {scale9 = false})
	   	:addTo(titleBar)
	   	:align(display.BOTTOM_RIGHT,titleBar:getContentSize().width,0)
	   	:onButtonClicked(function ()
	   		self:LeftButtonClicked()
	   	end)
	UIKit:ttfLabel({
		text = _("联系我们"),
		size = 22,
		shadow = true,
		color = 0xffedae
	}):addTo(titleBar):align(display.CENTER,300,28)
	UIKit:ttfLabel({
		text = _("你将使用你的邮箱向我们发送一份邮件"),
		size = 20,
		color= 0x615b44
	}):align(display.CENTER_TOP,304, 735):addTo(bg)
	self.list_view = UIListView.new{
        viewRect = cc.rect(26,50,556,650),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL,
    }:addTo(bg)
    self:RefreshListView()
end

function GameUISettingContactUs:RefreshListView()
	self.list_view:removeAllItems()
	local data = self:GetData()
	for __,v in ipairs(data) do
		local item = self:GetItem(v.title,v.subtitle,v.mail)
		self.list_view:addItem(item)
	end
	self.list_view:reload()
end
function GameUISettingContactUs:GetData()
	local data = {
		{title = _("支付遇到了问题"),mail = 'support@batcatstudio.com'},
		{title = _("游戏老是报错"),mail = 'support@batcatstudio.com'},
		{title = _("致命性Bug上报"),mail = 'support@batcatstudio.com',subtitle = _("查实后我们将提供奖励")},
		{title = _("其他问题"),mail = 'support@batcatstudio.com'},
	}
	return data
end

function GameUISettingContactUs:GetItem(title,subtitle,mail)
	local item = self.list_view:newItem()
	local content = UIKit:CreateBoxPanelWithBorder({width = 556,height = 96})
	if subtitle then
		UIKit:ttfLabel({
			text = title,
			size = 22,
			color= 0x403c2f
		}):addTo(content):align(display.LEFT_BOTTOM, 18, 44)
		UIKit:ttfLabel({
			text = subtitle,
			size = 20,
			color= 0x318200
		}):addTo(content):align(display.LEFT_BOTTOM, 18, 14)
	else
		UIKit:ttfLabel({
			text = title,
			size = 22,
			color= 0x403c2f
		}):addTo(content):align(display.LEFT_CENTER, 18, 48)
	end
	WidgetPushButton.new({normal = 'yellow_btn_up_148x58.png',pressed = 'yellow_btn_down_148x58.png'})
		:addTo(content)
		:pos(462,48)
		:setButtonLabel("normal", UIKit:commonButtonLable({
			text = _("写邮件"),
		}))
		:onButtonClicked(function()
			--TODO:确认邮件格式后调整
			local subject,body = app:getSupportMailFormat(title)
			local canSendMail = ext.sysmail.sendMail(mail,subject,body,function()end)
			if not canSendMail then
				UIKit:showMessageDialog(_("错误"),_("您尚未设置邮件：请前往IOS系统“设置”-“邮件、通讯录、日历”-“添加账户”处设置"),function()end)
			end
		end)
	item:addContent(content)
	item:setMargin({left = 0, right = 0, top = 0, bottom = 8})
	item:setItemSize(556, 96, false)
	return item
end

return GameUISettingContactUs
