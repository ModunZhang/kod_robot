--
-- Author: Danny He
-- Date: 2015-05-18 09:11:42
--
local WidgetPopDialog = import("..widget.WidgetPopDialog")
local GameUIAllianceJoinTips = class("GameUIAllianceJoinTips",WidgetPopDialog)
local window = import("..utils.window")
local UIListView = import(".UIListView")
local UIScrollView = import(".UIScrollView")
local WidgetPushButton = import("..widget.WidgetPushButton")


function GameUIAllianceJoinTips:ctor()
	GameUIAllianceJoinTips.super.ctor(self,724,_("加入联盟"),display.top-100)
end

function GameUIAllianceJoinTips:onEnter()
	GameUIAllianceJoinTips.super.onEnter(self)
	local bg = display.newSprite("join_alliance_tips_bg_572x536.png"):align(display.BOTTOM_CENTER, 304,112):addTo(self:GetBody())
	local green_title = display.newSprite("green_title_639x69.png"):addTo(self:GetBody()):align(display.TOP_CENTER,304,700)
	UIKit:ttfLabel({text = _("联盟强大功能!"),size = 24,color = 0xffedae,shadow = true }):align(display.CENTER,319, 40):addTo(green_title)
	local list_bg = display.newSprite("join_tips_list_bg_572x338.png"):align(display.LEFT_BOTTOM, 0, 0):addTo(bg)
	local list_view = UIListView.new({
		bgColor = cc.c3b(255,0,0),
        viewRect = cc.rect(0, 0, 572, 338),
        direction = UIScrollView.DIRECTION_VERTICAL
	}):addTo(list_bg)
	self.list_view = list_view
	WidgetPushButton.new({normal = "yellow_btn_up_186x66.png",pressed = "yellow_btn_down_186x66.png"})
		:align(display.BOTTOM_CENTER, 304, 25)
		:addTo(self:GetBody())
		:setButtonLabel("normal", UIKit:commonButtonLable({
			text = _("明白")
		}))
		:onButtonClicked(function()
			self:LeftButtonClicked()
		end)
	self:RefreshListView()
end

function GameUIAllianceJoinTips:RefreshListView()
	self.list_view:removeAllItems()
	for __,v in ipairs(self:GetTipsData()) do
		local item = self:GetItem(v)
		self.list_view:addItem(item)
	end
	self.list_view:reload()
end

function GameUIAllianceJoinTips:GetItem(str)  -- 48
	local item = self.list_view:newItem()
	local content = display.newNode():size(572,42)
	item:addContent(content)
	local star = display.newSprite("alliance_star_23x23.png"):addTo(content):align(display.LEFT_CENTER, 14, 21)
	UIKit:ttfLabel({
		text = str,
		size = 20,
		color= 0xffedae
	}):align(display.LEFT_CENTER, 50, 21):addTo(content)
	item:setItemSize(572, 42)
	return item
end

function GameUIAllianceJoinTips:GetTipsData()
	 local tips = {
	 	_("将城市迁入联盟领地，受到联盟保护"),
	 	_("从联盟盟友获得免费的加速"),
	 	_("在联盟领地的村落采集丰富的资源"),
	 	_("购买联盟商店的专属道具"),
	 	_("解锁特殊的联盟GvE任务"),
	 	_("解锁刺激的联盟GvG对战"),
	 	_("免费获得联盟成员赠送的礼物"),
	 	_("以及更多强大联盟功能..."),
	 }
	 return tips
end

return GameUIAllianceJoinTips