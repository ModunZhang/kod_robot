local WidgetProgress = class("WidgetProgress", function(...)
    return display.newNode(...)
end)
function WidgetProgress:ctor(label_color, bg, bar, params)
    params = params or { }
    params.has_icon = params.has_icon == nil and true or false
    params.has_bg = params.has_bg == nil and true or false
    local bar_pos = params.bar_pos or {x = -4, y = 1}
    local progress_bg = cc.ui.UIImage.new(bg or "progress_bar_364x40_1.png")
        :addTo(self):align(display.LEFT_BOTTOM)
    self.progress_timer = display.newProgressTimer(bar or "progress_bar_364x40_2.png", display.PROGRESS_TIMER_BAR)
        :align(display.LEFT_BOTTOM, 0, 0):addTo(progress_bg):pos(bar_pos.x, bar_pos.y)
    self.progress_timer:setBarChangeRate(cc.p(1,0))
    self.progress_timer:setMidpoint(cc.p(0,0))

    local size = self.progress_timer:getContentSize()
    self.progress_label = cc.ui.UILabel.new({
        text = "",
        size = params.label_size or 18,
        font = UIKit:getFontFilePath(),
        align = cc.ui.TEXT_ALIGN_RIGHT,
        color = label_color or UIKit:hex2c3b(0xfdfac2)
    }):addTo(self.progress_timer):align(display.LEFT_CENTER, 35, size.height / 2)

    if params.has_icon then
        local icon_bg = cc.ui.UIImage.new(params.icon_bg or "back_ground_43x43.png")
            :addTo(progress_bg, 2):align(display.CENTER, 0, progress_bg:getContentSize().height/2)
        local pos = icon_bg:getAnchorPointInPoints()
        cc.ui.UIImage.new(params.icon or "hourglass_30x38.png"):addTo(icon_bg):align(display.CENTER, pos.x, pos.y):scale(0.8)
    end

    progress_bg:opacity(params.has_bg and 255 or 0)

    self.back_ground = progress_bg
end
function WidgetProgress:SetProgressInfo(time_label, percent)
    self.progress_label:setString(time_label)
    self.progress_timer:setPercentage(percent)
    return self
end
function WidgetProgress:align(anchorPoint, x, y)
    self.back_ground:align(anchorPoint)
    if x and y then self:setPosition(x, y) end
    return self
end
-- function WidgetProgress:Performance(time, onUpdate, onComplete)
--     if self.update_handle then
--         self:unscheduleUpdate()
--         self:removeNodeEventListener(self.update_handle)
--     end
--     local t = 0
--     self.update_handle = self:addNodeEventListener(cc.NODE_ENTER_FRAME_EVENT, function(dt)
--         t = t + dt
--         if t > time then
--             t = time
--             if type(onComplete) == "function" then
--                 onComplete()
--             end
--             self:unscheduleUpdate()
--         end
--         if type(onUpdate) == "function" then
--             onUpdate(t / time)
--         end
--     end)
--     self:scheduleUpdate()
--     return self
-- end



return WidgetProgress










