--[[ 
    能控制点击事件回调的CheckBoxButtonGroup,
    必须配合自定义的UICheckBoxButton使用。
]]--
local UICheckBoxButton = import(".UICheckBoxButton")
local UICheckBoxButtonGroup = cc.ui.UICheckBoxButtonGroup
local UICanCanelCheckBoxButtonGroup = class("UICanCanelCheckBoxButtonGroup",UICheckBoxButtonGroup)

function UICanCanelCheckBoxButtonGroup:addButton(button)
    self:addChild(button)
    self.buttons_[#self.buttons_ + 1] = button
    self:getLayout():addWidget(button):apply(self)
    button:onButtonClicked(handler(self, self.onButtonStateChanged_))
    if button:isButtonSelected() then 
        self:updateButtonState_(button)
    end
    return self
end

function UICanCanelCheckBoxButtonGroup:updateButtonState_(clickedButton)
    if self.check_func then
        local currentSelectedIndex = 0
        for index, button in ipairs(self.buttons_) do
            if button == clickedButton then
                currentSelectedIndex = index
            end
        end
        if not self.check_func(self,currentSelectedIndex,self.currentSelectedIndex_) then
            clickedButton:setButtonSelected(false, true) 
            if self.currentSelectedIndex_ then 
                self.buttons_[self.currentSelectedIndex_]:setButtonSelected(true, true) 
            end
            return
        end
    end
    if not self.isSwitchModel then
        local currentSelectedIndex = 0
        for index, button in ipairs(self.buttons_) do
            if button == clickedButton then
                currentSelectedIndex = index
                if not button:isButtonSelected() then
                    button:setButtonSelected(true)
                end
            else
                if button:isButtonSelected() then
                    button:setButtonSelected(false)
                end
            end
        end
        if self.currentSelectedIndex_ ~= currentSelectedIndex then
            local last = self.currentSelectedIndex_
            self.currentSelectedIndex_ = currentSelectedIndex
            self:dispatchEvent({name = UICheckBoxButtonGroup.BUTTON_SELECT_CHANGED, selected = currentSelectedIndex, last = last})
        end
    end
end

function UICanCanelCheckBoxButtonGroup:sureSelectedButtonIndex(target_index,dot_call_event)
    for index, button in ipairs(self.buttons_) do
        if target_index == index then
            if not button:isButtonSelected() then
                button:setButtonSelected(true)
            end
        else
            if button:isButtonSelected() then
                button:setButtonSelected(false)
            end
        end
    end
    if self.currentSelectedIndex_ ~= target_index then
        local last = self.currentSelectedIndex_
        self.currentSelectedIndex_ = target_index
        if not dot_call_event then
            self:dispatchEvent({name = UICheckBoxButtonGroup.BUTTON_SELECT_CHANGED, selected = target_index, last = last})
        end
    end
end

function UICanCanelCheckBoxButtonGroup:setCheckButtonStateChangeFunction(func)
    self.check_func = func
    return self
end
--开启开关模式 唯一的一个选项 
function UICanCanelCheckBoxButtonGroup:setIsSwitchModel(yesOrNo)
    self.isSwitchModel = yesOrNo
    return self
end

return UICanCanelCheckBoxButtonGroup
