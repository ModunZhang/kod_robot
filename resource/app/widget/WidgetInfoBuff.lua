--
-- Author: Danny He
-- Date: 2015-02-09 11:21:23
--
local WidgetInfo = import(".WidgetInfo")
local WidgetInfoBuff = class("WidgetInfoBuff", WidgetInfo)


function WidgetInfoBuff:ctor(params)
	dump(params,"params--->")
	self.color = params.color or 0x068329
	WidgetInfoBuff.super.ctor(self,params)
end


function WidgetInfoBuff:CreateInfoItem(info_message)
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
            text = v[1],
            size = 20,
            color = 0x615b44,
        }):align(display.LEFT_CENTER, 10, item_height/2):addTo(content)

        if v[2] then
        	local label_1_x = item_width-10
        	if v[3] and type(v[3]) == 'string' then
        		local label_2 = UIKit:ttfLabel({
	                text = v[3],
	                size = 20,
	                color = self.color,
            	}):align(display.RIGHT_CENTER, item_width-10, item_height/2):addTo(content)
            	label_1_x = label_2:getPositionX() - label_2:getContentSize().width - 2
        	end
			UIKit:ttfLabel({
                text = v[2],
                size = 20,
                color = 0x403c2f,
            }):align(display.RIGHT_CENTER,label_1_x, item_height/2):addTo(content)
        end

        meetFlag =  not meetFlag
        item:addContent(content)
        self.info_listview:addItem(item)
    end
    self.info_listview:reload()
end

return WidgetInfoBuff