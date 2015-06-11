
--
-- Author: Kenny Dai
-- Date: 2015-06-01 09:51:28
--
local fire_circle = import("..particles.fire_circle")
local WidgetAutoOrderBuffButton = class("WidgetAutoOrderBuffButton",function ( )
    return display.newNode()
end)

function WidgetAutoOrderBuffButton:ctor()
    self:setNodeEventEnabled(true)
    -- BUFF按钮
    local buff_button = cc.ui.UIPushButton.new(
        {normal = "buff_68x68.png", pressed = "buff_68x68.png"}
    ):onButtonClicked(function(event)
        if event.name == "CLICKED_EVENT" then
            UIKit:newGameUI("GameUIBuff",City):AddToCurrentScene(true)
        end
    end):addTo(self):pos(34,34)
    self.buff_button = buff_button
    
    local grey_image = display.newSprite("buff_68x68.png",34, 34,{class=cc.FilteredSpriteWithOne}):addTo(self)
    local my_filter = filter
    local filters = my_filter.newFilter("GRAY", {0.2, 0.3, 0.5, 0.1})
    grey_image:setFilter(filters)
    grey_image:setVisible(not ItemManager:IsAnyItmeEventActive())
    buff_button:opacity(ItemManager:IsAnyItmeEventActive() and 255 or 0)

    self.grey_image = grey_image
    self:setContentSize(buff_button:getCascadeBoundingBox().size)
    self:setAnchorPoint(cc.p(0.5,0.5))

    self:OnItemEventChanged()
end

function WidgetAutoOrderBuffButton:onEnter()
    ItemManager:AddListenOnType(self,ItemManager.LISTEN_TYPE.ITEM_EVENT_CHANGED)
end

function WidgetAutoOrderBuffButton:onCleanup()
    ItemManager:RemoveListenerOnType(self,ItemManager.LISTEN_TYPE.ITEM_EVENT_CHANGED)
end
function WidgetAutoOrderBuffButton:OnItemEventChanged()
    if ItemManager:IsAnyItmeEventActive() then
        if not self.buff_button:getChildByTag(321) then
            fire_circle():addTo(self.buff_button, -1000, 321)
        end
    else
        if self.buff_button:getChildByTag(321) then
            self.buff_button:removeChildByTag(321)
        end
    end
    self.grey_image:setVisible(not ItemManager:IsAnyItmeEventActive())
    self.buff_button:opacity(ItemManager:IsAnyItmeEventActive() and 255 or 0)
end
-- For WidgetAutoOrder
function WidgetAutoOrderBuffButton:CheckVisible()
    return  true
end

function WidgetAutoOrderBuffButton:GetElementSize()
    return self:getContentSize()
end

return WidgetAutoOrderBuffButton




