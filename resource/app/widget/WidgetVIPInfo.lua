--
-- Author: Kenny Dai
-- Date: 2015-03-28 16:23:47
--
local WidgetInfo = import(".WidgetInfo")
local WidgetVIPInfo = class("WidgetVIPInfo", WidgetInfo)


function WidgetVIPInfo:ctor(params)
    WidgetVIPInfo.super.ctor(self,params)
end


function WidgetVIPInfo:CreateInfoItem(info_message)
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
        local add_type = v[1]
        if add_type == "new" then
            UIKit:ttfLabel({
                text = v[2],
                size = 20,
                color = 0x007c23,
            }):align(display.LEFT_CENTER, 10, item_height/2):addTo(content)
        elseif add_type == "changeless" then
            UIKit:ttfLabel({
                text = v[2],
                size = 20,
                color = 0x797154,
            }):align(display.LEFT_CENTER, 10, item_height/2):addTo(content)
        elseif add_type == "edit" then
            local one = UIKit:ttfLabel({
                text = v[2],
                size = 20,
                color = 0x797154,
            }):align(display.LEFT_CENTER, 10, item_height/2):addTo(content)
            UIKit:ttfLabel({
                text = v[3],
                size = 20,
                color = 0x007c23,
            }):align(display.LEFT_CENTER, one:getPositionX()+one:getContentSize().width, item_height/2):addTo(content)
        end


        meetFlag =  not meetFlag
        item:addContent(content)
        self.info_listview:addItem(item)
    end
    self.info_listview:reload()
end

return WidgetVIPInfo

