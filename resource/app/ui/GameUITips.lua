--
-- Author: Danny He
-- Date: 2015-02-10 14:30:55
--
--
local GameUITips = UIKit:createUIClass("GameUITips","UIAutoClose")
local UILib = import(".UILib")
local UIListView = import(".UIListView")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local window = import("..utils.window")
local WidgetPushButton = import("..widget.WidgetPushButton")
local WidgetRoundTabButtons = import("..widget.WidgetRoundTabButtons")

function GameUITips:ctor(default_tab)
	GameUITips.super.ctor(self)
	self.default_tab = default_tab or "city"
end

function GameUITips:onEnter()
	GameUITips.super.onEnter(self)
	self:BuildUI()
end

function GameUITips:BuildUI()
	local bg = WidgetUIBackGround.new({height=762})
	self:addTouchAbleChild(bg)
	self.bg = bg
	bg:pos(((display.width - bg:getContentSize().width)/2),window.bottom_top)
	local titleBar = display.newSprite("title_blue_600x56.png"):align(display.LEFT_BOTTOM,3,747):addTo(bg)
	local closeButton = cc.ui.UIPushButton.new({normal = "X_1.png",pressed = "X_2.png"}, {scale9 = false})
	   	:addTo(titleBar)
	   	:align(display.BOTTOM_RIGHT,titleBar:getContentSize().width,0)
	   	:onButtonClicked(function ()
	   		self:LeftButtonClicked()
	   	end)
	UIKit:ttfLabel({
		text = _("游戏说明"),
		size = 22,
		shadow = true,
		color = 0xffedae
	}):addTo(titleBar):align(display.CENTER,300,28)
	
	self.tab_buttons = WidgetRoundTabButtons.new({
        {tag = "city",label = _("城市"),default = self.default_tab == "city"},
        {tag = "region",label = _("区域地图"),default = self.default_tab == "region"},
    }, function(tag)
       self:OnTabButtonClicked(tag)
    end,2):align(display.CENTER_BOTTOM,304,15):addTo(bg)
end

function GameUITips:OnTabButtonClicked(tag)
	local method = string.format("CreateUIIf_%s", tag)
	if self[method] then
		if self.cur_tab then self.cur_tab:hide() end
		self.cur_tab = self[method](self)
		self.cur_tab:show()
	end
end

function GameUITips:CreateUIIf_city()
	if self.city_node then
		self:RefreshCityListView()
		return self.city_node
	end
	local list_bg = display.newScale9Sprite("box_bg_546x214.png"):size(568,636):addTo(self.bg):align(display.TOP_CENTER, 304, 732)
	self.city_node = list_bg

	self.city_list = UIListView.new({
        viewRect = cc.rect(11,10, 546, 616),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(list_bg)
	self:RefreshCityListView()
	return self.city_node
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

function GameUITips:RefreshCityListView()
	self.city_list:removeAllItems()
	local data = self:Tips()
	for index,v in ipairs(data) do
		local item = self:GetItem(index,v.image,v.title,v.text,v.scale)
		self.city_list:addItem(item)
	end
	self.city_list:reload()
end

function GameUITips:GetItem(index,image,title,text,scale)
	local item = self.city_list:newItem()
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
-- Region tips
function GameUITips:RegionTips()
	local tips = {
		_("选择木材、石料、铁矿、粮食村落采集资源，满足发展城市和联盟的需求"),
		_("激活并参与圣地战，和盟友并肩作战，赢取丰厚的稀缺材料"),
		_("参加联盟会战，来一场争锋相对的较量，进攻敌方联盟的城市获得大量积分和资源"),
		_("如果你的盟友不幸成为敌方攻击的目标，协助盟友击退外敌"),
		_("联盟会战胜利后，联盟获得大量的荣誉点数"),
	}
	return tips
end

function GameUITips:CreateUIIf_region()
	if self.region_node then
		return self.region_node
	end
	local node = display.newNode():size(608,747):addTo(self.bg)
	display.newSprite("region_tips_556x344.png"):align(display.CENTER_TOP, 304, 740):addTo(node)


	local tips_bg = UIKit:CreateBoxPanelWithBorder({width = 556,height = 263}):align(display.BOTTOM_CENTER, 304, 120):addTo(node)
	local x,y = 10,250
	for index,v in ipairs(self:RegionTips()) do
		local star = display.newSprite("alliance_star_23x23.png"):align(display.LEFT_TOP, x, y):addTo(tips_bg)
		UIKit:ttfLabel({
			text = v,
			size = 18,
			color=0x403c2f,
			dimensions = cc.size(496,56)
		}):align(display.LEFT_TOP,x + 28, y+2):addTo(tips_bg)
		y = y - 52
	end
	self.region_node = node
	return self.region_node
end

return GameUITips