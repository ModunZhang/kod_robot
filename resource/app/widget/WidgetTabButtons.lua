local WidgetTabButtons = class("WidgetTabButtons", function()
    return display.newNode()
end)


local origin_x = 20
local origin_y = 20
function WidgetTabButtons:ctor(buttons, tab_param, listener)
    local count = #buttons
    local tab_param = tab_param ~= nil and tab_param or {}
    local scale_on_height = display.height / 960
    local gap = tab_param.gap ~= nil and tab_param.gap or 0
    local margin_left = tab_param.margin_left ~= nil and tab_param.margin_left or 0
    local margin_right = tab_param.margin_right ~= nil and tab_param.margin_right or 0
    local margin_up = tab_param.margin_up ~= nil and tab_param.margin_up * (tab_param.margin_up >= 0 and scale_on_height or 1 / scale_on_height) or 0
    local margin_down = tab_param.margin_down ~= nil and tab_param.margin_down * (tab_param.margin_down >= 0 and scale_on_height or 1 / scale_on_height) or 0
    self.tabListener = listener

    self.buttons = {}

    local tab_bg = cc.ui.UIImage.new("tab_bg_550x61.png", {scale9 = true})
        :addTo(self)
        :align(display.CENTER, 0, 0)
    tab_bg:setCapInsets(cc.rect(origin_x, origin_y, tab_bg:getContentSize().width - origin_x * 2, tab_bg:getContentSize().height - origin_y * 2))
    tab_bg:setContentSize(cc.size(tab_bg:getContentSize().width, tab_bg:getContentSize().height))

    local unit_len = tab_bg:getContentSize().width / count
    local unit_height = tab_bg:getContentSize().height
    local height = unit_height - margin_up - margin_down
    local y = - margin_up / 2 + margin_down / 2 + unit_height / 2
    for i = 1, count do
        local tag = buttons[i].tag
        local label = buttons[i].label
        local is_default = buttons[i].default
        local x = unit_len/2 + unit_len * (i - 1)
        local width
        local button
        if i == 1 then
            x = x - gap/2 + margin_left
            width = unit_len - gap/2 - margin_left
            button = cc.ui.UIPushButton.new(
                {normal = "tab_right_279x63.png"},
                {scale9 = true})
                :addTo(tab_bg, 100)
            button:setScaleX(-1)
            for i, v in ipairs(button.sprite_) do
                v:setCapInsets(cc.rect(origin_x, origin_y, 279 - origin_x * 2, 63 - origin_y * 2))
            end
        elseif i == count then
            x = x + gap/2 - margin_right
            width = unit_len - gap/2 - margin_right
            button = cc.ui.UIPushButton.new(
                {normal = "tab_right_279x63.png"},
                {scale9 = true})
                :addTo(tab_bg, 100)
            for i, v in ipairs(button.sprite_) do
                v:setCapInsets(cc.rect(origin_x, origin_y, 279 - origin_x * 2, 63 - origin_y * 2))
            end
        else
            width = unit_len - gap
            button = cc.ui.UIPushButton.new(
                {normal = "tab_middle_188x64.png"},
                {scale9 = true})
                :addTo(tab_bg, 100)
        end
        button:setButtonSize(width, height)
        button:pos(x, y)
        button.tag = tag


        button.label = cc.ui.UILabel.new({text = label, size = 22, color = display.COLOR_BLACK})
            :addTo(tab_bg, 101)
            :align(display.CENTER, x, y)

        table.insert(self.buttons, button)

        button:onButtonPressed(function(event)
            self:PushButton(event.target)
        end)
        if is_default then
            self:PushButton(button)
        end
    end
end
function WidgetTabButtons:SelectByTag(tag)
    for _, button in pairs(self.buttons) do
        if button.tag == tag then
            self:PushButton(button)
            return
        end
    end
end
function WidgetTabButtons:PushButton(button)
    if self.push_button == button then
        return
    end
    if self.push_button then
        self.push_button:setVisible(true)
        self.push_button.label:setColor(UIKit:hex2c3b(0x1f1d17))
    end
    button:setVisible(false)
    button.label:setColor(UIKit:hex2c3b(0xfff3c7))
    self.push_button = button
    if type(self.tabListener) == "function" then
        self.tabListener(self.push_button.tag)
    end
end

function WidgetTabButtons:GetSelectedButtonTag()
    return self.push_button.tag or ""
end

return WidgetTabButtons







