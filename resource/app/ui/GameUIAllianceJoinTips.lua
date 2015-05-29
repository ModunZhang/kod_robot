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
local Alliance_Manager = Alliance_Manager
local User = User
local Localize_item = import("..utils.Localize_item")

function GameUIAllianceJoinTips:ctor()
	GameUIAllianceJoinTips.super.ctor(self,724,_("加入联盟"),display.top-100)
	self.alliance = Alliance_Manager:GetMyAlliance()
end

function GameUIAllianceJoinTips:onEnter()
	GameUIAllianceJoinTips.super.onEnter(self)
	local bg = display.newSprite("join_alliance_tips_bg_572x536.jpg"):align(display.BOTTOM_CENTER, 304,112):addTo(self:GetBody())
	local green_title = display.newSprite("green_title_639x69.png"):addTo(self:GetBody()):align(display.TOP_CENTER,304,700)
	UIKit:ttfLabel({text = _("联盟强大功能!"),size = 24,color = 0xffedae,shadow = true }):align(display.CENTER,319, 40):addTo(green_title)
	local list_bg = display.newSprite("join_tips_list_bg_572x313.png"):align(display.LEFT_BOTTOM, 0, 0):addTo(bg)
	local tips_bg = display.newSprite("alliance_join_tips_title_571x66.png"):align(display.TOP_CENTER,286, 313):addTo(list_bg)
	display.newSprite("gem_icon_62x61.png"):align(display.LEFT_CENTER, 2, 33):addTo(tips_bg)
	local label_1 = UIKit:ttfLabel({
		text = _("立即加入联盟送金龙币"),
		size = 28,
		color= 0xffd200,
		shadow= true
	}):align(display.LEFT_CENTER,60, 33):addTo(tips_bg)

	UIKit:ttfLabel({
		text = "200",
		size = 40,
		color= 0xffd200,
		shadow= true
	}):align(display.LEFT_CENTER,60 + label_1:getContentSize().width + 24, 33):addTo(tips_bg)
	local list_view = UIListView.new({
		bgColor = cc.c3b(255,0,0),
        viewRect = cc.rect(0, 0, 572, 250),
        direction = UIScrollView.DIRECTION_VERTICAL
	}):addTo(list_bg)
	self.list_view = list_view
	self.get_reward_button = WidgetPushButton.new({normal = "yellow_btn_up_186x66.png",pressed = "yellow_btn_down_186x66.png"})
		:align(display.BOTTOM_CENTER, 304, 25)
		:addTo(self:GetBody())
		:setButtonLabel("normal", UIKit:commonButtonLable({
			text = _("领取")
		}))
		:onButtonClicked(function()
			self:OnGetRewardButtonClicked()
		end)
	self.create_alliance_button = WidgetPushButton.new({normal = "yellow_btn_up_186x66.png",pressed = "yellow_btn_down_186x66.png"})
		:align(display.BOTTOM_LEFT, 14, 25)
		:addTo(self:GetBody())
		:setButtonLabel("normal", UIKit:commonButtonLable({
			text = _("创建联盟")
		}))
		:onButtonClicked(function()
			self:LeftButtonClicked()
			UIKit:newGameUI("GameUIAlliance","create"):AddToCurrentScene(true)
		end)
	self.join_alliance_button = WidgetPushButton.new({normal = "yellow_btn_up_186x66.png",pressed = "yellow_btn_down_186x66.png"})
		:align(display.BOTTOM_RIGHT, 588, 25)
		:addTo(self:GetBody())
		:setButtonLabel("normal", UIKit:commonButtonLable({
			text = _("加入联盟")
		}))
		:onButtonClicked(function()
			self:LeftButtonClicked()
			UIKit:newGameUI("GameUIAlliance","join"):AddToCurrentScene(true)
		end)
	self:RefreshUI()
	self:RefreshListView()
	User:AddListenOnType(self, User.LISTEN_TYPE.COUNT_INFO)
end

function GameUIAllianceJoinTips:RefreshUI()
	if self.alliance:IsDefault() then
		self.create_alliance_button:setVisible(true)
		self.join_alliance_button:setVisible(true)
		self.get_reward_button:setVisible(false)
	else
		self.get_reward_button:setVisible(true)
		self.create_alliance_button:setVisible(false)
		self.join_alliance_button:setVisible(false)

		if User:GetCountInfo().firstJoinAllianceRewardGeted then
			self.get_reward_button:setButtonEnabled(false)
		else
			self.get_reward_button:setButtonEnabled(true)
		end
	end
end


function GameUIAllianceJoinTips:OnCountInfoChanged()
	local countInfo = User:GetCountInfo()
	if countInfo.firstJoinAllianceRewardGeted then
		self:LeftButtonClicked()
	end
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
	local content = display.newNode():size(572,50)
	item:addContent(content)
	local star = display.newSprite("star_23X23.png"):addTo(content):align(display.LEFT_CENTER, 14, 25)
	UIKit:ttfLabel({
		text = str,
		size = 20,
		color= 0xffedae
	}):align(display.LEFT_CENTER, 50, 25):addTo(content)
	item:setItemSize(572, 50)
	return item
end

function GameUIAllianceJoinTips:GetTipsData()
	 local tips = {
	 	_("将城市迁入联盟领地，受到联盟保护"),
	 	_("从联盟盟友获得免费加速及礼物"),
	 	_("购买联盟商店的专属道具"),
	 	_("解锁特殊的联盟GvE任务"),
	 	_("解锁刺激的联盟GvG对战"),
	 }
	 return tips
end

function GameUIAllianceJoinTips:OnGetRewardButtonClicked()
	NetManager:getFirstJoinAllianceRewardPromise():done(function()
		GameGlobalUI:showTips(_("提示"),string.format(_("获得%s"),string.format("%s x%d",Localize_item.item_name['gemClass_2'],2)))
	end)
end

function GameUIAllianceJoinTips:onCleanup()
	User:RemoveListenerOnType(self, User.LISTEN_TYPE.COUNT_INFO)
	GameUIAllianceJoinTips.super.onCleanup(self)
end

return GameUIAllianceJoinTips
