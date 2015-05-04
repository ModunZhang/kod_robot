--
-- Author: Kenny Dai
-- Date: 2015-01-26 16:46:44
--

local WidgetUIBackGround = import(".WidgetUIBackGround")
local UIListView = import("..ui.UIListView")

local WidgetInfoNotListView = class("WidgetInfoNotListView", function ()
    return display.newNode()
end)
function WidgetInfoNotListView:ctor(params)
    local info = params.info -- 显示信息
    local width = params.w or 568
    self.width = width
    self.info_bg = WidgetUIBackGround.new({width = width,height = params.h or #info*40+20},WidgetUIBackGround.STYLE_TYPE.STYLE_6)
        :addTo(self)

    if info then
        self:CreateInfoItem(info)
    end
end
function WidgetInfoNotListView:SetInfo(info)
    for k,v in pairs(self.items) do
        self.info_bg:removeChild(v, true)
    end
    self:CreateInfoItem(info)
    return self
end
function WidgetInfoNotListView:align(align,x,y)
    self.info_bg:align(align, x, y)
    return self
end
function WidgetInfoNotListView:GetListView()
    return self.info_listview
end
function WidgetInfoNotListView:CreateInfoItem(info_message)
    self.items = {}
    local meetFlag = true

    local item_width, item_height = self.width-20,40
    local origin_y = 30
    local gap_y = 40
    for k,v in ipairs(info_message) do

        local content
        if meetFlag then
            content = display.newScale9Sprite("back_ground_548x40_1.png",0,0,cc.size(self.width-20,40),cc.rect(10,10,528,20))
        else
            content = display.newScale9Sprite("back_ground_548x40_2.png",0,0,cc.size(self.width-20,40),cc.rect(10,10,528,20))
        end
        content:addTo(self.info_bg):align(display.CENTER, self.width/2,origin_y+gap_y*(k-1))
        UIKit:ttfLabel({
            text = v[1],
            size = 20,
            color = 0x797154,
        }):align(display.LEFT_CENTER, 10, item_height/2):addTo(content)
        if v[2] then
            local text_2 = UIKit:ttfLabel({
                text = v[2],
                size = 20,
                color = 0x403c2f,
            }):align(display.RIGHT_CENTER, item_width-10, item_height/2):addTo(content)
            -- icon
            if v[3] then
                local icon = display.newSprite(v[3]):align(display.RIGHT_CENTER, item_width-15, item_height/2):addTo(content)
                local is_icon_in_left_side = v[4]
                if is_icon_in_left_side then
                    icon:setPositionX(text_2:getPositionX()-text_2:getContentSize().width-10)
                else
                    text_2:setPositionX(item_width-60)
                end

            end
        end
        meetFlag = not meetFlag

        table.insert(self.items, content)
    end
end
return WidgetInfoNotListView






