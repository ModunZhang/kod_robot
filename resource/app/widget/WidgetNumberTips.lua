local WidgetNumberTips = class("WidgetNumberTips", function()
    return display.newSprite("back_ground_32x33.png")
end)

function WidgetNumberTips:ctor()
    local size = self:getContentSize()
    self.label = UIKit:ttfLabel({
        size = 14,
        color = 0xf5e8c4,
        shadow = true
    }):align(display.CENTER, size.width/2-2, size.height/2+4):addTo(self)
end

function WidgetNumberTips:SetNumber(number)
    number = number or 0
    if number > 0 then
        self.label:setString(number > 99 and "99+" or number)
        self:show()
    else
        self:hide()
    end
    return self
end





return WidgetNumberTips




