local WidgetNumberTips = class("WidgetNumberTips", function()
    return display.newSprite("back_ground_32x33.png")
end)

function WidgetNumberTips:ctor()
    local size = self:getContentSize()
    self.label = UIKit:CreateNumberImageNode({
        size = 16,
        color = 0xf5e8c4,
    }):align(display.CENTER, size.width/2-2, size.height/2+2):addTo(self)
    
end

function WidgetNumberTips:SetNumber(number)
    number = number or 0
    if number > 0 then
        self.label:SetNumString(number > 99 and "99+" or number)
        self:show()
    else
        self:hide()
    end
    return self
end


function WidgetNumberTips:DisplayBlank(yesOrno)
    if yesOrno then
        self.label:SetNumString("")
        self:show()
    else
        self:hide()
    end
end



return WidgetNumberTips




