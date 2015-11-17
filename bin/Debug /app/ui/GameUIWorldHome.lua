--
-- Author: Kenny Dai
-- Date: 2015-10-22 14:37:23
--
local window = import("..utils.window")
local WidgetChat = import("..widget.WidgetChat")
local WidgetHomeBottom = import("..widget.WidgetHomeBottom")
local WidgetEventTabButtons = import("..widget.WidgetEventTabButtons")
local WidgetChangeMap = import("..widget.WidgetChangeMap")
local GameUIWorldHome = UIKit:createUIClass('GameUIWorldHome')
function GameUIWorldHome:DisplayOn()
    self.visible_count = self.visible_count + 1
    self:FadeToSelf(self.visible_count > 0)
end
function GameUIWorldHome:DisplayOff()
    self.visible_count = self.visible_count - 1
    self:FadeToSelf(self.visible_count > 0)
end
function GameUIWorldHome:FadeToSelf(isFullDisplay)
    self:stopAllActions()
    if isFullDisplay then
        self:show()
        transition.fadeIn(self, {
            time = 0.2,
        })
    else
        transition.fadeOut(self, {
            time = 0.2,
            onComplete = function()
                self:hide()
            end,
        })
    end
end
function GameUIWorldHome:ctor(city)
    GameUIWorldHome.super.ctor(self,{type = UIKit.UITYPE.BACKGROUND})
    self.city = city
end
function GameUIWorldHome:onEnter()
    self.visible_count = 1
    local city = self.city
    -- top
    local top_bg = display.newSprite("background_500x84.png"):align(display.TOP_CENTER, display.cx, display.top-20):addTo(self)
    UIKit:ttfLabel({
        text = _("世界地图"),
        size = 32,
        color = 0xffedae,
    }):align(display.CENTER, top_bg:getContentSize().width/2, top_bg:getContentSize().height/2)
        :addTo(top_bg)

    UIKit:newWidgetUI("WidgetShortcutButtons",city):addTo(self)

    self.bottom = self:CreateBottom()

    local ratio = self.bottom:getScale()
    self.event_tab = WidgetEventTabButtons.new(self.city, ratio)
    local rect1 = self.chat:getCascadeBoundingBox()
    local x, y = rect1.x, rect1.y + rect1.height - 2
    self.event_tab:addTo(self,0):pos(x, y)
    -- self:AddOrRemoveListener(true)
end
function GameUIWorldHome:onExit()
-- self:AddOrRemoveListener(false)
end
-- function GameUIWorldHome:AddOrRemoveListener(isAdd)
--     local city = self.city
--     local user = self.city:GetUser()
--     local my_allaince = Alliance_Manager:GetMyAlliance()
--     if isAdd then
--         user:AddListenOnType(self, "basicInfo")
--     else
--         user:RemoveListenerOnType(self, "basicInfo")
--     end
-- end

function GameUIWorldHome:CreateBottom()
    local bottom_bg = WidgetHomeBottom.new(self.city):addTo(self, 1)
        :align(display.BOTTOM_CENTER, display.cx, display.bottom)

    self.chat = WidgetChat.new():addTo(bottom_bg)
        :align(display.CENTER, bottom_bg:getContentSize().width/2, bottom_bg:getContentSize().height-11)

    self.change_map = WidgetChangeMap.new(WidgetChangeMap.MAP_TYPE.OUR_CITY):addTo(self, 1)

    return bottom_bg
end
function GameUIWorldHome:ChangeChatChannel(channel_index)
    self.chat:ChangeChannel(channel_index)
end


return GameUIWorldHome








