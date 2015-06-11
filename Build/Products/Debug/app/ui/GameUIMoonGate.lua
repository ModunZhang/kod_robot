--
-- Author: Kenny Dai
-- Date: 2015-01-14 20:59:24
--
local window = import("..utils.window")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local WidgetPushButton = import("..widget.WidgetPushButton")
local WidgetInfo = import("..widget.WidgetInfo")
local UIScrollView = import(".UIScrollView")
local Localize = import("..utils.Localize")

local wonder_grassLand = GameDatas.ClientInitGame.wonder_grassLand
local wonder_desert = GameDatas.ClientInitGame.wonder_desert
local wonder_iceField = GameDatas.ClientInitGame.wonder_iceField

local GameUIMoonGate = UIKit:createUIClass('GameUIMoonGate', "GameUIWithCommonHeader")

function GameUIMoonGate:ctor(city,default_tab,building)
    GameUIMoonGate.super.ctor(self, city, _("联盟月门"))
    self.building = building
end

function GameUIMoonGate:onEnter()
    GameUIMoonGate.super.onEnter(self)
end
function GameUIMoonGate:CreateBetweenBgAndTitle()
    GameUIMoonGate.super.CreateBetweenBgAndTitle(self)
    self.map_layer = display.newLayer():addTo(self:GetView())
    self.wonder_layer = display.newLayer():addTo(self:GetView())
    self.wonder_layer:setVisible(false)
    self:InitKingCity()
    self:InitWonderDetails()
end
function GameUIMoonGate:InitKingCity()
    local layer = self.map_layer
    local scroll_view_width = 610
    local scroll_view_height = 630

    -- 三种地形第一王城
    local biggest_wonder_grassLand = wonder_grassLand.highcastle
    local biggest_wonder_desert = wonder_desert.rockwarren
    local biggest_wonder_iceField = wonder_iceField.whitemoon

    -- 根据玩家所在联盟地形，初始化时定位对应地形第一王城
    local x,y = 0,0
    local terrain = Alliance_Manager:GetMyAlliance():Terrain()
    if terrain=="grassLand" then
        x,y = biggest_wonder_grassLand.x,biggest_wonder_grassLand.y
    elseif terrain=="desert" then
        x,y = biggest_wonder_desert.x,biggest_wonder_desert.y
    elseif terrain=="iceField" then
        x,y = biggest_wonder_iceField.x,biggest_wonder_iceField.y
    end

    local map = display.newSprite("world_map_2000x2000.jpg"):align(display.LEFT_BOTTOM, scroll_view_width/2-50-x,scroll_view_height/2-y)
    self:CreateAllWonders(map)

    local scrollView = UIScrollView.new({
        viewRect = cc.rect(0,0,scroll_view_width,scroll_view_height),
    })
        :addScrollNode(map)
        :setBounceable(false)
        :setDirection(UIScrollView.DIRECTION_BOTH)
        :align(display.CENTER,window.left+16,window.top_bottom-scroll_view_width)
        :addTo(layer)
    local line = display.newSprite("box_620x628.png"):align(display.TOP_CENTER, window.cx, window.top_bottom+20)
        :addTo(layer)
    local shadowLayer = UIKit:shadowLayer():addTo(layer)
        :align(display.CENTER, window.left+15, window.bottom + 263)
    shadowLayer:setContentSize(cc.size(620,34))
    UIKit:ttfLabel({
        text = _("王城争霸 未开启"),
        size = 22,
        color = 0xebdba0
    }):addTo(shadowLayer):align(display.CENTER,620/2,17)
    display.newSprite("i_icon_24x24.png"):align(display.CENTER, 580, 17)
        :addTo(shadowLayer)

    local line = display.newSprite("line_624x58.png"):align(display.CENTER, window.cx, window.bottom + 248)
        :addTo(layer)

    WidgetInfo.new({
        info={
            {_("开战王城"),_("未知")},
            {_("当前占领者"),_("未知")},
            {_("地形"),_("未知")},
        },
        w = 546
    }):align(display.BOTTOM_CENTER, window.cx, window.bottom + 90)
        :addTo(layer)
    WidgetPushButton.new(
        {normal = "yellow_btn_up_148x58.png",pressed = "yellow_btn_down_148x58.png"}
        ,{}
        ,{
            disabled = { name = "GRAY", params = {0.2, 0.3, 0.5, 0.1} }
        })
        :addTo(layer)
        :align(display.CENTER, window.cx, window.bottom + 54)
        :setButtonLabel(UIKit:ttfLabel({
            text = _("定位"),
            size = 24,
            color = 0xfff3c7
        }))
        :setButtonEnabled(false)
