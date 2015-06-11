
--[[

Copyright (c) 2011-2014 chukong-inc.com

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

]]

--[[--

quick CheckButton控件

]]

local UIButton = import(".UIButton")
local UICheckBoxButton = class("UICheckBoxButton", UIButton)
local MOVE_EVENT = "MOVE_EVENT"
UICheckBoxButton.OFF          = "off"
UICheckBoxButton.OFF_PRESSED  = "off_pressed"
UICheckBoxButton.OFF_DISABLED = "off_disabled"
UICheckBoxButton.ON           = "on"
UICheckBoxButton.ON_PRESSED   = "on_pressed"
UICheckBoxButton.ON_DISABLED  = "on_disabled"

--[[--

UICheckBoxButton构建函数

@param table images checkButton各种状态的图片表
@param table options 参数表

]]
function UICheckBoxButton:ctor(images, options)
    UICheckBoxButton.super.ctor(self, {
        {name = "disable",  from = {"off", "off_pressed"}, to = "off_disabled"},
        {name = "disable",  from = {"on", "on_pressed"},   to = "on_disabled"},
        {name = "enable",   from = {"off_disabled"}, to = "off"},
        {name = "enable",   from = {"on_disabled"},  to = "on"},
        {name = "press",    from = "off", to = "off_pressed"},
        {name = "press",    from = "on",  to = "on_pressed"},
        {name = "release",  from = "off_pressed", to = "off"},
        {name = "release",  from = "on_pressed", to = "on"},
        {name = "select",   from = "off", to = "on"},
        {name = "select",   from = "off_disabled", to = "on_disabled"},
        {name = "unselect", from = "on", to = "off"},
        {name = "unselect", from = "on_disabled", to = "off_disabled"},
    }, "off", options)
    self:setButtonImage(UICheckBoxButton.OFF, images["off"], true)
    self:setButtonImage(UICheckBoxButton.OFF_PRESSED, images["off_pressed"], true)
    self:setButtonImage(UICheckBoxButton.OFF_DISABLED, images["off_disabled"], true)
    self:setButtonImage(UICheckBoxButton.ON, images["on"], true)
    self:setButtonImage(UICheckBoxButton.ON_PRESSED, images["on_pressed"], true)
    self:setButtonImage(UICheckBoxButton.ON_DISABLED, images["on_disabled"], true)
    self.labelAlign_ = display.LEFT_CENTER
    self.pre_pos = nil
    self:setTouchSwallowEnabled(false)
    self:RebindEventListener()
end


function UICheckBoxButton:RebindEventListener()
    self:onButtonPressed(function(event)
        self.pre_pos = event.target:convertToWorldSpace(cc.p(event.target:getPosition()))
    end)
    self:addEventListener(MOVE_EVENT, function(event)
        local cur_pos = event.target:convertToWorldSpace(cc.p(event.target:getPosition()))
        if event.touchInTarget and cc.pGetDistance(cur_pos, self.pre_pos) > 10 then
            if event.target.fsm_:canDoEvent("release") then
                event.target.fsm_:doEvent("release")
            end
        end
    end)
    return self
end

--[[--

设置单个状态的图片

@param string state checkButton状态
@param string image 图片路径
@param boolean ignoreEmpty 忽略image为nil

@return UICheckBoxButton 自身

]]
function UICheckBoxButton:setButtonImage(state, image, ignoreEmpty)
    assert(state == UICheckBoxButton.OFF
        or state == UICheckBoxButton.OFF_PRESSED
        or state == UICheckBoxButton.OFF_DISABLED
        or state == UICheckBoxButton.ON
        or state == UICheckBoxButton.ON_PRESSED
        or state == UICheckBoxButton.ON_DISABLED,
        string.format("UICheckBoxButton:setButtonImage() - invalid state %s", tostring(state)))
    UICheckBoxButton.super.setButtonImage(self, state, image, ignoreEmpty)
    if state == UICheckBoxButton.OFF then
        if not self.images_[UICheckBoxButton.OFF_PRESSED] then
            self.images_[UICheckBoxButton.OFF_PRESSED] = image
        end
        if not self.images_[UICheckBoxButton.OFF_DISABLED] then
            self.images_[UICheckBoxButton.OFF_DISABLED] = image
        end
    elseif state == UICheckBoxButton.ON then
        if not self.images_[UICheckBoxButton.ON_PRESSED] then
            self.images_[UICheckBoxButton.ON_PRESSED] = image
        end
        if not self.images_[UICheckBoxButton.ON_DISABLED] then
            self.images_[UICheckBoxButton.ON_DISABLED] = image
        end
    end

    return self
