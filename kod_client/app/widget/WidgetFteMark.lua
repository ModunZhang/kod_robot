local WidgetFteMark = class("WidgetFteMark", function()
    return display.newScale9Sprite("pve_mark_box.png")
end)



function WidgetFteMark:ctor()
    self:runAction(cc.RepeatForever:create(transition.sequence{
        cc.ScaleTo:create(0.5, 1.02),
        cc.ScaleTo:create(0.5, 1)
    }))
    self.origin_size = self:getContentSize()
end
function WidgetFteMark:Size(w, h)
    -- w = math.max(w, self.origin_size.width)
    h = math.max(h, self.origin_size.height)
    return self:size(w, h)
end




return WidgetFteMark

