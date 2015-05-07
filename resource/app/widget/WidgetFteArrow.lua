local WidgetFteArrow = class("WidgetFteArrow", function()
    return display.newNode()
end)



function WidgetFteArrow:OnPositionChanged(x, y, tx, ty)
    local p = self:getParent():convertToNodeSpace(cc.p(tx, ty))
    self:pos(p.x, p.y)
end

function WidgetFteArrow:ctor(text)
    self.back = display.newSprite("fte_label_background.png"):addTo(self)
    local s = self.back:getContentSize()
    self.label = UIKit:ttfLabel({
        text = text or "",
        size = 22,
        color = 0xffedae,
    }):addTo(self.back):align(display.CENTER, s.width/2, s.height/2)
    self.arrow = display.newSprite("fte_icon_arrow.png"):addTo(self.back)
end
function WidgetFteArrow:TurnLeft()
    local s = self.back:getContentSize()
    self.arrow:align(display.TOP_CENTER, 10, s.height/2)
    self.arrow:rotation(90)

    self.back:stopAllActions()
    self.back:runAction(cc.RepeatForever:create(transition.sequence{
        cc.MoveBy:create(0.4, cc.p(5, 0)),
        cc.MoveBy:create(0.4, cc.p(-5, 0))
    }))
    return self
end
function WidgetFteArrow:TurnRight()
    local s = self.back:getContentSize()
    self.arrow:align(display.TOP_CENTER, s.width - 10, s.height/2)
    self.arrow:rotation(-90)

    self.back:stopAllActions()
    self.back:runAction(cc.RepeatForever:create(transition.sequence{
        cc.MoveBy:create(0.4, cc.p(-5, 0)),
        cc.MoveBy:create(0.4, cc.p(5, 0))
    }))

    return self
end
function WidgetFteArrow:TurnDown()
    local s = self.back:getContentSize()
    self.arrow:align(display.TOP_CENTER, s.width/2, 10)
    self.arrow:rotation(0)

    self.back:stopAllActions()
    self.back:runAction(cc.RepeatForever:create(transition.sequence{
        cc.MoveBy:create(0.4, cc.p(0, 5)),
        cc.MoveBy:create(0.4, cc.p(0, -5))
    }))
    return self
end
function WidgetFteArrow:TurnUp()
    local s = self.back:getContentSize()
    self.arrow:align(display.TOP_CENTER, s.width/2, s.height - 10)
    self.arrow:rotation(180)

    self.back:stopAllActions()
    self.back:runAction(cc.RepeatForever:create(transition.sequence{
        cc.MoveBy:create(0.4, cc.p(0, -5)),
        cc.MoveBy:create(0.4, cc.p(0, 5))
    }))
    return self
end
function WidgetFteArrow:align(anchorPoint, x, y)
    self.back:align(anchorPoint, x, y)
    return self
end

return WidgetFteArrow