end

function GameUIMoonGate:CreateAllWonders(map)
    -- 草地
    for k,v in pairs(wonder_grassLand) do
        self:CreateWonderNode(v):addTo(map)
    end
    -- 沙漠
    for k,v in pairs(wonder_desert) do
        self:CreateWonderNode(v):addTo(map)
    end
    -- 雪地
    for k,v in pairs(wonder_iceField) do
        self:CreateWonderNode(v):addTo(map)
    end
end
function GameUIMoonGate:CreateWonderNode(wonder)
    local wonder_node = display.newNode()
    wonder_node:setPosition(wonder.x, wonder.y)
    local w_name = wonder.name
    local terrain = wonder.terrain
    local wonder_img
    if terrain == "grassLand" then
        wonder_img = "Icon_wonder_grassLand.png"
    elseif terrain == "desert" then
        wonder_img = "Icon_wonder_desert.png"
    elseif terrain == "iceField" then
        wonder_img = "Icon_wonder_iceField.png"
    end
    local button = WidgetPushButton.new({normal = wonder_img,pressed = wonder_img})
        :onButtonClicked(function(event)
            if event.name == "CLICKED_EVENT" then
                if self.map_layer:isVisible() then
                    self:ShowWonderDetails(wonder)
                end
            end
        end)
        :align(display.CENTER, 0,0)
        :addTo(wonder_node)

    -- 非一等王城，缩小尺寸
    if wonder.order>1 then
        button:scale(0.5)
    else
        button:scale(0.7)
    end
    local name_bg = display.newSprite("back_ground_130x34.png")
        :align(display.CENTER, 0,-button:getCascadeBoundingBox().size.height/2-22)
        :addTo(wonder_node)
    UIKit:ttfLabel({
        text = Localize.wonder_name[w_name],
        size = 18,
        color = 0xffedae,
        shadow = true
    }):addTo(name_bg)
        :align(display.CENTER, name_bg:getContentSize().width/2, name_bg:getContentSize().height/2)

    return wonder_node
