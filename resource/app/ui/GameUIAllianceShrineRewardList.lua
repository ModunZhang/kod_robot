--
-- Author: Danny He
-- Date: 2014-11-12 10:02:15
--
local GameUIAllianceShrineRewardList = UIKit:createUIClass("GameUIAllianceShrineRewardList","UIAutoClose")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local HEIGHT = 438
local window = import("..utils.window")
local UIListView = import(".UIListView")
local Alliance_Manager = Alliance_Manager
local UILib = import(".UILib")

function GameUIAllianceShrineRewardList:ctor(shrineStage)
	GameUIAllianceShrineRewardList.super.ctor(self)
	self.shrineStage_ = shrineStage
end

function GameUIAllianceShrineRewardList:onEnter()
	GameUIAllianceShrineRewardList.super.onEnter(self)
	self:BuildUI()
end

function GameUIAllianceShrineRewardList:BuildUI()
	local background = WidgetUIBackGround.new({height = HEIGHT})
		:pos(window.left+22,window.top - 101 - HEIGHT)
	self:addTouchAbleChild(background)
	local title_bar = display.newSprite("title_blue_600x56.png"):align(display.CENTER_BOTTOM, 304,HEIGHT - 15):addTo(background)
	UIKit:ttfLabel({
		text = _("事件完成奖励"),
		size = 22,
		color = 0xffedae
	}):align(display.CENTER,300,26):addTo(title_bar)
	local closeButton = UIKit:closeButton()
	   	:addTo(title_bar)
	   	:align(display.BOTTOM_RIGHT,title_bar:getContentSize().width, 0)
	   	:onButtonClicked(function ()
	   		self:LeftButtonClicked()
	   	end)

	self.rewards_listView = UIListView.new({
        viewRect = cc.rect(7, 100,595, 300),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL,
        alignment = UIListView.ALIGNMENT_LEFT,
    }):addTo(background)
	local line = display.newScale9Sprite("dividing_line_594x2.png"):size(590,1):align(display.LEFT_BOTTOM,10,710):addTo(background)
	cc.ui.UIPushButton.new({
		normal = "yellow_btn_up_185x65.png",
		pressed = "yellow_btn_down_185x65.png"
	}):align(display.RIGHT_BOTTOM,580,20):addTo(background)
	:setButtonLabel("normal",UIKit:commonButtonLable({
		text = _("确定")
	}))
	:onButtonClicked(function()
		self:LeftButtonClicked()
	end)
	self:RefreshRewardListView()
end

function GameUIAllianceShrineRewardList:GetListItem(index,data) 
	local node = display.newNode()
	local line = display.newScale9Sprite("dividing_line_594x2.png"):size(595,1):align(display.LEFT_BOTTOM,0,0):addTo(node)
	local iconImage = "GoldKill_icon_66x76.png"
	if index == 1 then
		iconImage = "GoldKill_icon_66x76.png"
	elseif index == 2 then
		iconImage = "SilverKill_icon_66x76.png"
	elseif index == 3 then
		iconImage = "BronzeKill_icon_66x76.png"
	end
	local icon = display.newSprite(iconImage):align(display.LEFT_BOTTOM,20,10):addTo(node)
	local strength_icon = display.newSprite("dragon_strength_27x31.png")
		:align(display.LEFT_BOTTOM,icon:getPositionX()+icon:getContentSize().width+10,icon:getPositionY()+2)
		:addTo(node)
	UIKit:ttfLabel({
		text = data[2],
		size = 22,
		color = 0x403c2f
	}):addTo(node):align(display.LEFT_BOTTOM,strength_icon:getPositionX()+strength_icon:getContentSize().width+5,strength_icon:getPositionY())
	local label = UIKit:ttfLabel({
		text = data[1],
		size = 22,
		color = 0x403c2f
	}):addTo(node):align(display.LEFT_TOP,strength_icon:getPositionX(),icon:getPositionY()+icon:getContentSize().height)
	local x,y = strength_icon:getPositionX()+strength_icon:getContentSize().width+200,label:getPositionY()+10

	for i,v in ipairs(data[3]) do
		local item = display.newScale9Sprite("box_118x118.png"):scale(0.59)
			:align(display.LEFT_TOP,x,y)
			:addTo(node)
			if v.type == 'dragonMaterials' then
				local sp = display.newSprite(UILib.dragon_material_pic_map[v.sub_type]):align(display.CENTER,59,59)
				local size = sp:getContentSize()
				sp:scale(100/math.max(size.width,size.height)):addTo(item)
			elseif v.type == 'allianceInfo' then
				if v.sub_type == 'loyalty' then
					local sp = display.newSprite("loyalty_128x128.png"):align(display.CENTER,59,59)
					sp:scale(0.78):addTo(item)
				end
			end
		UIKit:ttfLabel({
			text = "x" .. v.count,
			size = 22,
			color = 0x403c2f
		}):addTo(node):align(display.TOP_CENTER,x + 35,y - 68)
		x = x + 70 + 20
	end
	return node
end

function GameUIAllianceShrineRewardList:GetListData()
	local terrain = Alliance_Manager:GetMyAlliance():Terrain()
	local data = {}
	data[1] = {"奖励等级本地化缺失",string.formatnumberthousands(self:GetShrineStage():GoldKill()),self:GetShrineStage():GoldRewards(terrain)}
	data[2] = {"奖励等级本地化缺失",string.formatnumberthousands(self:GetShrineStage():SilverKill()),self:GetShrineStage():SilverRewards(terrain)}
	data[3] = {"奖励等级本地化缺失",string.formatnumberthousands(self:GetShrineStage():BronzeKill()),self:GetShrineStage():BronzeRewards(terrain)}
	return data
end

function GameUIAllianceShrineRewardList:GetShrineStage()
	return self.shrineStage_
end

function GameUIAllianceShrineRewardList:RefreshRewardListView()
	self.rewards_listView:removeAllItems()
	for i,v in ipairs(self:GetListData()) do
		local item = self.rewards_listView:newItem()
		local content = self:GetListItem(i,v)
		item:addContent(content)
		content:size(595,100)
		item:setItemSize(595,100)
		self.rewards_listView:addItem(item)
	end
	self.rewards_listView:reload()
end

return GameUIAllianceShrineRewardList
