local WidgetLight = class("WidgetLight", function()
    return display.newNode()
end)


function WidgetLight:ctor()
    local time = 2
    display.newSprite("light.png"):addTo(self)
        :runAction(cc.RepeatForever:create(transition.sequence({
            cc.RotateTo:create(time, 180),
            cc.RotateTo:create(time, 360),
        })))
    display.newSprite("light.png"):addTo(self)
        :runAction(cc.RepeatForever:create(transition.sequence({
            cc.RotateTo:create(time, -180),
            cc.RotateTo:create(time, -360),
        })))
end


return WidgetLight
