local promise = import("..utils.promise")
local WidgetTab = import(".WidgetTab")
local WidgetNumberTips = import(".WidgetNumberTips")
local WidgetBackGroundTabButtons = class("WidgetBackGroundTabButtons", function()
    return display.newNode()
end)

function WidgetBackGroundTabButtons:ctor(buttons, listener)
    self.callbacks = {}
    self.tabListener = listener
    local width = 578
    local node = display.newNode():addTo(self)
    self.node = node

    local unit_width = width / #buttons
    self.unit_width = unit_width
    local origin_x = - width / 2
    local tabs = {}
    local default
    for i, v in ipairs(buttons) do
        local widget = WidgetTab.new({
            on = "tab_btn_up_140x60.png", 
            off = "tab_btn_down_140x60.png",
        }, unit_width, 60)
            :addTo(node)
            :align(display.LEFT_CENTER, origin_x + unit_width * (i - 1), 18)
            :OnTabPress(handler(self, self.OnTabClicked))

        widget.tag = v.tag
        widget.label = UIKit:ttfLabel({text = v.label, size = 22, color = 0xa0956e,shadow=true})
            :addTo(widget)
            :align(display.CENTER, unit_width/2, 0)
        if v.default then
            default = widget
        end
        table.insert(tabs, widget)
    end
    self.tabs = tabs

    if default then
        self:PushButton(default)
    end
end
function WidgetBackGroundTabButtons:SelectTab(tag)
    for _, tab in pairs(self.tabs) do
        if tab.tag == tag then
            self:PushButton(tab)
            return
        end
    end
end
function WidgetBackGroundTabButtons:PushButton(tab)
    for _, v in pairs(self.tabs) do
        if v ~= tab then
            v:Enable(true):Active(false)
            v.label:setColor(UIKit:hex2c3b(0xffedae))
        else
            v:Enable(false):Active(true)
            v.label:setColor(UIKit:hex2c3b(0x00c0ff))
        end
    end
    self:OnSelectTag(tab.tag)
end
function WidgetBackGroundTabButtons:OnTabClicked(widget, is_pressed)
    self:PushButton(widget)
end
function WidgetBackGroundTabButtons:OnSelectTag(tag)
    if type(self.tabListener) == "function" then
        self.tabListener(tag)
    end
    self:CheckTag(tag)
end

function WidgetBackGroundTabButtons:GetSelectedButtonTag()
    for _, v in pairs(self.tabs) do
        if v.pressed then
            return v.tag
        end
    end
end
function WidgetBackGroundTabButtons:GetTabByTag(tag)
    for _, v in pairs(self.tabs) do
        if v.tag == tag then
            return v
        end
    end
    return nil
end
function WidgetBackGroundTabButtons:CheckTag(tag)
    local callbacks = self.callbacks
    if #callbacks > 0 and callbacks[1](tag) then
        table.remove(callbacks, 1)
    end
end
function WidgetBackGroundTabButtons:PromiseOfTag(tag)
    local callbacks = self.callbacks
    assert(#callbacks == 0)
    local p = promise.new()
    table.insert(callbacks, function(tag_)
        if tag == tag_ then
            p:resolve()
            return true
        end
    end)
    return p
end

function WidgetBackGroundTabButtons:SetButtonTipNumber(tab_tag,number)
    local tab = self:GetTabByTag(tab_tag)
    if not tab then return end
    if not tab.tip_numbers then
        tab.tip_numbers = WidgetNumberTips.new():addTo(tab):align(display.RIGHT_CENTER, self.unit_width + 2,25)
    end
    tab.tip_numbers:SetNumber(number)
end
--这里坐标写死了 只有日常任务使用
function WidgetBackGroundTabButtons:SetGreenTipsShow(tab_tag,visible)
    local tab = self:GetTabByTag(tab_tag)
    if not tab then return end
     if not tab.tips_green then
        tab.tips_green = display.newSprite("green_tips_icon_22x22.png"):addTo(tab):align(display.RIGHT_CENTER, self.unit_width + 10,25)
    end
    tab.tips_green:setVisible(visible)
end

return WidgetBackGroundTabButtons


