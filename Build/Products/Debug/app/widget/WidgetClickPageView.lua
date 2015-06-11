local WidgetPushButton = import(".WidgetPushButton")
local WidgetClickPageView = class("WidgetClickPageView", function()
    return display.newNode()
end)

local CURRENT_TAG = 999

--[[--

WidgetClickPageView构建函数

可用参数有：
-   viewRect 页面控件的显示区域
@param table params 参数表

]]
function WidgetClickPageView:ctor(params)
    self.items_ = {}
    self.bg = params.bg
    local size = self.bg:getContentSize()
    self.width = size.width
    self.height = size.height
    self.current_index = 1

    self:addChild(self.bg)
    self.bg:align(display.CENTER, self.width/2, self.height/2)

    self:setContentSize(cc.size(self.width,self.height))

    self.left_btn =  WidgetPushButton.new(
        {normal = "brown_btn_up_34x165.png", pressed = "brown_btn_down_34x165.png"},
        {scale9 = false}
    )
        :addTo(self.bg):align(display.CENTER, 17,self.height/2)
        :onButtonClicked(function(event)
            self:changePage(false)
        end)
    self.left_btn:setRotationSkewY(180)
    self.right_btn =  WidgetPushButton.new(
        {normal = "brown_btn_up_34x165.png", pressed = "brown_btn_down_34x165.png"},
        {scale9 = false}
    )
        :addTo(self.bg):align(display.CENTER, self.width-17,self.height/2)
        :onButtonClicked(function(event)
            self:changePage(true)
        end)
end
--[[--

创建一个新的页面控件项

@return WidgetClickPageViewItem

]]
function WidgetClickPageView:newItem()
    local item = display.newNode()
    item:setContentSize(cc.size(self.width-196, self.height))
    return item
end
--[[--

添加一项到页面控件中

@param node item 页面控件项

@return WidgetClickPageView

]]
function WidgetClickPageView:addItem(item)
    table.insert(self.items_, item)
    item:align(display.CENTER,self.width/2,self.height)
        :addTo(self.bg)
    item:setVisible(false)
    return self
end

function WidgetClickPageView:changePage(isRight)
    local item_old = self.items_[self.current_index]
    item_old:setVisible(false)
    local change = isRight and 1 or -1
    self.current_index = self.current_index + change
    local item_new = self.items_[self.current_index]
    item_new:setVisible(true)

    self:VisableBtn_()
end

function WidgetClickPageView:VisableBtn_()
    self.right_btn:setVisible(self.current_index ~= #self.items_)
    self.left_btn:setVisible(self.current_index ~= 1)
end
--[[--

加载数据，各种参数

@return WidgetClickPageView

]]
function WidgetClickPageView:reload()
    local item =  self.items_[1]
    item:setVisible(true)
    self.current_index = 1
    self:VisableBtn_()
    return self
end

function WidgetClickPageView:align(align, x, y)
    self.bg:align(align, x, y)
    return self
end

return WidgetClickPageView








