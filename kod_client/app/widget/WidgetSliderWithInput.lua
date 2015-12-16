local WidgetSlider = import("..widget.WidgetSlider")
local WidgetPushButton = import("..widget.WidgetPushButton")
local WidgetInput = import("..widget.WidgetInput")
local Enum = import("..utils.Enum")

local WidgetSliderWithInput = class("WidgetSliderWithInput", function ( ... )
    return display.newNode(...)
end)
WidgetSliderWithInput.STYLE_LAYOUT = Enum("LEFT","RIGHT","TOP","BOTTOM")


function WidgetSliderWithInput:ctor(params)
    local max = params.max
    local min = params.min and max > 1 and params.min or 0
    local unit = params.unit or ""
    local bar = params.bar or "slider_bg_554x24.png"
    local progress = params.progress or "slider_progress_538x24.png"
    self.max = max
    self.unit = unit
    -- progress
    local slider_max
    if params.unit == "K" then
        slider_max = math.floor(max/1000)
    else
        slider_max = max
    end
    min = slider_max == 0 and 0 or min
    self.slider = WidgetSlider.new(display.LEFT_TO_RIGHT,  {bar = bar,
        progress = progress,
        button = "slider_btn_66x66.png"}, {max = slider_max,min = min,scale9=true}):addTo(self)
    local slider = self.slider


    local text_btn = WidgetPushButton.new({normal = "back_ground_83x32.png",pressed = "back_ground_83x32.png"})
        :onButtonClicked(function(event)
            if event.name == "CLICKED_EVENT" then
                local p = {
                    current = math.floor(slider:getSliderValue()),
                    max=max,
                    min=min,
                    unit=unit,
                    callback = function ( edit_value )
                        if edit_value ~= self:GetValue() then
                            slider.fsm_:doEvent("press")
                            slider:setSliderValue(edit_value)
                            slider.fsm_:doEvent("release")
                            if self.sliderReleaseEventListener then
                                self.sliderReleaseEventListener()
                            end
                        end
                    end
                }
                UIKit:newWidgetUI("WidgetInput",p):AddToCurrentScene()
            end
        end):align(display.CENTER, slider:getCascadeBoundingBox().size.width,30):addTo(self)



    self.btn_text = UIKit:ttfLabel({
        text = min,
        size = 22,
        color = 0x403c2f,
    }):addTo(text_btn):align(display.CENTER)
    self.text_btn = text_btn

    slider:onSliderValueChanged(function(event)
        local change_unit
        if self.unit == "K" then
            change_unit = 1000
        else
            change_unit = 1
        end
        local e_value = math.floor(event.value*change_unit)
        local btn_value
        local btn_unit  = ""
        if e_value>=1000 then
            local f_value = GameUtils:formatNumber(e_value)
            -- if change_unit == 1000 then
                btn_value = string.sub(f_value,1,-2)
                btn_unit = string.sub(f_value,-1,-1)
            -- else
            --     btn_value = string.sub(f_value,1,-2)
            -- end
        else
            btn_value = e_value
        end
        if btn_unit == "K" then
            self.btn_text:setString(math.floor(tonumber(btn_value)))
        else
            self.btn_text:setString(tonumber(btn_value))
        end
        self.soldier_total_count:setString(string.format(btn_unit.."/ %s", GameUtils:formatNumber(self.max)))
        if self.valueChangedFunc then
            self.valueChangedFunc(event)
        end
    end)

    local soldier_total_count = UIKit:ttfLabel({
        text = string.format(unit.."/ %s", GameUtils:formatNumber(max)),
        size = 20,
        color = 0x403c2f
    }):addTo(slider)
        :align(display.RIGHT_CENTER, slider:getCascadeBoundingBox().size.width,0)
    self:setContentSize(cc.size(slider:getCascadeBoundingBox().size.width,slider:getCascadeBoundingBox().size.height))
    self.soldier_total_count = soldier_total_count
    slider:setSliderValue(slider_max > 0 and (min < 1) and 1 or min)
end
function WidgetSliderWithInput:SetValue(value)
    self.slider:setSliderValue(value)
end
function WidgetSliderWithInput:GetValue()
    return tonumber(math.floor(self.slider:getSliderValue()))
end
function WidgetSliderWithInput:AddSliderReleaseEventListener(func)
    self.sliderReleaseEventListener = func
    self.slider:addSliderReleaseEventListener(function(event)
        func(event)
    end)
    return self
end
function WidgetSliderWithInput:OnSliderValueChanged(func)
    self.valueChangedFunc = func
    return self
end
function WidgetSliderWithInput:LayoutValueLabel(layout,offset)
    if WidgetSliderWithInput.STYLE_LAYOUT.TOP == layout then
        self.soldier_total_count:setPosition(self:getContentSize().width,offset)
        self.text_btn:setPosition(self:getContentSize().width-self.soldier_total_count:getContentSize().width-10-60,offset)
    else
        self.soldier_total_count:setPosition(self.slider.scale9Size_[1]+80 + offset,0)
        self.text_btn:setPosition(self.slider.scale9Size_[1]+60 + offset,30)
    end
    return self
end
function WidgetSliderWithInput:SetSliderSize(width, height)
    self.slider:setSliderSize(width, height)
    return self
end
function WidgetSliderWithInput:GetEditBoxPostion()
    return self.text_btn:getPosition()
end

return WidgetSliderWithInput













