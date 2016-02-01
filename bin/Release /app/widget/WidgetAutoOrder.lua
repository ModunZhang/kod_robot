--
-- Author: Kenny Dai
-- Date: 2015-04-08 11:13:41
--
local WidgetAutoOrder = class("WidgetAutoOrder", function ()
    return display.newNode()
end)
-- 缩进类型
WidgetAutoOrder.ORIENTATION = {
    LEFT_TO_RIGHT = 1,
    RIGHT_TO_LEFT = 2,
    TOP_TO_BOTTOM = 3,
    BOTTOM_TO_TOP = 4,
}
function WidgetAutoOrder:ctor(order_type,default_gap,not_need_order)
    self.order_type = order_type
    self.not_need_order = not_need_order
    self.default_gap = default_gap or 0
    self.element_table = {}
end

function WidgetAutoOrder:AddElement(element)
    assert(element.CheckVisible)
    assert(element.GetElementSize)
    self:Insert(element)
    element:addTo(self):pos(0,0):hide()
end
-- 刷新
function WidgetAutoOrder:RefreshOrder()
    local gap = 0
    for i,v in ipairs(self.element_table) do
        if not not_need_order then
            v:setVisible(v:CheckVisible())
            if self.order_type == WidgetAutoOrder.ORIENTATION.BOTTOM_TO_TOP then
                v:setPositionY(gap)
                gap = gap + v:GetElementSize().height/2 + self.default_gap
            elseif self.order_type == WidgetAutoOrder.ORIENTATION.TOP_TO_BOTTOM then
                v:setPositionY(gap)
                gap = gap - v:GetElementSize().height/2 - self.default_gap
            elseif self.order_type == WidgetAutoOrder.ORIENTATION.LEFT_TO_RIGHT then
                v:setPositionX(gap)
                gap = gap + v:GetElementSize().width/2 + self.default_gap
            elseif self.order_type == WidgetAutoOrder.ORIENTATION.RIGHT_TO_LEFT then
                v:setPositionX(gap)
                gap = gap - v:GetElementSize().width/2 - self.default_gap
            end
            if v.GetXY then
                v:setPosition(v.GetXY().x, v.GetXY().y)
            end
            if v.refrshCallback then
                v:refrshCallback()
            end
        else
            if v:CheckVisible() then
                if self.order_type == WidgetAutoOrder.ORIENTATION.BOTTOM_TO_TOP then
                    v:setPositionY(gap)
                    gap = gap + v:GetElementSize().height/2 + self.default_gap
                elseif self.order_type == WidgetAutoOrder.ORIENTATION.TOP_TO_BOTTOM then
                    v:setPositionY(gap)
                    gap = gap - v:GetElementSize().height/2 - self.default_gap
                elseif self.order_type == WidgetAutoOrder.ORIENTATION.LEFT_TO_RIGHT then
                    v:setPositionX(gap)
                    gap = gap + v:GetElementSize().width/2 + self.default_gap
                elseif self.order_type == WidgetAutoOrder.ORIENTATION.RIGHT_TO_LEFT then
                    v:setPositionX(gap)
                    gap = gap - v:GetElementSize().width/2 - self.default_gap
                end
                if v.GetXY then
                    v:setPosition(v.GetXY().x, v.GetXY().y)
                end
                v:show()
                if v.refrshCallback then
                    v:refrshCallback()
                end
            else
                v:hide()
            end
        end

    end
end
-- 私有方法
function WidgetAutoOrder:Insert(element)
    table.insert(self.element_table, element)
end
return WidgetAutoOrder