end

--[[--

是否选中状态

@return boolean 选中与否

]]
function UICheckBoxButton:isButtonSelected()
    return self.fsm_:canDoEvent("unselect")
end


--[[--

设置选中状态

@param boolean selected 选中与否

@return UICheckBoxButton 自身

]]
function UICheckBoxButton:setButtonSelected(selected,do_not_call_cb)
    if self:isButtonSelected() ~= selected then
        if selected then
            self.fsm_:doEventForce("select")
        else
            self.fsm_:doEventForce("unselect")
        end
        if not do_not_call_cb then
            self:dispatchEvent({name = UIButton.STATE_CHANGED_EVENT, state = self.fsm_:getState()})
        end
    end
    return self
end


function UICheckBoxButton:onTouch_(event)
    local name, x, y = event.name, event.x, event.y
    if name == "began" then
        self.touchBeganX = x
        self.touchBeganY = y
        if not self:checkTouchInSprite_(x, y) then return false end
        self.fsm_:doEvent("press")
        self:dispatchEvent({name = UIButton.PRESSED_EVENT, x = x, y = y, touchInTarget = true})
        return true
    end

    local touchInTarget = self:checkTouchInSprite_(x, y) and self:checkTouchInSprite_(self.touchBeganX, self.touchBeganY)
    if name == "moved" then
        if touchInTarget then
            self:dispatchEvent({name = MOVE_EVENT, x = x, y = y, touchInTarget = true})
        elseif  not touchInTarget and self.fsm_:canDoEvent("release") then
            self.fsm_:doEvent("release")
            self:dispatchEvent({name = UIButton.RELEASE_EVENT, x = x, y = y, touchInTarget = false})
        end
        -- if touchInTarget and self.fsm_:canDoEvent("press") then
        --     self.fsm_:doEvent("press")
        --     self:dispatchEvent({name = UIButton.PRESSED_EVENT, x = x, y = y, touchInTarget = true})
        -- elseif not touchInTarget and self.fsm_:canDoEvent("release") then
        --     self.fsm_:doEvent("release")
        --     self:dispatchEvent({name = UIButton.RELEASE_EVENT, x = x, y = y, touchInTarget = false})
        -- end
    else
        if self.fsm_:canDoEvent("release") then
            self.fsm_:doEvent("release")
            self:dispatchEvent({name = UIButton.RELEASE_EVENT, x = x, y = y, touchInTarget = touchInTarget})
        end
        if name == "ended" and touchInTarget then
            self:setButtonSelected(self.fsm_:canDoEvent("select"))
            self:dispatchEvent({name = UIButton.CLICKED_EVENT, x = x, y = y, touchInTarget = true})
        end
    end
end

function UICheckBoxButton:getDefaultState_()
    local state = self.fsm_:getState()
    if state == UICheckBoxButton.ON or state == UICheckBoxButton.ON_DISABLED or state == UICheckBoxButton.ON_PRESSED then
        return {UICheckBoxButton.ON, UICheckBoxButton.OFF}
    else
        return {UICheckBoxButton.OFF, UICheckBoxButton.ON}
    end
end

return UICheckBoxButton
