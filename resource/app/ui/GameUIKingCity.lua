--
-- Author: Kenny Dai
-- Date: 2015-01-16 09:35:29
--
local window = import("..utils.window")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local WidgetPushButton = import("..widget.WidgetPushButton")
local UIListView = import(".UIListView")

local GameUIKingCity = UIKit:createUIClass('GameUIKingCity',"GameUIWithCommonHeader")

function GameUIKingCity:ctor(city)
    GameUIKingCity.super.ctor(self, city, _("王城"))
end

function GameUIKingCity:onEnter()
    GameUIKingCity.super.onEnter(self)
    self:Init()
end
function GameUIKingCity:Init()
	-- 王城信息
	self:InitInfo()
	-- 头衔任命
	self:InitTitles()
end
function GameUIKingCity:InitInfo()
	-- bg
	local background = display.newSprite("back_ground_550x364.png"):align(display.TOP_CENTER,window.cx,window.top_bottom)
		:addTo(self)
	UIKit:ttfLabel(
        {
            text = _("联盟"),
            size = 20,
            color = 0x797154
        }):align(display.LEFT_CENTER, 80, 234)
        :addTo(background)
    UIKit:ttfLabel(
        {
            text = _("无"),
            size = 22,
            color = 0x403c2f
        }):align(display.RIGHT_CENTER, 470, 234)
        :addTo(background)

    UIKit:ttfLabel(
        {
            text = _("国王"),
            size = 20,
            color = 0x797154
        }):align(display.LEFT_CENTER, 80, 190)
        :addTo(background)
    UIKit:ttfLabel(
        {
            text = _("无"),
            size = 22,
            color = 0x403c2f
        }):align(display.RIGHT_CENTER, 470, 190)
        :addTo(background)

    UIKit:ttfLabel(
        {
            text = _("占领王城的联盟盟主当选国王，可以给任一玩家指定头衔同时该联盟将获得大量的荣誉值"),
            size = 18,
            color = 0x403c2f,
            dimensions = cc.size(350,90)
        }):align(display.LEFT_TOP, 100, 140)
        :addTo(background)
    
end
function GameUIKingCity:InitTitles()
	UIKit:ttfLabel(
        {
            text = _("头衔"),
            size = 22,
            color = 0x403c2f
        }):align(display.CENTER, window.cx-2, window.top-460)
        :addTo(self)

	local list_view ,listnode=  UIKit:commonListView({
        viewRect = cc.rect(0,0, 594, 440),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
    })
    listnode:align(display.BOTTOM_CENTER, window.cx,window.bottom+30):addTo(self)

    local titles = {
    {
    	title = _("大法官"),
    	effect = _("所有部队的生命值+15%。维护费-5%"),
    },
    {
    	title = _("勇士"),
    	effect = _("所有部队的攻击力+10%,生命值+10%,行军速度+10%"),
    },
    {
    	title = _("废物"),
    	effect = _("所有部队的攻击力-10%,生命值-10%,行军速度-10%"),
    },
}
for k,v in pairs(titles) do
    self:CreateTitleItem(list_view,v)
end
    list_view:reload()
end
function GameUIKingCity:CreateTitleItem(list,params)
	local item = list:newItem()
	local item_width,item_height = 568,154
	item:setItemSize(item_width,item_height)
	list:addItem(item)

	local content = WidgetUIBackGround.new({width=item_width,height=item_height},WidgetUIBackGround.STYLE_TYPE.STYLE_2)
	item:addContent(content)

	display.newSprite("box_136x136.png"):pos(80,item_height/2):addTo(content)
	local title_bg = display.newScale9Sprite("title_blue_430x30.png",item_width/2+70,item_height-30,cc.size(412,30),cc.rect(15,10,400,10))
            :addTo(content)
    UIKit:ttfLabel({
        text = params.title,
        size = 22,
        color = 0xffedae,
    }):align(display.LEFT_CENTER, 20 , title_bg:getContentSize().height/2)
        :addTo(title_bg)
    UIKit:ttfLabel(
        {
            text =params.effect,
            size = 20,
            color = 0x403c2f,
            dimensions = cc.size(350,0)
        }):align(display.LEFT_TOP, 168, 80)
        :addTo(content)

     WidgetPushButton.new({normal = "next_32x38.png",pressed = "next_32x38.png"})
            :onButtonClicked(function(event)
                if event.name == "CLICKED_EVENT" then
                    UIKit:showMessageDialog(_("提示"),_("权限不足,不能任命头衔"))
                end
            end):align(display.CENTER, item_width-25, 66):addTo(content)
end
function GameUIKingCity:onExit()
    GameUIKingCity.super.onExit(self)
end

return GameUIKingCity