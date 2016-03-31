local promise = import("..utils.promise")
local MOVE_EVENT = "MOVE_EVENT"
local UISlider = cc.ui.UISlider
local WidgetSlider = class("WidgetSlider", UISlider)
function WidgetSlider:ctor(direction, images, options)
    self.callbacks = {}
    WidgetSlider.super.ctor(self, direction, images, options)
    self:setTouchSwallowEnabled(false)

    if images.progress then
        local rect = self.barSprite_:getBoundingBox()
        self.progress = display.newProgressTimer(images.progress, display.PROGRESS_TIMER_BAR)
            :addTo(self, 1):align(display.CENTER, rect.x + rect.width/2, rect.y + rect.height/2)
        self.progress:setBarChangeRate(cc.p(1,0))
        self.progress:setMidpoint(cc.p(0,0))
        self.buttonSprite_:setLocalZOrder(2)
    end

end
function WidgetSlider:setSliderSize(width, height)
    local rect = self.barSprite_:getBoundingBox()

    local old_widht = rect.width 
    WidgetSlider.super.setSliderSize(self,width, height)
    self:updateButtonPosition_()
    self.progress:setScaleX(width*(self.progress:getContentSize().width/old_widht)/self.progress:getContentSize().width)
    local rect = self.barSprite_:getBoundingBox()
    self.progress:align(display.CENTER, rect.x + rect.width/2, rect.y + rect.height/2)

end
function WidgetSlider:SetMax( max )
    self.max_ = max
    return self
end
function WidgetSlider:SetMin( min )
    self.min_ = min
    return self
end
function WidgetSlider:onTouch_(event, x, y)
     if event == "began" then
        if not self:checkTouchInButton_(x, y) then return false end
        local posx, posy = self.buttonSprite_:getPosition()
        local buttonPosition = self:convertToWorldSpace(cc.p(posx, posy))
        self.buttonPositionOffset_.x = buttonPosition.x - x
        self.buttonPositionOffset_.y = buttonPosition.y - y
        self.fsm_:doEvent("press")
        self:dispatchEvent({name = UISlider.PRESSED_EVENT, x = x, y = y, touchInTarget = true})
        return true
    end

    local touchInTarget = self:checkTouchInButton_(x, y)
    x = x + self.buttonPositionOffset_.x
    y = y + self.buttonPositionOffset_.y
    local buttonPosition = self:convertToNodeSpace(cc.p(x, y))
    x = buttonPosition.x
    y = buttonPosition.y
    local offset = 0

    if self.isHorizontal_ then
        if x < self.buttonPositionRange_.min then
            x = self.buttonPositionRange_.min
        elseif x > self.buttonPositionRange_.max then
            x = self.buttonPositionRange_.max
        end
        if self.direction_ == display.LEFT_TO_RIGHT then
            offset = (x - self.buttonPositionRange_.min) / self.buttonPositionRange_.length
        else
            offset = (self.buttonPositionRange_.max - x) / self.buttonPositionRange_.length
        end
    else
        if y < self.buttonPositionRange_.min then
            y = self.buttonPositionRange_.min
        elseif y > self.buttonPositionRange_.max then
            y = self.buttonPositionRange_.max
        end
        if self.direction_ == display.TOP_TO_BOTTOM then
            offset = (self.buttonPositionRange_.max - y) / self.buttonPositionRange_.length
        else
            offset = (y - self.buttonPositionRange_.min) / self.buttonPositionRange_.length
        end
    end
    if self.dynamic_cb then
        local value = self.dynamic_cb(offset * (self.max_ - self.min_) + self.min_)
        local final_value = tolua.type(value) == "number" and value or offset * (self.max_ - self.min_) + self.min_
        self:setSliderValue(final_value)
    else
        self:setSliderValue(offset * (self.max_ - self.min_) + self.min_)
    end

    if event ~= "moved" and self.fsm_:canDoEvent("release") then
        self.fsm_:doEvent("release")
        self:dispatchEvent({name = UISlider.RELEASE_EVENT, x = x, y = y, touchInTarget = touchInTarget})
    end
end
-- 是否达到动态最大值
function WidgetSlider:setDynamicMaxCallBakc(cb)
    self.dynamic_cb = cb
    return self
end
function WidgetSlider:align(align, x, y)
    WidgetSlider.super.align(self,align, x, y)
    self.progress:align(align)
end
function WidgetSlider:onSliderValueChanged(callback)
    return WidgetSlider.super.onSliderValueChanged(self, function(event)
        local percent = math.floor((event.value- self.min_)/ (self.max_ - self.min_) * 100)
        if self.progress then
            self.progress:setPercentage(percent ~= percent and 0 or percent)
        end
        callback(event)
        self:CheckProgress(percent)
    end)
end
function WidgetSlider:Max(max)
    self.max_ = max
    self:updateButtonPosition_()
    self:dispatchEvent({name = UISlider.VALUE_CHANGED_EVENT, value = self.value_})
    return self
end
function WidgetSlider:Min(min)
    self.min_ = min
    self:updateButtonPosition_()
    self:dispatchEvent({name = UISlider.VALUE_CHANGED_EVENT, value = self.value_})
    return self
end
function WidgetSlider:align(...)
    WidgetSlider.super.align(self, ...)
    local rect = self.barSprite_:getBoundingBox()
    self.progress:align(display.CENTER, rect.x + rect.width/2, rect.y + rect.height/2)
    return self
end
function WidgetSlider:CheckProgress(progress)
    local callbacks = self.callbacks
    if #callbacks > 0 and callbacks[1](progress) then
        table.remove(callbacks, 1)
    end
end
function WidgetSlider:PromiseOfProgress(percent)
    local callbacks = self.callbacks
    assert(#callbacks == 0)
    local p = promise.new()
    table.insert(callbacks, function(val)
        if percent == val then
            self.onTouch_ = function() end
            p:resolve(self)
            return true
        end
    end)
    return p
end


return WidgetSlider








