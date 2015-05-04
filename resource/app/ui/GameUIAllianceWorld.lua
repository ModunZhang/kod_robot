
local WidgetPushButton = import("..widget.WidgetPushButton")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local WidgetPopDialog = import("..widget.WidgetPopDialog")
local UIListView = import(".UIListView")
local UIScrollView = import(".UIScrollView")
local window = import("..utils.window")

local GameUIAllianceWorld = class("GameUIAllianceWorld", WidgetPopDialog)

function GameUIAllianceWorld:ctor()
    GameUIAllianceWorld.super.ctor(self,880,_("世界地图"),window.top-60)

    local map = display.newSprite("world_map_2000x2000.jpg"):scale(1.8):align(display.CENTER, 278, 270)
    
    local scrollView = UIScrollView.new({
        viewRect = cc.rect(0,0,556,541),
    })
        :addScrollNode(map)
        :setBounceable(false)
        :setDirection(UIScrollView.DIRECTION_BOTH)
        :align(display.TOP_CENTER,26, self.body:getContentSize().height-569)


    -- 遮罩效果
    -- 模板
    local stencil = display.newNode()
    stencil:addChild(display.newSprite("info_26x26.png"):pos(20, 310))
    stencil:addChild(display.newSprite("info_26x26.png"):pos(20, 852))
    stencil:addChild(display.newSprite("info_26x26.png"):pos(588, 310))
    stencil:addChild(display.newSprite("info_26x26.png"):pos(588, 852))
    -- stencil

    -- 初始化一个裁剪节点
    local clippingNode = cc.ClippingNode:create(stencil)
        :pos(0, self.body:getContentSize().height-880)
    clippingNode:setInverted(true)
    clippingNode:setAlphaThreshold(0.5)
    -- 底板
    clippingNode:addChild(scrollView)
    self.body:addChild(clippingNode)

    local bg1 = WidgetUIBackGround.new({width = 572,height=557},WidgetUIBackGround.STYLE_TYPE.STYLE_4)
        :align(display.TOP_CENTER,304, self.body:getContentSize().height-20):addTo(self.body)
    -- 介绍
    local info_bg = WidgetUIBackGround.new({width = 568,height = 200},WidgetUIBackGround.STYLE_TYPE.STYLE_6)
        :align(display.BOTTOM_CENTER,304, 90):addTo(self.body)

    local info_message = {
        {_("统治联盟"),"Kingdoms of Dragon"},
        {_("国王"),"孙悟空"},
        {_("开服时间"),"1 month 13 days"},
        {_("人口密度"),"Low"},
    }
    self.info_listview = UIListView.new{
        viewRect = cc.rect(9, 10, 550, 180),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
    }:addTo(info_bg)
    self:CreateInfoItem(info_message)
    -- 迁移按钮
    WidgetPushButton.new({normal = "blue_btn_up_142x39.png",pressed = "blue_btn_down_142x39.png"})
        :setButtonLabel(UIKit:ttfLabel({
            text = _("迁移"),
            size = 24,
            color = 0xffedae,
            shadow= true
        }))
        :onButtonClicked(function(event)
            if event.name == "CLICKED_EVENT" then

            end
        end):align(display.CENTER, 100, 50):addTo(self.body)
    -- 首都按钮
    WidgetPushButton.new({normal = "yellow_button_146x42.png",pressed = "yellow_button_highlight_146x42.png"})
        :setButtonLabel(UIKit:ttfLabel({
            text = _("首都"),
            size = 24,
            color = 0xffedae,
            shadow= true
        }))
        :onButtonClicked(function(event)
            if event.name == "CLICKED_EVENT" then

            end
        end):align(display.CENTER, 508, 50):addTo(self.body)
end
function GameUIAllianceWorld:CreateInfoItem(info_message)
    local meetFlag = true

    local item_width, item_height = 550,46
    for k,v in pairs(info_message) do
        local item = self.info_listview:newItem()
        item:setItemSize(item_width, item_height)
        local content
        if meetFlag then
            content = display.newSprite("upgrade_resources_background_3.png"):scale(550/520)
        else
            content = display.newSprite("upgrade_resources_background_2.png"):scale(550/520)
        end
        UIKit:ttfLabel({
            text = v[1],
            size = 20,
            color = 0x5d563f,
        }):align(display.LEFT_CENTER, 10, item_height/2):addTo(content)
        UIKit:ttfLabel({
            text = v[2],
            size = 20,
            color = 0x403c2f,
        }):align(display.RIGHT_CENTER, 510, item_height/2):addTo(content)
        meetFlag =  not meetFlag
        item:addContent(content)
        self.info_listview:addItem(item)
    end
    self.info_listview:reload()
end

function GameUIAllianceWorld:onEnter()
end

function GameUIAllianceWorld:onExit()
    UIKit:getRegistry().removeObject(self.__cname)
end

return GameUIAllianceWorld




