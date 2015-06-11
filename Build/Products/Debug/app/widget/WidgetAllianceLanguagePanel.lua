--
-- Author: Danny He
-- Date: 2014-10-09 20:58:25
--
local Language = import("..utils.Localize").alliance_language
local UICheckBoxButton = import("..ui.UICheckBoxButton")
local WidgetAllianceLanguagePanel = class("WidgetAllianceLanguagePanel", function()
    return display.newNode()
end)
local HEIGHT = 320
local ALL_LANGUAGE = {
    "all",
    "en",
    "cn",
    "tw",
    "ja",
    "ko",
    "de",
    "fr",
    "ru",
    "it",
    "es",
    "pt",
}

local checkbox_image = {
    off = "checkbox_unselected.png",
    off_pressed = "checkbox_unselected.png",
    off_disabled = "checkbox_unselected.png",
    on = "checkbox_selectd.png",
    on_pressed = "checkbox_selectd.png",
    on_disabled = "checkbox_selectd.png",
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
        text = _("联盟语言"),
        size = 20,
        color = 0xffedae
    }):addTo(title):align(display.CENTER,272,16)
	self:createCheckBoxButtons_()
    self:buttonEvents_()
    self:selectButtonByIndex(self.currentSelectedIndex_)
end


function WidgetAllianceLanguagePanel:createCheckBoxButtons_()
	self.buttons_ = {}
    local start_y = 20
	local button = UICheckBoxButton.new(checkbox_image)
            :setButtonLabel(UIKit:ttfLabel({text = Language.it,size = 20,color = 0x615b44}))
            :setButtonLabelOffset(30, 0)
            :align(display.LEFT_BOTTOM,10,start_y)
            :addTo(self)
    button:setTag(10)
	table.insert(self.buttons_,button)
	button = UICheckBoxButton.new(checkbox_image)
            :setButtonLabel(UIKit:ttfLabel({text = Language.es,size = 20,color = 0x615b44}))
            :setButtonLabelOffset(30, 0)
            :align(display.LEFT_BOTTOM,220,start_y)
            :addTo(self)
    button:setTag(11)
    table.insert(self.buttons_,button)
    button = UICheckBoxButton.new(checkbox_image)
            :setButtonLabel(UIKit:ttfLabel({text = Language.pt,size = 20,color = 0x615b44}))
            :setButtonLabelOffset(30, 0)
            :align(display.LEFT_BOTTOM,400,start_y)
            :addTo(self)
    button:setTag(12)
    table.insert(self.buttons_,button)
    button = UICheckBoxButton.new(checkbox_image)
            :setButtonLabel(UIKit:ttfLabel({text = Language.de,size = 20,color = 0x615b44}))
            :setButtonLabelOffset(30, 0)
            :align(display.LEFT_BOTTOM,10,start_y + button:getCascadeBoundingBox().height+5)
            :addTo(self)
    button:setTag(7)
	table.insert(self.buttons_,button) 
    button = UICheckBoxButton.new(checkbox_image)
            :setButtonLabel(UIKit:ttfLabel({text = Language.fr,size = 20,color = 0x615b44}))
            :setButtonLabelOffset(30, 0)
            :align(display.LEFT_BOTTOM,220,start_y + button:getCascadeBoundingBox().height+5)
            :addTo(self)
    button:setTag(8)
    table.insert(self.buttons_,button)
    button = UICheckBoxButton.new(checkbox_image)
            :setButtonLabel(UIKit:ttfLabel({text = Language.ru,size = 20,color = 0x615b44}))
            :setButtonLabelOffset(30, 0)
            :align(display.LEFT_BOTTOM,400,start_y + button:getCascadeBoundingBox().height+5)
            :addTo(self)
    button:setTag(9)
    table.insert(self.buttons_,button)    
    button = UICheckBoxButton.new(checkbox_image)
            :setButtonLabel(UIKit:ttfLabel({text = Language.tw,size = 20,color = 0x615b44}))
            :setButtonLabelOffset(30, 0)
            :align(display.LEFT_BOTTOM,10,start_y + (button:getCascadeBoundingBox().height+5)*2)
            :addTo(self)
    button:setTag(4)
    table.insert(self.buttons_,button)   
    button = UICheckBoxButton.new(checkbox_image)
            :setButtonLabel(UIKit:ttfLabel({text = Language.ja,size = 20,color = 0x615b44}))
            :setButtonLabelOffset(30, 0)
            :align(display.LEFT_BOTTOM,220,start_y +(button:getCascadeBoundingBox().height+5)*2)
            :addTo(self)
    button:setTag(5)
    table.insert(self.buttons_,button)
	button = UICheckBoxButton.new(checkbox_image)
            :setButtonLabel(UIKit:ttfLabel({text = Language.ko,size = 20,color = 0x615b44}))
            :setButtonLabelOffset(30, 0)
            :align(display.LEFT_BOTTOM,400,start_y +(button:getCascadeBoundingBox().height+5)*2)
            :addTo(self)
    button:setTag(6)
    table.insert(self.buttons_,button)
    button = UICheckBoxButton.new(checkbox_image)
            :setButtonLabel(UIKit:ttfLabel({text = Language.all,size = 20,color = 0x615b44}))
            :setButtonLabelOffset(30, 0)
            :align(display.LEFT_BOTTOM,10,start_y +(button:getCascadeBoundingBox().height+5)*3)
            :addTo(self)
    button:setTag(1)
    table.insert(self.buttons_,button)
	button = UICheckBoxButton.new(checkbox_image)
            :setButtonLabel(UIKit:ttfLabel({text = Language.en,size = 20,color = 0x615b44}))
            :setButtonLabelOffset(30, 0)
            :align(display.LEFT_BOTTOM,220,start_y +(button:getCascadeBoundingBox().height+5)*3)
            :addTo(self)
    button:setTag(2)
    table.insert(self.buttons_,button)
    button = UICheckBoxButton.new(checkbox_image)
            :setButtonLabel(UIKit:ttfLabel({text = Language.cn,size = 20,color = 0x615b44}))
            :setButtonLabelOffset(30, 0)
            :align(display.LEFT_BOTTOM,400,start_y +(button:getCascadeBoundingBox().height+5)*3)
            :addTo(self)
    button:setTag(3)
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