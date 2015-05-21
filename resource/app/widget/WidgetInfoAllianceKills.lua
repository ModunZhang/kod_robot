--
-- Author: Kenny Dai
-- Date: 2015-05-11 16:48:03
--
local WidgetInfo = import(".WidgetInfo")
local WidgetInfoAllianceKills = class("WidgetInfoAllianceKills", WidgetInfo)

function WidgetInfoAllianceKills:CreateInfoItem(info_message)
    local meetFlag = true

    local item_width, item_height = self.width-20,40
    for k,member in ipairs(info_message) do
        local item = self.info_listview:newItem()
        item:setItemSize(item_width, item_height)
        local content
        if meetFlag then
            content = display.newScale9Sprite("back_ground_548x40_1.png",0,0,cc.size(self.width-20,40),cc.rect(10,10,528,20))
        else
            content = display.newScale9Sprite("back_ground_548x40_2.png",0,0,cc.size(self.width-20,40),cc.rect(10,10,528,20))
        end
         UIKit:ttfLabel({
            text = k.."."..member.name,
            size = 22,
            color = 0x403c2f,
        }):align(display.LEFT_CENTER,20,20)
            :addTo(content)

        local t = UIKit:ttfLabel({
            text = string.formatnumberthousands(member.kill),
            size = 22,
            color = 0x403c2f,
        }):align(display.RIGHT_CENTER,520,20)
            :addTo(content)
        display.newSprite("battle_33x33.png")
            :align(display.RIGHT_CENTER,510-t:getContentSize().width,20)
            :addTo(content)

        meetFlag =  not meetFlag
        item:addContent(content)
        self.info_listview:addItem(item)
    end
    self.info_listview:reload()
end

return WidgetInfoAllianceKills

