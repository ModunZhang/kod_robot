--
-- Author: Danny He
-- Date: 2015-02-10 14:30:55
--
--
local GameUITips = UIKit:createUIClass("GameUITips")
local UILib = import(".UILib")
local UIListView = import(".UIListView")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local window = import("..utils.window")
local WidgetPushButton = import("..widget.WidgetPushButton")

function GameUITips:ctor(active_button,callback)
	GameUITips.super.ctor(self)
	self.show_never_again = true
	self.never_show_again = app:GetGameDefautlt():getBasicInfoValueForKey("NEVER_SHOW_TIP_ICON")
	self.active_button = active_button
	self.callback = callback
end


function GameUITips:onEnter()
	GameUITips.super.onEnter(self)
	self:BuildUI()
end


function GameUITips:BuildUI()
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
		text = _("帮助"),
		size = 22,
		shadow = true,
		color = 0xffedae
	}):addTo(titleBar):align(display.CENTER,300,24)
	local list_bg = display.newScale9Sprite("box_bg_546x214.png"):size(568,636):addTo(bg):align(display.TOP_CENTER, 304, 732)
	self.info_list = UIListView.new({
        viewRect = cc.rect(11,10, 546, 616),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(list_bg)
	WidgetPushButton.new({normal = 'yellow_btn_up_185x65.png',pressed = 'yellow_btn_down_185x65.png'})
		:setButtonLabel('normal', UIKit:commonButtonLable({
			text = _("我知道了!")
		}))
		:addTo(bg):pos(500,50)
		:onButtonClicked(function()
			self:LeftButtonClicked()
		end)
	local checkbox_image = {
	        off = "checkbox_unselected.png",
	        off_pressed = "checkbox_unselected.png",
	        off_disabled = "checkbox_unselected.png",
	        on = "checkbox_selectd.png",
	        on_pressed = "checkbox_selectd.png",
	        on_disabled = "checkbox_selectd.png",

	}
	if self.show_never_again then
		local button = WidgetPushButton.new({normal = 'activity_check_bg_55x51.png'})
			:addTo(bg)
			:align(display.LEFT_BOTTOM,15, 25)
		local check_state = display.newSprite("activity_check_body_55x51.png"):addTo(button):pos(27,25)
		check_state:setVisible(self.never_show_again)
		button.check_state = check_state
		button:onButtonClicked(function()
			self.never_show_again = not self.never_show_again
			app:GetGameDefautlt():setBasicInfoBoolValueForKey("NEVER_SHOW_TIP_ICON",self.never_show_again)
			app:GetGameDefautlt():flush()
			button.check_state:setVisible(self.never_show_again)
			self.callback()
		end)
		UIKit:ttfLabel({text = _("不再显示"),size = 22,color = 0x514d3e}):align(display.LEFT_CENTER, 80, 50):addTo(bg)
	end
	self:RefreshListView()
end

function GameUITips:Tips()
	local tips = {
		{title = _("1.建造住宅"),image = 'dwelling_2.png',text = _("建造和升级住宅能提升城民数量，生产资源的小屋需要占用城民"),scale = 0.8},
		{title = _("2.获取资源"),image = 'quarrier_1.png',text = _("建造和升级木工小屋，石匠小屋，旷工小屋，农夫小屋获得更多资源"),scale = 0.9},
		{title = _("3.升级主城堡"),image = 'keep_1.png',text = _("升级城堡能够提升建筑的等级上限，解锁更多的地块和新的建筑"),scale = 0.25},
		{title = _("4.招募部队"),image = 'barracks.png',text = _("在兵营招募部队，招募出的部队会持续消耗粮食，请务必保证自己的粮食产量充足"),scale = 0.45},
		{title = _("5.飞艇探索"),image = 'airship.png',text = _("使用飞艇，带领部队探索外域，获得资源还能增长巨龙等级，提升带兵总量"),scale = 0.35},
		{title = _("6.加入联盟"),image = UILib.alliance_building.palace,text = _("解锁联盟领地，参加联盟会战，并解锁更多新奇的玩法"),scale = 0.65},
	}
	return tips
end

function GameUITips:RefreshListView()
	local data = self:Tips()
	for index,v in ipairs(data) do
		local item = self:GetItem(index,v.image,v.title,v.text,v.scale)
		self.info_list:addItem(item)
	end
	self.info_list:reload()
end

function GameUITips:GetItem(index,image,title,text,scale)
	local item = self.info_list:newItem()
	local content = display.newScale9Sprite(string.format("resource_item_bg%d.png",index % 2)):size(548,122)
	local image = display.newSprite(image):align(display.LEFT_CENTER, 10, 61):addTo(content):scale(scale)
	local title_label = UIKit:ttfLabel({
		text = title,
		color= 0x514d3e,
		size = 22
	}):align(display.LEFT_TOP,130,115):addTo(content)
	UIKit:ttfLabel({
		text = text,
		color= 0x615b44,
		size = 20,
		dimensions = cc.size(410, 65)
	}):align(display.LEFT_TOP,130,title_label:getPositionY() - 30):addTo(content)

	item:addContent(content)
	item:setItemSize(548,122)
	return item
end

function GameUITips:LeftButtonClicked()
	if self.active_button then
		self.active_button:setVisible(not app:GetGameDefautlt():getBasicInfoValueForKey("NEVER_SHOW_TIP_ICON"))
		print(tolua.type(self.active_button),"self.active_button---->")
	end
	GameUITips.super.LeftButtonClicked(self)
end

return GameUITips