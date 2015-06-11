--
-- Author: Kenny Dai
-- Date: 2015-01-21 10:37:19
-- 排列规则是3段文字，支持字体颜色，大小

local WidgetInfo = import(".WidgetInfo")
local WidgetInfoText = class("WidgetInfoText", WidgetInfo)

function WidgetInfoText:CreateInfoItem(info_message)
    local meetFlag = true

    local item_width, item_height = self.width-20,40
    for k,v in pairs(info_message) do
        local item = self.info_listview:newItem()
        item:setItemSize(item_width, item_height)
        local content
        if meetFlag then
            content = display.newScale9Sprite("back_ground_548x40_1.png",0,0,cc.size(self.width-20,40),cc.rect(10,10,528,20))
        else
            content = display.newScale9Sprite("back_ground_548x40_2.png",0,0,cc.size(self.width-20,40),cc.rect(10,10,528,20))
        end
        UIKit:ttfLabel({
            text = v[1].text,
            size = v[1].size,
            color = v[1].color,
        }):align(display.LEFT_CENTER, 10, item_height/2):addTo(content)
        UIKit:ttfLabel({
            text = v[2].text,
            size = v[2].size,
            color = v[2].color,
        }):align(display.CENTER, item_width/2, item_height/2):addTo(content)
        UIKit:ttfLabel({
            text = v[3].text,
            size = v[3].size,
            color = v[3].color,
        }):align(display.RIGHT_CENTER, item_width-10, item_height/2):addTo(content)

        meetFlag =  not meetFlag
        item:addContent(content)
        self.info_listview:addItem(item)
    end
    self.info_listview:reload()
end

return WidgetInfoText

