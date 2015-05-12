local WidgetPushButton = import(".WidgetPushButton")
local UIListView = import("..ui.UIListView")
local WidgetUIBackGround = import(".WidgetUIBackGround")
local WidgetPopDialog = import(".WidgetPopDialog")
local WidgetAllianceBuildingInfo = class("WidgetAllianceBuildingInfo", WidgetPopDialog)

function WidgetAllianceBuildingInfo:ctor()
    WidgetAllianceBuildingInfo.super.ctor(self,544, _("建筑详情"),display.top-150)
    local body = self.body
    local rb_size = body:getContentSize()
    -- 建筑详情介绍
    UIKit:ttfLabel(
        {
            text = "",
            size = 20,
            align = cc.ui.TEXT_ALIGN_CENTER,
            dimensions = cc.size(360,0),
            color = 0x615b44
        }):align(display.TOP_CENTER, rb_size.width/2, rb_size.height-40)
        :addTo(body)


    -- 帮助列表
    local info_bg = WidgetUIBackGround.new({width = 568,height = 382},WidgetUIBackGround.STYLE_TYPE.STYLE_6)
        :align(display.CENTER,rb_size.width/2, rb_size.height/2-40):addTo(body)
    
    self.info_listview = UIListView.new{
        viewRect = cc.rect(9, 10, 550, 362),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
    }:addTo(info_bg)

    local list = self.info_listview

    local flag = true
    for i=1,10 do
        local item = list:newItem()
        item:setItemSize(548, 40)
        local content
        if flag then
            content = display.newSprite("back_ground_548x40_1.png")
        else
            content = display.newSprite("back_ground_548x40_2.png")
        end
        UIKit:ttfLabel(
            {
                text = "",
                size = 20,
                color = 0x403c2f
            }):align(display.LEFT_CENTER, 10, 20)
            :addTo(content)
        item:addContent(content)
        list:addItem(item)
        flag = not flag
    end
    list:reload()
end

return WidgetAllianceBuildingInfo


