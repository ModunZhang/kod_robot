--
-- Author: Danny He
-- Date: 2014-10-09 20:58:25
--
local Language = import("..utils.Localize").alliance_language
local UICheckBoxButton = import("..ui.UICheckBoxButton")
local WidgetAllianceLanguagePanel = class("WidgetAllianceLanguagePanel", function()
    return display.newNode()
end)
local HEIGHT = 428
local ALL_LANGUAGE = {
    "ALL",
    "USA",
    "GBR",
    "CAN",
    "FRA",
    "ITA",
    "DEU",
    "RUS",
    "PRT",
    "CHN",
    "TWN",
    "AUS",
    "ESP",
    "JPN",
    "KOR",
    "FIN",
}

WidgetAllianceLanguagePanel.BUTTON_SELECT_CHANGED = "BUTTON_SELECT_CHANGED"

function WidgetAllianceLanguagePanel:ctor(selectLanguage)
    cc(self):addComponent("components.behavior.EventProtocol"):exportMethods()
    self:setNodeEventEnabled(true)
    self.currentSelectedIndex_ = selectLanguage ~= nil and  self:FindIndexByLanguage(selectLanguage) or 1
end

function WidgetAllianceLanguagePanel:FindIndexByLanguage(language)
    if not language then return 1 end
    for i,v in ipairs(ALL_LANGUAGE) do
        if v == language then
            return i
        end
    end
end

function WidgetAllianceLanguagePanel:onEnter()
    local bg = UIKit:CreateBoxPanelWithBorder({height = HEIGHT}):addTo(self)
    local title = display.newSprite("alliance_panel_bg_544x32.png"):align(display.CENTER_TOP,bg:getContentSize().width/2, HEIGHT - 6):addTo(bg)
    UIKit:ttfLabel({
        text = _("国家"),
        size = 20,
        color = 0xffedae
    }):addTo(title):align(display.CENTER,272,16)
    self:createCheckBoxButtons_()
    self:buttonEvents_()
    self:selectButtonByIndex(self.currentSelectedIndex_)
end


