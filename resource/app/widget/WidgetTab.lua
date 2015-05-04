local WidgetTab = class("WidgetTab", function()
    return display.newNode()
end)


function WidgetTab:ctor(param, width, height)
    self.pressed = false
    self.width = width
    self.height = height
    self.back_ground = display.newLayer():addTo(self)
    self.back_ground:setContentSize(width, height)
    if param.background then
        display.newSprite(param.background):addTo(self.back_ground):align(display.CENTER, width/2, height/2)
    end
    self.tab = cc.ui.UICheckBoxButton.new(param, {scale9 = true})
        :addTo(self.back_ground, 1)
        :align(display.CENTER, width/2, height/2)
        :setButtonSelected(self.pressed)
        :setButtonSize(width, height)
    self.tab:setTouchEnabled(false)

    if param.tab_png then
        self.tab_png = cc.ui.UIImage.new(param.tab_png):addTo(self)
            :align(display.CENTER, width/2, height/2)
    end

    if param.progress then
        self.progress = display.newProgressTimer("tab_event_progress.png",
            display.PROGRESS_TIMER_BAR):addTo(self.back_ground, 2)
            :align(display.BOTTOM_CENTER, width/2, 1)
        self.progress:setBarChangeRate(cc.p(1,0))
        self.progress:setMidpoint(cc.p(0,0))

        self.label = UIKit:ttfLabel({
            text = "",
            size = 14,
            color = 0xfffcbe,
        }):addTo(self):align(display.CENTER, width/2 + 10, height/2)
    end

    self.back_ground:setContentSize(cc.size(width, height))
    self.back_ground:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(event)
        if event.name == "began" and
            self.back_ground:getCascadeBoundingBox():containsPoint(cc.p(event.x, event.y)) then
            self.pressed = not self.pressed
            self:Active(self.pressed)
            app:GetAudioManager():PlayeEffectSoundWithKey("HOME_PAGE")
            if type(self.tab_press) == "function" then
                self:tab_press(self.pressed)
            end
            return false
        end
    end)
end
function WidgetTab:SetOrResetProgress(time, percent)
    if time and percent then
        if self.left_time > time then
            self.left_time = time
            self.label:show():setString(GameUtils:formatTimeStyle1(time))
            self.progress:show():setPercentage(percent)
            self.tab_png:scale(0.8):setPositionX(self.width/5)
        end
    else
        self.left_time = math.huge
        self.label:hide()
        self.progress:hide():setPercentage(0)
        self.tab_png:scale(1):setPositionX(self.width/2)
    end
    return self
end
function WidgetTab:OnTabPress(func)
    self.tab_press = func
    return self
end
function WidgetTab:Enable(trueOrFlase)
    self.back_ground:setTouchEnabled(trueOrFlase)
    return self
end
function WidgetTab:Active(active)
    self:SetHighLight(active)
    self:SetSelect(active)
    return self
end
function WidgetTab:SetSelect(is_pressed)
    self.pressed = is_pressed
    return self
end
function WidgetTab:SetHighLight(is_highlight)
    self.tab:setButtonSelected(is_highlight)
    return self
end
function WidgetTab:IsSelected()
    return self.pressed
end
function WidgetTab:EnableTag(b)
    local size = self.back_ground:getContentSize()
    local bg = display.newSprite("tab_background_40x24.png"):addTo(self,1):pos(size.width - 40/2, size.height)
    self.active = cc.ui.UILabel.new({
        UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
        size = 16,
        font = UIKit:getFontFilePath(),
        color = UIKit:hex2c3b(0xfffeb3)}):addTo(bg):align(display.CENTER,40/2,24/2 + 2)
    return self
end
function WidgetTab:SetActiveNumber(active, total)
    self.current = active
    self.total = total
    self.active:getParent():setVisible(total > 0)
    self.active:setString(string.format("%d/%d", active, total))
    return self
end
function WidgetTab:IsChanged(active, total)
    return self.current ~= active or self.total ~= total
end
function WidgetTab:Size(width, height)
    self.tab:setButtonSize(width, height)
    self.back_ground:setContentSize(cc.size(width, height))
    return self
end
function WidgetTab:align(anchorPoint, x, y)
    local size = self.back_ground:getContentSize()
    local point = display.ANCHOR_POINTS[anchorPoint]
    local offset_x, offset_y = size.width * point.x, size.height * point.y
    self.back_ground:setPosition(- offset_x, - offset_y)
    if x and y then self:setPosition(x, y) end
    return self
end





return WidgetTab












