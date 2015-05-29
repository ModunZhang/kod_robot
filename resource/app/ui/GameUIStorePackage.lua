--
-- Author: Danny He
-- Date: 2015-03-25 16:55:31
--
local WidgetPopDialog = import("..widget.WidgetPopDialog")
local GameUIStorePackage = class("GameUIStorePackage",WidgetPopDialog)
local WidgetPushButton = import("..widget.WidgetPushButton")
local UIListView = import(".UIListView")
local Localize = import("..utils.Localize")
local UILib = import(".UILib")
local Localize_item = import("..utils.Localize_item")

function GameUIStorePackage:ctor(data)
	GameUIStorePackage.super.ctor(self,756,_("礼包详情"),display.top-100)
	self.data = data
end

function GameUIStorePackage:GetData()
	return self.data
end

function GameUIStorePackage:onEnter()
	GameUIStorePackage.super.onEnter(self)
	self:CreateUI()
end

function GameUIStorePackage:CreateUI()
	self:CreateBuyButton()
	self:CreateListView()
	self:CreateItemLogo()
end

function GameUIStorePackage:CreateItemLogo()
	local data = self:GetData()
	local content = display.newSprite(data.config.small_content)
		:align(display.CENTER_BOTTOM, 304, 538)
		:addTo(self:GetBody())
	UIKit:ttfLabel({
		text = data.name,
		color= 0xfed36c,
		size = 24,
		align = cc.TEXT_ALIGNMENT_CENTER,
	}):align(display.CENTER_TOP, 294, 182):addTo(content)
	local clip_rect = display.newClippingRegionNode(cc.rect(0,0,549,138)):addTo(content)
	local logo = display.newSprite(data.config.logo)
	local logo_box = display.newSprite("store_logo_box_592x141.png",296,69):addTo(logo):zorder(5)
	local bg = display.newScale9Sprite(data.config.desc):size(335,92)
	bg:align(display.RIGHT_CENTER, 592, 69):addTo(logo)
	local gem_box = display.newSprite("store_gem_box_260x116.png"):align(display.CENTER, 0, 46):addTo(bg)
	display.newSprite("store_gem_260x116.png", 130, 58):addTo(gem_box)
	UIKit:ttfLabel({
		text = data.gem,
		size = 30,
		color= 0xffd200,
	}):align(display.TOP_CENTER, 167, 92):addTo(bg)
	UIKit:ttfLabel({
		text = _("礼包中包含下列所有物品"),
		size = 16,
		color= 0xfed36c
	}):align(display.BOTTOM_CENTER, 167,6):addTo(bg)
	UIKit:ttfLabel({
		text = string.format(_("+价值%d的道具"),data.rewards_price),
		size = 20,
		color= 0xffd200
	}):align(display.CENTER, 167,44):addTo(bg)
	logo:align(display.LEFT_BOTTOM,0,2):addTo(clip_rect)
end

function GameUIStorePackage:CreateListView()
	local list_bg = display.newScale9Sprite("background_568x120.png", 0,0,cc.size(546,402),cc.rect(15,10,538,100))
		:addTo(self:GetBody())
		:align(display.BOTTOM_CENTER, 304, 118)
	self.info_list = UIListView.new({
        viewRect = cc.rect(11,10, 524, 382),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(list_bg)
	self:RefreshListView()
end

function GameUIStorePackage:RefreshListView()
	self.info_list:removeAllItems()
	local rewards = self:GetData().rewards
	for index,v in ipairs(rewards) do
		local item = self:GetItem(index,v)
		self.info_list:addItem(item)
	end
	self.info_list:reload()
end

function GameUIStorePackage:GetItem(index,reward)
	local item = self.info_list:newItem()
	local content = display.newScale9Sprite(string.format("back_ground_548x40_%d.png", index % 2 == 0 and 1 or 2)):size(524,48)
	local bg = display.newSprite("box_118x118.png"):align(display.LEFT_CENTER, 14, 24):addTo(content)
	local icon = display.newSprite(UILib.item[reward.key]):align(display.CENTER, 59, 58):addTo(bg)
	icon:scale(100/math.max(icon:getContentSize().width,icon:getContentSize().height))
	bg:scale(0.3)
	-- local icon = display.newSprite(UILib.item[reward.key]):align(display.LEFT_CENTER, 14, 24):addTo(content)
	-- icon:scale(36/math.max(icon:getContentSize().width,icon:getContentSize().height))
	local item_name = ""
	if reward.isToAlliance then
		item_name = string.format(_("赠送给联盟成员的%s"),Localize_item.item_name[reward.key])
	else
		item_name = Localize_item.item_name[reward.key]
	end
	UIKit:ttfLabel({
		text = item_name,
		size = 22,
		color= 0x403c2f
	}):align(display.LEFT_CENTER, 62, 24):addTo(content)

	UIKit:ttfLabel({
		text = "x " .. reward.count,
		size = 22,
		color= 0x403c2f,
		align = cc.TEXT_ALIGNMENT_RIGHT,
	}):align(display.RIGHT_CENTER, 507, 24):addTo(content)
	item:addContent(content)
	item:setItemSize(524, 48)
	return item
end

function GameUIStorePackage:CreateBuyButton()
	local button = WidgetPushButton.new({
		normal = "store_buy_button_n_332x76.png",
		pressed= "store_buy_button_l_332x76.png"
	})
	local icon = display.newSprite("store_buy_icon_332x76.png"):addTo(button)
	local label = UIKit:ttfLabel({
		text = _("购买"),
		size = 24,
		color= 0xfff3c7,
		shadow= true,
	})
	button:setButtonLabel("normal", label)
	button:setButtonLabelOffset(0, 20)
	UIKit:ttfLabel({
		text = "$" .. self:GetData().price,
		size =  24,
		color= 0xffd200
	}):addTo(icon):align(display.CENTER_BOTTOM, 166, 10)
	button:addTo(self:GetBody()):pos(304,64)
	button:onButtonClicked(function()
		self:OnBuyButtonClicked()
	end)
end

function GameUIStorePackage:OnBuyButtonClicked()
	app:getStore().purchaseWithProductId(self:GetData().productId,1)
	device.showActivityIndicator()
end

return GameUIStorePackage