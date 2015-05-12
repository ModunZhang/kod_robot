--
-- Author: Danny He
-- Date: 2014-11-12 10:02:15
--
local WidgetPopDialog = import("..widget.WidgetPopDialog")
local GameUIAllianceShrineRewardList =class("GameUIAllianceShrineRewardList",WidgetPopDialog)
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local window = import("..utils.window")
local UIListView = import(".UIListView")
local Alliance_Manager = Alliance_Manager
local UILib = import(".UILib")
local WidgetPushButton = import("..widget.WidgetPushButton")
local Localize = import("..utils.Localize")

function GameUIAllianceShrineRewardList:ctor(shrineStage)
	GameUIAllianceShrineRewardList.super.ctor(self,464,_("事件完成奖励"),window.top - 101)
	self.shrineStage_ = shrineStage
end

function GameUIAllianceShrineRewardList:onEnter()
	GameUIAllianceShrineRewardList.super.onEnter(self)
	self:BuildUI()
end

function GameUIAllianceShrineRewardList:BuildUI()
	local background = self:GetBody()
	local list,list_node = UIKit:commonListView_1({
		viewRect = cc.rect(0, 0,547, 282),
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL,
	})
	self.rewards_listView = list
	list_node:addTo(background):align(display.CENTER_BOTTOM, background:getContentSize().width/2, 118)
	WidgetPushButton.new({
		normal = "yellow_btn_up_185x65.png",
		pressed = "yellow_btn_down_185x65.png"
	}):align(display.CENTER_BOTTOM,background:getContentSize().width/2,30):addTo(background)
	:setButtonLabel("normal",UIKit:commonButtonLable({
		text = _("确定")
	}))
	:onButtonClicked(function()
		self:LeftButtonClicked()
	end)
	self:RefreshRewardListView()
end

function GameUIAllianceShrineRewardList:GetListItem(index,data) 
	local item = self.rewards_listView:newItem()
	local content = display.newScale9Sprite(string.format("resource_item_bg%d.png",index % 2)):size(547,94)
	
	
	local iconImage = "goldKill_icon_76x84.png"
	if index == 1 then
		iconImage = "goldKill_icon_76x84.png"
	elseif index == 2 then
		iconImage = "silverKill_icon_76x84.png"
	elseif index == 3 then
		iconImage = "bronzeKill_icon_76x84.png"
	end
	local icon = display.newSprite(iconImage):align(display.LEFT_CENTER,6,47):addTo(content)
	local strength_icon = display.newSprite("battle_33x33.png")
		:align(display.LEFT_BOTTOM,82,12)
		:addTo(content)
	UIKit:ttfLabel({
		text = data[2],
		size = 22,
		color = 0x403c2f
	}):addTo(content):align(display.LEFT_BOTTOM,120,12)
	local label = UIKit:ttfLabel({
		text = data[1],
		size = 22,
		color = 0x403c2f,
	}):addTo(content):align(display.LEFT_TOP,82,82)
	local x,y = 290,22

	for i,v in ipairs(data[3]) do
		local item = display.newScale9Sprite("box_118x118.png"):scale(0.59)
			:align(display.LEFT_BOTTOM,x,y)
			:addTo(content)
			if v.type == 'dragonMaterials' then
				local sp = display.newSprite(UILib.dragon_material_pic_map[v.sub_type]):align(display.CENTER,59,59)
				local size = sp:getContentSize()
				sp:scale(100/math.max(size.width,size.height)):addTo(item)
				UIKit:addTipsToNode(item,Localize.equip_material[v.sub_type],self)
			elseif v.type == 'allianceInfo' then
				if v.sub_type == 'loyalty' then
					local sp = display.newSprite("loyalty_128x128.png"):align(display.CENTER,59,59)
					sp:scale(0.78):addTo(item)
				end
				UIKit:addTipsToNode(item,_("忠诚值"),self)
			end
		UIKit:ttfLabel({
			text = "x" .. v.count,
			size = 18,
			color = 0x403c2f
		}):addTo(content):align(display.BOTTOM_CENTER,x + 35,1)
		x = x + 70 + 20
	end
	item:addContent(content)
	item:setItemSize(547,94)
	return item
end

function GameUIAllianceShrineRewardList:GetListData()
	local terrain = Alliance_Manager:GetMyAlliance():Terrain()
	local data = {}
	data[1] = {_("完成目标获得"),string.formatnumberthousands(self:GetShrineStage():GoldKill()),self:GetShrineStage():GoldRewards(terrain)}
	data[2] = {_("完成目标获得"),string.formatnumberthousands(self:GetShrineStage():SilverKill()),self:GetShrineStage():SilverRewards(terrain)}
	data[3] = {_("完成目标获得"),string.formatnumberthousands(self:GetShrineStage():BronzeKill()),self:GetShrineStage():BronzeRewards(terrain)}
	return data
end

function GameUIAllianceShrineRewardList:GetShrineStage()
	return self.shrineStage_
end

function GameUIAllianceShrineRewardList:RefreshRewardListView()
	self.rewards_listView:removeAllItems()
	for i,v in ipairs(self:GetListData()) do
		
		local item = self:GetListItem(i,v)
		self.rewards_listView:addItem(item)
	end
	self.rewards_listView:reload()
end

return GameUIAllianceShrineRewardList