function WidgetAllianceLanguagePanel:createCheckBoxButtons_()
    self.buttons_ = {}
    local start_y = 10
    local frist_row_x, second_row_x, thrid_row_x, fourth_row_x = 57,205,353,499
    -- 从上往上第一排
    local button = UICheckBoxButton.new({
        off = "icon_ESP.png",
        on = "icon_language_selected_112x112.png",
    })
        :align(display.CENTER_BOTTOM,frist_row_x,start_y)
        :addTo(self)
        :scale(76/94)
    display.newSprite("icon_ESP.png"):align(display.CENTER_BOTTOM,frist_row_x,start_y)
        :addTo(self)
        :scale(76/94)
    button:setTag(13)
    table.insert(self.buttons_,button)
    button = UICheckBoxButton.new({
        off = "icon_JPN.png",
        on = "icon_language_selected_112x112.png",
    })
        :align(display.CENTER_BOTTOM,second_row_x,start_y)
        :addTo(self)
        :scale(76/94)
    display.newSprite("icon_JPN.png"):align(display.CENTER_BOTTOM,second_row_x,start_y)
        :addTo(self)
        :scale(76/94)
    button:setTag(14)
    table.insert(self.buttons_,button)
    button = UICheckBoxButton.new({
        off = "icon_KOR.png",
        on = "icon_language_selected_112x112.png",
    })
        :align(display.CENTER_BOTTOM,thrid_row_x,start_y)
        :addTo(self)
        :scale(76/94)
    display.newSprite("icon_KOR.png"):align(display.CENTER_BOTTOM,thrid_row_x,start_y)
        :addTo(self)
        :scale(76/94)
    button:setTag(15)
    table.insert(self.buttons_,button)
    button = UICheckBoxButton.new({
        off = "icon_FIN.png",
        on = "icon_language_selected_112x112.png",
    })
        :align(display.CENTER_BOTTOM,fourth_row_x,start_y)
        :addTo(self)
        :scale(76/94)
    display.newSprite("icon_FIN.png"):align(display.CENTER_BOTTOM,fourth_row_x,start_y)
        :addTo(self)
        :scale(76/94)
    button:setTag(16)
    table.insert(self.buttons_,button)
    -- 第二排
    start_y = start_y + button:getCascadeBoundingBox().height+5
    button = UICheckBoxButton.new({
        off = "icon_PRT.png",
        on = "icon_language_selected_112x112.png",
    })
        :align(display.CENTER_BOTTOM,frist_row_x,start_y)
        :addTo(self)
        :scale(76/94)
    display.newSprite("icon_PRT.png"):align(display.CENTER_BOTTOM,frist_row_x,start_y)
        :addTo(self)
        :scale(76/94)
    button:setTag(9)
    table.insert(self.buttons_,button)
    button = UICheckBoxButton.new({
        off = "icon_CHN.png",
        on = "icon_language_selected_112x112.png",
    })
        :align(display.CENTER_BOTTOM,second_row_x,start_y)
        :addTo(self)
        :scale(76/94)
    display.newSprite("icon_CHN.png"):align(display.CENTER_BOTTOM,second_row_x,start_y)
        :addTo(self)
        :scale(76/94)
    button:setTag(10)
    table.insert(self.buttons_,button)
    button = UICheckBoxButton.new({
        off = "icon_TWN.png",
        on = "icon_language_selected_112x112.png",
    })
        :align(display.CENTER_BOTTOM,thrid_row_x,start_y)
        :addTo(self)
        :scale(76/94)
    display.newSprite("icon_TWN.png"):align(display.CENTER_BOTTOM,thrid_row_x,start_y)
        :addTo(self)
        :scale(76/94)
    button:setTag(11)
    table.insert(self.buttons_,button)
    button = UICheckBoxButton.new({
        off = "icon_AUS.png",
        on = "icon_language_selected_112x112.png",
    })
        :align(display.CENTER_BOTTOM,fourth_row_x,start_y)
        :addTo(self)
        :scale(76/94)
    display.newSprite("icon_AUS.png"):align(display.CENTER_BOTTOM,fourth_row_x,start_y)
        :addTo(self)
        :scale(76/94)
    button:setTag(12)
    table.insert(self.buttons_,button)
    -- 第三排
    start_y = start_y + button:getCascadeBoundingBox().height+5
    button = UICheckBoxButton.new({
        off = "icon_FRA.png",
        on = "icon_language_selected_112x112.png",
    })
        :align(display.CENTER_BOTTOM,frist_row_x,start_y)
        :addTo(self)
        :scale(76/94)
    display.newSprite("icon_FRA.png"):align(display.CENTER_BOTTOM,frist_row_x,start_y)
        :addTo(self)
        :scale(76/94)
    button:setTag(5)
    table.insert(self.buttons_,button)
    button = UICheckBoxButton.new({
        off = "icon_ITA.png",
        on = "icon_language_selected_112x112.png",
    })
        :align(display.CENTER_BOTTOM,second_row_x,start_y)
        :addTo(self)
        :scale(76/94)
    display.newSprite("icon_ITA.png"):align(display.CENTER_BOTTOM,second_row_x,start_y)
        :addTo(self)
        :scale(76/94)
    button:setTag(6)
    table.insert(self.buttons_,button)
    button = UICheckBoxButton.new({
        off = "icon_DEU.png",
        on = "icon_language_selected_112x112.png",
    })
        :align(display.CENTER_BOTTOM,thrid_row_x,start_y)
        :addTo(self)
        :scale(76/94)
    display.newSprite("icon_DEU.png"):align(display.CENTER_BOTTOM,thrid_row_x,start_y)
        :addTo(self)
        :scale(76/94)
    button:setTag(7)
    table.insert(self.buttons_,button)
    button = UICheckBoxButton.new({
        off = "icon_RUS.png",
        on = "icon_language_selected_112x112.png",
    })
        :align(display.CENTER_BOTTOM,fourth_row_x,start_y)
        :addTo(self)
        :scale(76/94)
    display.newSprite("icon_RUS.png"):align(display.CENTER_BOTTOM,fourth_row_x,start_y)
        :addTo(self)
        :scale(76/94)
    button:setTag(8)
    table.insert(self.buttons_,button)
    -- 第四排
    start_y = start_y + button:getCascadeBoundingBox().height+5
    button = UICheckBoxButton.new({
        off = "icon_ALL.png",
        on = "icon_language_selected_112x112.png",
    })
        :align(display.CENTER_BOTTOM,frist_row_x,start_y)
        :addTo(self)
        :scale(76/94)
    display.newSprite("icon_ALL.png"):align(display.CENTER_BOTTOM,frist_row_x,start_y)
        :addTo(self)
        :scale(76/94)
    button:setTag(1)
    table.insert(self.buttons_,button)
    button = UICheckBoxButton.new({
        off = "icon_USA.png",
        on = "icon_language_selected_112x112.png",
    })
        :align(display.CENTER_BOTTOM,second_row_x,start_y)
        :addTo(self)
        :scale(76/94)
    display.newSprite("icon_USA.png"):align(display.CENTER_BOTTOM,second_row_x,start_y)
        :addTo(self)
        :scale(76/94)
    button:setTag(2)
    table.insert(self.buttons_,button)
    button = UICheckBoxButton.new({
        off = "icon_GBR.png",
        on = "icon_language_selected_112x112.png",
    })
        :align(display.CENTER_BOTTOM,thrid_row_x,start_y)
        :addTo(self)
        :scale(76/94)
    display.newSprite("icon_GBR.png"):align(display.CENTER_BOTTOM,thrid_row_x,start_y)
        :addTo(self)
        :scale(76/94)
    button:setTag(3)
    table.insert(self.buttons_,button)
    button = UICheckBoxButton.new({
        off = "icon_CAN.png",
        on = "icon_language_selected_112x112.png",
    })
        :align(display.CENTER_BOTTOM,fourth_row_x,start_y)
        :addTo(self)
        :scale(76/94)
    display.newSprite("icon_CAN.png"):align(display.CENTER_BOTTOM,fourth_row_x,start_y)
        :addTo(self)
        :scale(76/94)
    button:setTag(4)
    table.insert(self.buttons_,button)
