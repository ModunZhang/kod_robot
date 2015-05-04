--
-- Author: Danny He
-- Date: 2015-02-25 11:49:26
--
local GameUISettingFaqDetail = UIKit:createUIClass("GameUISettingFaqDetail")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local window = import("..utils.window")
local WidgetPushButton = import("..widget.WidgetPushButton")
local UIListView = import(".UIListView")

function GameUISettingFaqDetail:ctor(data)
	GameUISettingFaqDetail.super.ctor(self)
	self.data = data
	self:BuildUI()
end

function GameUISettingFaqDetail:BuildUI()
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
		text = _("遇到问题"),
		size = 22,
		shadow = true,
		color = 0xffedae
	}):addTo(titleBar):align(display.CENTER,300,24)
	UIKit:ttfLabel({
		text = self.data.title,
		size = 20,
		color= 0x797154
	}):align(display.TOP_CENTER, 304,732):addTo(bg)
	local list_bg = UIKit:CreateBoxPanelWithBorder({width = 556,height = 648}):align(display.BOTTOM_CENTER, 304, 33):addTo(bg)
	self.list_view = UIListView.new{
        viewRect = cc.rect(10,10,536,628),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL,
    }:addTo(list_bg)
    self:RefreshListView()
end


function GameUISettingFaqDetail:RefreshListView()
	 local textLabel = UIKit:ttfLabel({
        dimensions = cc.size(536, 0),
        text = self.data.content,
        size = 22,
        color = 0x403c2f,
        align=cc.TEXT_ALIGNMENT_CENTER
    })
    local content = display.newNode()
    content:size(536,textLabel:getContentSize().height)
    textLabel:addTo(content):align(display.CENTER, 268, textLabel:getContentSize().height/2)
    self.list_view:removeAllItems()
    local item = self.list_view:newItem()
    item:addContent(content)
    item:setItemSize(536,content:getContentSize().height)
    self.list_view:addItem(item)
    self.list_view:reload()
end

return GameUISettingFaqDetail