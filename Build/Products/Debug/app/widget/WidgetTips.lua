local WidgetUIBackGround = import(".WidgetUIBackGround")
local WidgetTips = class("WidgetTips", function()
    return display.newNode()
end)


function WidgetTips:ctor(head, body)
    self.back_ground = WidgetUIBackGround.new({width=556,height = 106},WidgetUIBackGround.STYLE_TYPE.STYLE_5)
        :addTo(self)


    local align_x = 556/2
    self.head = cc.ui.UILabel.new({
        size = 24,
        font = UIKit:getFontFilePath(),
        align = cc.ui.TEXT_ALIGN_LEFT,
        color = UIKit:hex2c3b(0x403c2f)
    }):addTo(self.back_ground, 2):align(display.CENTER_BOTTOM, align_x, 60)

    self.body = cc.ui.UILabel.new({
        size = 22,
        font = UIKit:getFontFilePath(),
        align = cc.ui.TEXT_ALIGN_LEFT,
        color = UIKit:hex2c3b(0x403c2f)
    }):addTo(self.back_ground, 2):align(display.CENTER_BOTTOM, align_x, 20)

    self:Title(head, body)
end
function WidgetTips:Title(head, body)
    self.head:setString(head)
    self.body:setString(body)
    return self
end
function WidgetTips:Size(width, height)
    self.back_ground:setLayoutSize(width, height)
    return self
end
function WidgetTips:align(anchorPoint, x, y)
    self.back_ground:align(anchorPoint)
    if x and y then self:setPosition(x, y) end
    return self
end


return WidgetTips





