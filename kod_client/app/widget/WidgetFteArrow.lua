local WidgetFteArrow = class("WidgetFteArrow", function()
    return display.newNode()
end)



function WidgetFteArrow:OnPositionChanged(x, y, tx, ty)
    local rx, ry = tx or x, ty or y
    local p = self:getParent():convertToNodeSpace(cc.p(rx, ry))
    self:pos(p.x, p.y)
end

function WidgetFteArrow:ctor(text, size)
    self.back = display.newScale9Sprite("fte_label_background.png"):addTo(self)
    local s = self.back:getContentSize()
    self.label = UIKit:ttfLabel({
        text = text or "",
        size = size or 22,
        color = 0xffedae,
        align = cc.TEXT_ALIGNMENT_CENTER,
    }):addTo(self.back)
    self.label:setMaxLineWidth(s.width-80)
    local s1 = self.label:getContentSize()
    
    local min = math.max(math.min(s1.width, s.width), s.width*0.6)
    local width = s1.width > (s.width - 50) and (s1.width + 50) or min + 50

    local height = s1.height > s.height and s1.height or s.height
    self.back:setContentSize(cc.size(width, height + (self.label:getStringNumLines() > 1 and 20 or 0)))

    local s = self.back:getContentSize()
    self.label:align(display.CENTER, s.width/2, s.height/2)
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
function WidgetFteArrow:TurnDown(stay_right)
    local offset_x, offset_y = 0, 0
    local s = self.back:getContentSize()
    local s1 = self.arrow:getContentSize()
    if stay_right == nil then
    elseif stay_right == false then
        offset_x = s1.width/2 - s.width/2
    elseif stay_right == true then
        offset_x = s.width/2 - s1.width/2
    end

    self.arrow:align(display.TOP_CENTER, s.width/2 + offset_x, 10)
    self.arrow:rotation(0)

    self.back:stopAllActions()
    self.back:runAction(cc.RepeatForever:create(transition.sequence{
        cc.MoveBy:create(0.4, cc.p(0, 5)),
        cc.MoveBy:create(0.4, cc.p(0, -5))
    }))
    return self
end
function WidgetFteArrow:TurnUp(stay_right)
    local offset_x, offset_y = 0, 0
    local s = self.back:getContentSize()
    local s1 = self.arrow:getContentSize()
    if stay_right == nil then
    elseif stay_right == false then
        offset_x = s1.width/2 - s.width/2
    elseif stay_right == true then
        offset_x = s.width/2 - s1.width/2
    end
    self.arrow:align(display.TOP_CENTER, s.width/2 + offset_x, s.height - 10 + offset_y)
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