end
function GameUIMoonGate:InitWonderDetails()
    local layer = self.wonder_layer
    -- 放地图的裁剪区域
    local map_rect = display.newClippingRegionNode(cc.rect(window.left+15, window.top_bottom-364,612,384)):addTo(layer)
    local map = display.newSprite("world_map_2000x2000.jpg"):align(display.LEFT_BOTTOM)
        :addTo(map_rect)
    self:CreateAllWonders(map)
    local shadowLayer = UIKit:shadowLayer():addTo(layer)
        :align(display.CENTER, window.left+15, window.top_bottom -363)
    shadowLayer:setContentSize(cc.size(620,62))
    local title_bg = display.newSprite("line_624x102.png")
        :align(display.LEFT_BOTTOM, -7,-40)
        :addTo(shadowLayer)
    -- 返回地图按钮
    local return_button = cc.ui.UIPushButton.new(
        {normal = "home_btn_up.png",pressed = "home_btn_down.png"})
        :onButtonClicked(function(event)
            self.map_layer:setVisible(true)
            self.wonder_layer:setVisible(false)
        end)
        :align(display.LEFT_TOP,3 , title_bg:getContentSize().height-1)
        :addTo(title_bg)
    display.newSprite("dragon_next_icon_28x31.png"):align(display.CENTER, return_button:getCascadeBoundingBox().size.width/2, -return_button:getCascadeBoundingBox().size.height/2)
        :addTo(return_button)
        :setFlippedX(true)
    -- title
    UIKit:ttfLabel({
        text = _("头衔"),
        size = 28,
        color = 0xebdba0,
    }):addTo(title_bg)
        :align(display.CENTER, title_bg:getContentSize().width/2+18, title_bg:getContentSize().height/2 +18)

    -- 信息框背景
    local info_bg = display.newSprite("back_ground_306x282.png"):align(display.CENTER,window.cx+140,window.top_bottom-140)
        :addTo(layer)
    display.newSprite("box_86x86.png"):align(display.CENTER,50,231)
        :addTo(info_bg)
    display.newSprite("box_86x86.png"):align(display.CENTER,50,138)
        :addTo(info_bg)
    local honour_bg = display.newSprite("box_86x86.png"):align(display.CENTER,50,44)
        :addTo(info_bg)
    display.newSprite("honour_128x128.png"):align(display.CENTER,honour_bg:getContentSize().width/2,honour_bg:getContentSize().height/2)
        :addTo(honour_bg):scale(0.5)
    UIKit:ttfLabel({
        text = _("占领联盟"),
        size = 22,
        color = 0xebdba0,
    }):addTo(info_bg)
        :align(display.CENTER, 180,248)
    UIKit:ttfLabel({
        text = _("无"),
        size = 22,
        color = 0xebdba0,
    }):addTo(info_bg)
        :align(display.CENTER, 180,218)
    UIKit:ttfLabel({
        text = _("国王"),
        size = 22,
        color = 0xebdba0,
    }):addTo(info_bg)
        :align(display.CENTER, 180,155)
    UIKit:ttfLabel({
        text = _("无"),
        size = 22,
        color = 0xebdba0,
    }):addTo(info_bg)
        :align(display.CENTER, 180,125)

    UIKit:ttfLabel({
        text = _("每日产出"),
        size = 22,
        color = 0xebdba0,
    }):addTo(info_bg)
        :align(display.CENTER, 180,62)
    local honour_perday = UIKit:ttfLabel({
        size = 22,
        color = 0xebdba0,
    }):addTo(info_bg)
        :align(display.CENTER, 180,33)

    --
    local listview,node=  UIKit:commonListView({
        viewRect = cc.rect(0, 0, 568, 450),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
    })
    node:addTo(layer):pos(window.cx,window.bottom + 30)
    node:align(display.BOTTOM_CENTER)

    function map:Refresh(wonder)
        dump(wonder,"wonder")
        self:setPosition(window.left+140-wonder.x,window.bottom+740-wonder.y)
        local add_honour = ""
        if wonder.name == "highcastle" or wonder.name == "rockwarren" or wonder.name == "whitemoon" then
            add_honour = _("大量联盟荣耀值")
        else
            add_honour = _("少量联盟荣耀值")
        end
        honour_perday:setString(add_honour)
        local titles = string.split(wonder.title,",")
        listview:removeAllItems()
        for k,v in pairs(titles) do
            local item = listview:newItem()
            local item_width,item_height = 568,154
            item:setItemSize(item_width,item_height)
            local content = WidgetUIBackGround.new({width=item_width,height=item_height},WidgetUIBackGround.STYLE_TYPE.STYLE_2)
            item:addContent(content)
            listview:addItem(item)

            local title_bg = display.newScale9Sprite("title_blue_430x30.png", item_width-10, item_height-30,cc.size(412,30),cc.rect(15,10,400,10))
                :align(display.RIGHT_CENTER)
                :addTo(content)
            UIKit:ttfLabel({
                text = Localize.wonder_title_name[v],
                size = 22,
                color = 0xebdba0,
            }):addTo(title_bg)
                :align(display.LEFT_CENTER, 20,title_bg:getContentSize().height/2)
            local box = display.newSprite("box_136x136.png"):align(display.CENTER,80,item_height/2)
                :addTo(content)
            UIKit:ttfLabel({
                text = Localize.wonder_title_buff[v],
                size = 20,
                color = 0x403c2f,
                dimensions = cc.size(360,0)
            }):addTo(content)
                :align(display.LEFT_CENTER, 160,item_height/2)
        end
        listview:reload()
    end
    self.wonder_map = map
end
function GameUIMoonGate:ShowWonderDetails( wonder )
    self.map_layer:setVisible(false)
    self.wonder_layer:setVisible(true)
    self.wonder_map:Refresh(wonder)
end
function GameUIMoonGate:onExit()
    GameUIMoonGate.super.onExit(self)
end

return GameUIMoonGate


