end

function WidgetAllianceLanguagePanel:buttonEvents_()
    for i,button in ipairs(self.buttons_) do
        button:onButtonStateChanged(handler(self, self.onButtonStateChanged_))
        button:onButtonClicked(handler(self, self.onButtonStateChanged_))
    end
end

function WidgetAllianceLanguagePanel:onButtonStateChanged_(event)
    if event.name == UICheckBoxButton.STATE_CHANGED_EVENT and event.target:isButtonSelected() == false then
        return
    end
    self:updateButtonState_(event.target)
end

function WidgetAllianceLanguagePanel:selectButtonByIndex( index )
    self:getChildByTag(index):setButtonSelected(true)
end

function WidgetAllianceLanguagePanel:updateButtonState_(clickedButton)
    local currentSelectedIndex = 0
    for index, button in ipairs(self.buttons_) do
        if button == clickedButton then
            currentSelectedIndex = button:getTag()
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
        self:dispatchEvent({name = WidgetAllianceLanguagePanel.BUTTON_SELECT_CHANGED,
            selected = currentSelectedIndex,
            last = last,
            language = self:getSelectedLanguage()}
        )
    end
end

function WidgetAllianceLanguagePanel:getSelectedIndex()
    return self.currentSelectedIndex_
end

function WidgetAllianceLanguagePanel:addButtonSelectChangedEventListener(callback)
    return self:addEventListener(WidgetAllianceLanguagePanel.BUTTON_SELECT_CHANGED, callback)
end

function WidgetAllianceLanguagePanel:onButtonSelectChanged(callback)
    self:addButtonSelectChangedEventListener(callback)
    return self
end

function WidgetAllianceLanguagePanel:getSelectedLanguage()
    return ALL_LANGUAGE[self:getSelectedIndex()]
end

return WidgetAllianceLanguagePanel



