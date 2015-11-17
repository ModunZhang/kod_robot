--
-- Author: Kenny Dai
-- Date: 2015-07-09 10:04:46
--
local WidgetPopDialog = import(".WidgetPopDialog")
local WidgetSliderWithInput = import(".WidgetSliderWithInput")
local WidgetPushButton = import(".WidgetPushButton")
local Localize_item = import("..utils.Localize_item")
local WidgetUseMutiItems = class("WidgetUseMutiItems", WidgetPopDialog)

function WidgetUseMutiItems:ctor(item_name)
    WidgetUseMutiItems.super.ctor(self,282,Localize_item.item_name[item_name],display.top-298)

    local body = self:GetBody()
    local body_size = body:getContentSize()
    -- 滑动条部分
    local slider_bg = display.newSprite("back_ground_580x136.png"):addTo(body)
        :align(display.CENTER_TOP,body_size.width/2,body_size.height-30)
    -- title
    UIKit:ttfLabel(
        {
            text = _("使用数量"),
            size = 22,
            color = 0x403c2f,
        }):align(display.LEFT_TOP, 20 ,slider_bg:getContentSize().height-15)
        :addTo(slider_bg)

    -- slider
    
    local slider = WidgetSliderWithInput.new({max = User:GetItemCount(item_name)})
        :addTo(slider_bg)
        :align(display.CENTER, slider_bg:getContentSize().width/2,  65)
        :OnSliderValueChanged(function(event)
            local value = math.floor(event.value)
            self.button:setButtonEnabled(value ~= 0)
        end)
        :LayoutValueLabel(WidgetSliderWithInput.STYLE_LAYOUT.TOP,75)
    --奖赏按钮
    local button = WidgetPushButton.new({normal = "yellow_btn_up_186x66.png",pressed = "yellow_btn_down_186x66.png",disabled = "grey_btn_186x66.png"})
        :setButtonLabel(UIKit:ttfLabel({
            text = _("确定"),
            size = 24,
            color = 0xffedae,
            shadow= true
        }))
        :onButtonClicked(function(event)
            if event.name == "CLICKED_EVENT" then
                NetManager:getUseItemPromise(item_name,{
                    [item_name] = {count = slider:GetValue()}
                }):done(function ()
                    self:LeftButtonClicked()
                end)
            end
        end):align(display.BOTTOM_CENTER, body_size.width/2,30):addTo(body)
    button:setButtonEnabled(slider:GetValue() ~= 0)
    self.button = button
    slider:SetValue(User:GetItemCount(item_name))
end

return WidgetUseMutiItems


