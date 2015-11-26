local WidgetUIBackGround = import(".WidgetUIBackGround")
local UIListView = import("..ui.UIListView")

local WidgetInfoWithTitle = class("WidgetInfoWithTitle", function ()
    return display.newNode()
end)
function WidgetInfoWithTitle:ctor(params)
    local info = params.info -- 显示信息
    local width = params.w or 548
    local height = params.h or 266
    self.width = width
    self.height = height
    self:setContentSize(cc.size(width,height))
    self.info_bg = display.newScale9Sprite("back_ground_540x64.png",0 , 0,cc.size(width - 8 ,height - 50),cc.rect(15,10,510,44))
        :align(display.LEFT_BOTTOM)
        :addTo(self)
    local title_bg = display.newSprite("alliance_evnets_title_548x50.png"):align(display.LEFT_TOP, -4, height):addTo(self.info_bg)

    UIKit:ttfLabel({
        text = params.title,
        size = 24,
        color = 0xffedae
    }):align(display.CENTER,title_bg:getContentSize().width/2, title_bg:getContentSize().height/2)
        :addTo(title_bg)
    self.info_listview = UIListView.new{
        viewRect = cc.rect(9, 10, width -26, height-66),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
    }:addTo(self.info_bg)

    if info then
        self:CreateInfoItems(info)
    end
end

function WidgetInfoWithTitle:align(align,x,y)
    self.info_bg:align(align, x, y)
    return self
end

function WidgetInfoWithTitle:CreateInfoItems(info_message)
    if not info_message then
        return
    end
    self.info_listview:removeAllItems()
    local meetFlag = true

    local item_width, item_height = self.width-10,40
    for k,v in pairs(info_message) do
        local item = self.info_listview:newItem()
        item:setItemSize(item_width, item_height)
        local content = display.newNode()
        content:setContentSize(cc.size(item_width, item_height))
        display.newScale9Sprite(meetFlag and "back_ground_548x40_1.png" or "back_ground_548x40_2.png",item_width/2,item_height/2,cc.size(item_width,item_height),cc.rect(15,10,518,20))
            :addTo(content)

        UIKit:ttfLabel({
            text = v[1],
            size = 20,
            color = 0x615b44,
        }):align(display.LEFT_CENTER, 20, item_height/2):addTo(content)

        local text_2
        if tolua.type(v[2]) == "table" then
            text_2 = UIKit:ttfLabel({
                text = v[2][1],
                size = 20,
                color = v[2][2],
            }):align(display.RIGHT_CENTER, item_width-20, item_height/2):addTo(content)
        else
            text_2 = UIKit:ttfLabel({
                text = v[2],
                size = 20,
                color = 0x403c2f,
            }):align(display.RIGHT_CENTER, item_width-20, item_height/2):addTo(content)
        end

        if v[3] then
            if tolua.type(v[3]) == "table" then
                 text_3 = UIKit:ttfLabel({
                    text = v[3][1],
                    size = 20,
                    color = v[3][2],
                }):align(display.RIGHT_CENTER, item_width-20, item_height/2):addTo(content)
                text_2:setPositionX(text_3:getPositionX() - text_3:getContentSize().width - 10)
            else
                display.newSprite(v[3]):align(display.RIGHT_CENTER, item_width-15, item_height/2):addTo(content)
                text_2:setPositionX(item_width-60)
            end
        end

        meetFlag =  not meetFlag
        item:addContent(content)
        self.info_listview:addItem(item)
    end
    self.info_listview:reload()
end
function WidgetInfoWithTitle:GetListView()
    return self.info_listview
end
return WidgetInfoWithTitle





