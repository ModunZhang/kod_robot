
local WidgetTimeBar = class("WidgetTimeBar", function(...)
    return display.newNode(...)
end)
function WidgetTimeBar:ctor(label_color, bg, bar, params)
    params = params or { }
    params.has_icon = params.has_icon == nil and true or false
    params.has_bg = params.has_bg == nil and true or false
    local bar_pos = params.bar_pos or {x = -4, y = 1}
    local progress_bg = cc.ui.UIImage.new(bg or "progress_bar_364x40_1.png")
        :addTo(self):align(display.LEFT_BOTTOM)
    
    self.progress_label = cc.ui.UILabel.new({
        text = "",
        size = params.label_size or 18,
        font = UIKit:getFontFilePath(),
        align = cc.ui.TEXT_ALIGN_RIGHT,
        color = label_color or UIKit:hex2c3b(0x007c23)
    }):addTo(progress_bg):align(display.CENTER, progress_bg:getContentSize().width/2, progress_bg:getContentSize().height/2)

    if params.has_icon then
        local icon_bg = cc.ui.UIImage.new(params.icon_bg or "back_ground_43x43.png")
            :addTo(progress_bg, 2):align(display.CENTER, 0, progress_bg:getContentSize().height/2)
        local pos = icon_bg:getAnchorPointInPoints()
        cc.ui.UIImage.new(params.icon or "hourglass_30x38.png"):addTo(icon_bg):align(display.CENTER, pos.x, pos.y):scale(0.8)
    end

    progress_bg:opacity(params.has_bg and 255 or 0)

    self.back_ground = progress_bg
end
function WidgetTimeBar:SetProgressInfo(time_label, percent)
    if self.progress_label:getString() ~= time_label then
        self.progress_label:setString(time_label)
    end
    return self
end
function WidgetTimeBar:align(anchorPoint, x, y)
    self.back_ground:align(anchorPoint)
    if x and y then self:setPosition(x, y) end
    return self
end

return WidgetTimeBar