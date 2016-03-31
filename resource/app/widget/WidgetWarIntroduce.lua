--
-- Author: Kenny Dai
-- Date: 2015-10-19 10:25:33
--
local WidgetPushButton = import("..widget.WidgetPushButton")
local WidgetPopDialog = import("..widget.WidgetPopDialog")
local UIListView = import("..ui.UIListView")
local window = import("..utils.window")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local WidgetWarIntroduce = class("WidgetWarIntroduce", WidgetPopDialog)

function WidgetWarIntroduce:ctor()
    WidgetWarIntroduce.super.ctor(self,466,_("联盟会战说明"),window.top-120)
    self:setNodeEventEnabled(true)
    local body = self.body
    local b_size = body:getContentSize()
    WidgetPushButton.new({normal = "yellow_btn_up_186x66.png",pressed = "yellow_btn_down_186x66.png"})
        :align(display.CENTER,b_size.width/2,60)
        :onButtonClicked(function(event)
            if event.name == "CLICKED_EVENT" then
                self:LeftButtonClicked()
            end
        end)
        :setButtonLabel("normal", UIKit:ttfLabel({
            text = _("明白"),
            size = 22,
            color = 0xfff3c7,
            shadow = true
        }))
        :addTo(body)
    local intro_bg = WidgetUIBackGround.new({width = 584,height= 322},WidgetUIBackGround.STYLE_TYPE.STYLE_5):align(display.CENTER_BOTTOM,  b_size.width/2,110):addTo(body)
    local listview = UIListView.new{
        -- bgColor = UIKit:hex2c4b(0x7a100000),
        viewRect = cc.rect(14,10, 560, 302),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
    }:addTo(intro_bg)

    local item = listview:newItem()
    local content = display.newNode()
    local info = {
        _("和平期：联盟将军以上的职位的玩家可对和平期的联盟发起联盟战"),
        _("准备期：发起联盟战后，双方联盟有一段准备时间"),
        _("战前期：就是干（注意协防己方玩家城市）。击溃敌方城市可获得额外联盟荣耀值。"),
        _("保护期：战争期结束后，开战的两个联盟会进入保护期。其他联盟无法对处于保护期的联盟发起联盟战。但处于保护期的联盟可以主动破除保护，对其他联盟发起联盟战。"),
    }
    local total_size = 0
    local labels = {}
    for i,v in ipairs(info) do
        local label =  UIKit:ttfLabel({
            text = v,
            size = 20,
            color = 0x403c2f,
            dimensions = cc.size(530,0)
        })
        table.insert(labels,label) 
        total_size = total_size + label:getContentSize().height
    end

    content:setContentSize(cc.size(560,total_size))
    local x,y = 0,total_size
    for i,label in ipairs(labels) do
        local star = display.newSprite("icon_star_22x20.png"):addTo(content):align(display.LEFT_TOP,x,y)
        label:align(display.LEFT_TOP, x + 30, y)
            :addTo(content)
        y = y - label:getContentSize().height
    end
    item:addContent(content)
    item:setItemSize(560, total_size)
    listview:addItem(item)
    listview:reload()
end

return WidgetWarIntroduce














