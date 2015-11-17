local WidgetUIBackGround = import(".WidgetUIBackGround")
local UIListView = import("..ui.UIListView")

local WidgetInfo = class("WidgetInfo", function ()
    return display.newNode()
end)
function WidgetInfo:ctor(params)
    local info = params.info -- 显示信息
    local width = params.w or 568
    self.width = width
    local height = params.h or #info*40+20
    self.height = height
    self.info_bg = WidgetUIBackGround.new({width = width,height = height},WidgetUIBackGround.STYLE_TYPE.STYLE_6)
        :addTo(self)
    self.info_listview = UIListView.new{
        viewRect = cc.rect(10, 10, width-20, (params.h or #info*40+20)-20),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
    }:addTo(self.info_bg)

    -- 没有内容
    self.empty_label = UIKit:ttfLabel({
        text = _("当前没有内容"),
        size = 20,
        color = 0x615b44
    }):align(display.CENTER,width/2,height/2):addTo(self.info_bg)
    if info then
        self:SetInfo(info)
    else
        self.empty_label:show()
    end
end
function WidgetInfo:SetInfo(info)
    self.info_listview:removeAllItems()
    self:CreateInfoItem(info)
    self.empty_label:setVisible(#self:GetListView():getItems() < 1)
    return self
end
function WidgetInfo:align(align,x,y)
    self.info_bg:align(align, x, y)
    return self
end
function WidgetInfo:GetListView()
    return self.info_listview
end
function WidgetInfo:CreateInfoItem(info_message)
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
        if tolua.type(v[1]) == "table" then
                UIKit:ttfLabel({
                    text = v[1][1],
                    size = 20,
                    color = v[1][2],
                }):align(display.LEFT_CENTER, 10, item_height/2):addTo(content)
            else
                UIKit:ttfLabel({
                    text = v[1],
                    size = 20,
                    color = 0x615b44,
                }):align(display.LEFT_CENTER, 10, item_height/2):addTo(content)
            end
        -- UIKit:ttfLabel({
        --     text = v[1],
        --     size = 20,
        --     color = 0x615b44,
        -- }):align(display.LEFT_CENTER, 10, item_height/2):addTo(content)
        if v[2] then
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
                }):align(display.RIGHT_CENTER, item_width-10, item_height/2):addTo(content)
            end
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

        meetFlag =  not meetFlag
        item:addContent(content)
        self.info_listview:addItem(item)
    end
    self.info_listview:reload()
end
return WidgetInfo







