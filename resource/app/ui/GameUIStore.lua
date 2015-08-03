--
-- Author: Danny He
-- Date: 2015-03-24 16:04:35
--
local GameUIStore = UIKit:createUIClass("GameUIStore", "GameUIWithCommonHeader")
local UIListView = import(".UIListView")
local window = import("..utils.window")
local config_store = GameDatas.StoreItems.items
local WidgetPushButton = import("..widget.WidgetPushButton")
local Localize = import("..utils.Localize")
local UILib = import(".UILib")
local Localize_item = import("..utils.Localize_item")
local light_gem = import("..particles.light_gem")


function GameUIStore:ctor()
	GameUIStore.super.ctor(self,City,_("获得金龙币"))
end

function GameUIStore:OnMoveInStage()
	GameUIStore.super.OnMoveInStage(self)
	self:CreateUI()
end

function GameUIStore:onEnter()
	GameUIStore.super.onEnter(self)
	local layer = display.newColorLayer(cc.c4b(13,17,19,255))
	layer:addTo(self:GetView()):size(614,window.betweenHeaderAndTab + 90)
	layer:pos(window.left+math.ceil((window.width - 614)/2), window.bottom + 14)
	self.content_layer = layer
end

function GameUIStore:CreateUI()
	self.listView = UIListView.new({
        viewRect = cc.rect(0,0, 614,window.betweenHeaderAndTab + 90),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(self.content_layer)
	self:RefreshListView()
end

function GameUIStore:GetStoreData()
	local data = {}
	for __,v in ipairs(config_store) do
		local temp_data = {}
		temp_data['productId'] = v.productId
		temp_data['price'] = string.format("%.2f",v.price)
		temp_data['gem'] = v.gem
		temp_data['name'] = Localize.iap_package_name[v.productId]
		temp_data['order'] = v.order
		local rewards,rewards_price = self:FormatGemRewards(v.rewards,v.allianceRewards)
		temp_data['rewards'] = rewards
		temp_data['rewards_price'] = rewards_price
		temp_data['config'] = UILib.iap_package_image[v.name]
		table.insert(data,temp_data)
	end
	return data
end

function GameUIStore:FormatGemRewards(rewards,allianceRewards)
	local result_rewards = {}
	local rewards_price = {}
	local all_rewards = string.split(rewards, ",")
	if allianceRewards then
		local all_alliance_rewards = string.split(allianceRewards,",")
		for __,v in ipairs(all_alliance_rewards) do
			local one_reward = string.split(v,":")
			local category,key,count = unpack(one_reward)
			table.insert(result_rewards,{category = category,key = key,count = count,isToAlliance = true})
		end
	end
	for __,v in ipairs(all_rewards) do
		local one_reward = string.split(v,":")
		local category,key,count = unpack(one_reward)
		table.insert(result_rewards,{category = category,key = key,count = count})
		rewards_price[key] = count
	end
	return result_rewards,DataUtils:getItemsPrice(rewards_price)
end

function GameUIStore:RefreshListView()
	self.listView:removeAllItems()
	local data = self:GetStoreData()
	for __,v in ipairs(data) do
		local item = self:GetItem(v)
		self.listView:addItem(item)
	end
	self.listView:reload()
end

function GameUIStore:GetItem(data)
	local item = self.listView:newItem()
	local content = display.newSprite(data.config.content)
	UIKit:ttfLabel({
		text = data.name,
		color= 0xfed36c,
		size = 24
	}):align(display.CENTER_TOP, 305, 494):addTo(content)
	local logo = self:GetItemLogo(data):align(display.CENTER_TOP, 305, 450):addTo(content)
	self:GetItemBuyButton(data):addTo(content):pos(305,72)
	self:GetItemMoreButton(data):addTo(content):pos(305,142)
	self:AddRewardsForItem(content,data)
	item:addContent(content)
	item:setItemSize(610, 514)
	return item
end

function GameUIStore:GetItemLogo(data)
	local logo = display.newSprite(data.config.logo)
	-- 金龙币上的粒子特效
	light_gem():addTo(logo, 1022):pos(data.config.light_position.x , data.config.light_position.y):scale(1.2)
	local logo_box = display.newSprite("store_logo_box_592x141.png",296,69):addTo(logo):zorder(5)
	local bg = display.newSprite(data.config.desc)
	if data.config.npc then
		bg:align(display.RIGHT_CENTER, 530, 69):addTo(logo)
		display.newSprite(data.config.npc):align(display.RIGHT_BOTTOM, 592, 0):addTo(logo)
	else
		bg:align(display.RIGHT_CENTER, 592, 69):addTo(logo)
	end
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
	print("............".._("+价值%d的道具"), _("礼包中包含下列所有物品"))
	UIKit:ttfLabel({
		text = string.format(_("+价值%d的道具"),data.rewards_price),
		size = 20,
		color= 0xffd200
	}):align(display.CENTER, 167,44):addTo(bg)
	return logo
end

function GameUIStore:GetItemBuyButton(data)
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
	button:onButtonClicked(function()
		self:OnBuyButtonClicked(data.productId)
	end)
	button:setButtonLabel("normal", label)
	button:setButtonLabelOffset(0, 20)
	UIKit:ttfLabel({
		text = "$" .. data.price,
		size =  24,
		color= 0xffd200
	}):addTo(icon):align(display.CENTER_BOTTOM, 166, 10)
	return button
end

function GameUIStore:OnBuyButtonClicked(productId)
	device.showActivityIndicator()
	app:getStore().purchaseWithProductId(productId,1)
end

function GameUIStore:GetItemMoreButton(data)
	local button = WidgetPushButton.new({normal = data.config.more.normal,pressed = data.config.more.pressed})
	button:setButtonLabel("normal",UIKit:commonButtonLable({
		text = _("更多")
	})):onButtonClicked(function()
		UIKit:newGameUI("GameUIStorePackage",data):AddToCurrentScene(true)
	end)
	return button
end

function GameUIStore:AddRewardsForItem(content,data)
	local rewards = data.rewards
	local x_1,x_2,x_3,y = 24,66,586,285
	for i=1,3 do
		local reward = rewards[i]
		if reward then
			local bg = display.newSprite("box_118x118.png"):align(display.LEFT_CENTER, x_1, y):addTo(content)
			local icon = display.newSprite(UILib.item[reward.key]):align(display.CENTER, 59, 59):addTo(bg)
			icon:scale(100/math.max(icon:getContentSize().width,icon:getContentSize().height))
			bg:scale(0.3)
			UIKit:ttfLabel({
				text = reward.isToAlliance and
                string.format(_("赠送给联盟成员的%s"),Localize_item.item_name[reward.key]) or
                Localize_item.item_name[reward.key],
				size = 20,
				color= 0xffedae
			}):align(display.LEFT_CENTER, x_2, y):addTo(content)
			UIKit:ttfLabel({
				text = "x " .. reward.count,
				size = 20,
				color= 0xffedae,
				align = cc.TEXT_ALIGNMENT_RIGHT,
			}):align(display.RIGHT_CENTER, x_3, y):addTo(content)
			y = y - 50
		end
	end
end

function GameUIStore:CreateShopButton(on_clicked)
    local gem_button = cc.ui.UIImage.new("gem_btn_up.png"):align(display.RIGHT_TOP, 670, 86)
    local gem_icon = cc.ui.UIImage.new("gem_icon_62x61.png")
        :addTo(gem_button)
        :pos(106,0)

    light_gem():addTo(gem_icon, 1022):pos(62/2, 61/2)

    local gem_label = UIKit:ttfLabel({
        text = ""..string.formatnumberthousands(City:GetUser():GetGemResource():GetValue()),
        size = 20,
        color = 0xffd200,
        shadow = true
    }):addTo(gem_button):align(display.CENTER,64,32)

    return gem_button,gem_label
end

return GameUIStore