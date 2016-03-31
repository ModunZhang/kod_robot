--
-- Author: Kenny Dai
-- Date: 2016-02-22 10:29:40
--
local WidgetPopDialog = import("..widget.WidgetPopDialog")
local window = import("..utils.window")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local UIListView = import("..ui.UIListView")

local BODY_HEIGHT = 696
local BODY_WIDTH = 608
local WidgetKingWarRule = class("WidgetKingWarRule", WidgetPopDialog)

local rules = {
    {
        _("概述"),
        _("保护期：战争期结束后，开战的两个联盟会进入保护期 。其他联盟无法对处在保护期的联盟发起联盟战。但处在保护期的联盟可主动破除保护，对其他联盟发起联盟战。期的联盟可主动破除保护，对其他联盟发起联盟战。")
    },
    {
        _("概述"),
        _("保护期：战争期结束后，开战的两个联盟会进入保护期 。其他联盟无法对处在保护期的联盟发起联盟战。但处在保护期的联盟可主动破除保护，对其他联盟发起联盟战。期的联盟可主动破除保护，对其他联盟发起联盟战。")
    },
    {
        _("概述"),
        _("保护期：战争期结束后，开战的两个联盟会进入保护期 。其他联盟无法对处在保护期的联盟发起联盟战。但处在保护期的联盟可主动破除保护，对其他联盟发起联盟战。期的联盟可主动破除保护，对其他联盟发起联盟战。")
    },
    {
        _("概述"),
        _("保护期：战争期结束后，开战的两个联盟会进入保护期 。其他联盟无法对处在保护期的联盟发起联盟战。但处在保护期的联盟可主动破除保护，对其他联盟发起联盟战。期的联盟可主动破除保护，对其他联盟发起联盟战。")
    },
}

function WidgetKingWarRule:ctor()
    WidgetKingWarRule.super.ctor(self,BODY_HEIGHT,_("王座争夺战规则"),window.top-120)
end
function WidgetKingWarRule:onEnter()
    WidgetKingWarRule.super.onEnter(self)
    local gap_y = 160
    for i,v in ipairs(rules) do
    	self:CreateRuleNode(v[1],v[2]):align(display.TOP_CENTER, BODY_WIDTH/2, BODY_HEIGHT - 35 - (i-1) * gap_y):addTo(self:GetBody())
    end
end
function WidgetKingWarRule:CreateRuleNode( title,rule )
    local node = display.newNode()
    local node_width,node_height = 556,150
    node:setContentSize(cc.size(node_width,node_height))
    local title_bg = display.newSprite("title_552x16.png"):align(display.TOP_CENTER, node_width/2,node_height):addTo(node)
    UIKit:ttfLabel({text = title,
        size = 20,
        color = 0x403c2f
    }):align(display.CENTER, title_bg:getContentSize().width/2,title_bg:getContentSize().height/2):addTo(title_bg)

    local content = WidgetUIBackGround.new({width = 556,height= 120},WidgetUIBackGround.STYLE_TYPE.STYLE_5)
        :align(display.CENTER_BOTTOM,node_width / 2,0):addTo(node)
    local  listview = UIListView.new{
        -- bgColor = UIKit:hex2c4b(0x7a100000),
        viewRect = cc.rect(10,10, 536, 100),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
    }:addTo(content)
    local item = listview:newItem()
    local rule_item = UIKit:ttfLabel({text = rule,
        size = 20,
        color = 0x403c2f,
        dimensions = cc.size(500,0)
    })
    item:addContent(rule_item)
    item:setItemSize(536, 100)
    listview:addItem(item)
    listview:reload()
    return node
end
return WidgetKingWarRule








