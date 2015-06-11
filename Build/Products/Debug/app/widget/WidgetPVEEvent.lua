local Localize = import("..utils.Localize")
local promise = import("..utils.promise")
local WidgetPVEGetTaskRewards = import("..widget.WidgetPVEGetTaskRewards")
local cocos_promise = import("..utils.cocos_promise")
local timer = app.timer
local WIDGET_WIDTH = 640
local WIDGET_HEIGHT = 300
local ITEM_HEIGHT = 47

local WidgetPVEEvent = class("WidgetPVEEvent", function()
    local rect = cc.rect(0, 0, WIDGET_WIDTH, WIDGET_HEIGHT)
    local node = display.newClippingRegionNode(rect)
    node:setTouchEnabled(true)
    node.view_rect = rect
    node.locked = false
    node:addNodeEventListener(cc.NODE_TOUCH_CAPTURE_EVENT, function (event)
        if node.locked then
            return false
        end
        if ("began" == event.name or "moved" == event.name or "ended" == event.name)
            and node:isTouchInViewRect(event) then
            return true
        else
            return false
        end
    end)
    return node:setCascadeOpacityEnabled(true)
end)
function WidgetPVEEvent:isTouchInViewRect(event)
    local viewRect = self:convertToWorldSpace(cc.p(self.view_rect.x, self.view_rect.y))
    viewRect.width = self.view_rect.width
    viewRect.height = self.view_rect.height
    return cc.rectContainsPoint(viewRect, cc.p(event.x, event.y))
end
function WidgetPVEEvent:ctor(user, ratio)
    self.view_rect = cc.rect(0, 0, WIDGET_WIDTH * ratio, (WIDGET_HEIGHT) * ratio)
    self:setClippingRegion(self.view_rect)

    self.item_array = {}
    self.node = display.newNode():addTo(self):scale(ratio)

    cc.Layer:create():addTo(self.node):pos(0, -WIDGET_HEIGHT)
        :setContentSize(cc.size(WIDGET_WIDTH, WIDGET_HEIGHT))
        :setCascadeOpacityEnabled(true)

    self.user = user

    self.back_ground = self:CreateBackGround():addTo(self.node)
    self:Reset()
    self:PromiseOfSwitch()
end
function WidgetPVEEvent:CreateBackGround()
    local back = cc.ui.UIImage.new("tab_background_640x106.png", {scale9 = true,
        capInsets = cc.rect(2, 2, WIDGET_WIDTH - 4, 106 - 4)
    }):align(display.LEFT_BOTTOM):setLayoutSize(WIDGET_WIDTH, ITEM_HEIGHT + 2)
    return back
end
function WidgetPVEEvent:InsertItem(item, pos)
    if type(item) == "table" then
        local count = #item
        for i = count, 1, -1 do
            self:InsertItem_(item[i], pos)
        end
    else
        self:InsertItem_(item, pos)
    end
    for i, v in ipairs(self.item_array) do
        v:pos(1, (i-1) * ITEM_HEIGHT + 25)
    end
end
function WidgetPVEEvent:InsertItem_(item, pos)
    item:addTo(self.back_ground, 2)
    if pos then
        table.insert(self.item_array, pos, item)
    else
        table.insert(self.item_array, item)
    end
end
function WidgetPVEEvent:IteratorItems(func)
    for __,v in ipairs(self.item_array) do
        func(v)
    end
end
function WidgetPVEEvent:Lock(lock)
    self.locked = lock
end
function WidgetPVEEvent:PromiseOfSwitch()
    return self:PromiseOfHide():next(function()
        return self:PromiseOfShow()
    end)
end
function WidgetPVEEvent:PromiseOfHide()
    self.node:stopAllActions()
    self:Lock(true)
    local hide_height = - self.back_ground:getContentSize().height
    return cocos_promise.promiseOfMoveTo(self.node, 0, hide_height, 0.15, "sineIn"):next(function()
        self:Reset()
    end)
end
function WidgetPVEEvent:PromiseOfShow()
    local _,ok = self:GetWanted()
    if ok then
        self:Reload()
        self.node:stopAllActions()
        return cocos_promise.promiseOfMoveTo(self.node, 0, 0, 0.15, "sineIn"):next(function()

            end)
    end
    return cocos_promise.defer()
end
function WidgetPVEEvent:Reload()
    self:Reset()
    self:Load()
end
function WidgetPVEEvent:Reset()
    self.back_ground:removeAllChildren()
    self.item_array = {}
    self:ResizeBelowHorizon(0)
    self.node:stopAllActions()
    self:Lock(false)
end
function WidgetPVEEvent:Load()
    local target, ok = self:GetWanted()
    if ok then
        local item = self:CreateItem()
            :SetProgressInfo(
                string.format(_("通缉令 : %s        %d/%d"), Localize.soldier_name[target.name], target.count, target.target),
                (target.count / target.target) * 100)
        if target.count >= target.target then
            item:SetCanGet()
        end
        self:InsertItem(item:OnClicked(function()
            local target,ok = self.user:GetPVEDatabase():GetTarget()
            if ok then
                WidgetPVEGetTaskRewards.new(target.name, target.coin, (target.count/target.target) * 100):AddToCurrentScene(true)
            end
        end))
    end
    self:ResizeBelowHorizon(self:Length())
end
function WidgetPVEEvent:Length()
    return #self.item_array * ITEM_HEIGHT + 2
end
function WidgetPVEEvent:ResizeBelowHorizon(new_height)
    local height = new_height < ITEM_HEIGHT and ITEM_HEIGHT or new_height
    local size = self.back_ground:getContentSize()
    self.back_ground:setContentSize(cc.size(size.width, height))
    self.node:setPositionY(- height)
end
function WidgetPVEEvent:GetWanted()
    local target, ok = self.user:GetPVEDatabase():GetTarget()
    if not ok then
        self.user:GetPVEDatabase():NewTarget()
        return self.user:GetPVEDatabase():GetTarget()
    end
    return target, ok
end


--------------

function WidgetPVEEvent:CreateItem()
    local node = display.newSprite("tab_event_bar.png")
    local half_height = node:getContentSize().height / 2
    node.progress = display.newProgressTimer("pve_tab_progress_bar.png",
        display.PROGRESS_TIMER_BAR):addTo(node)
        :align(display.LEFT_CENTER, 4, half_height)
    node.progress:setBarChangeRate(cc.p(1,0))
    node.progress:setMidpoint(cc.p(0,0))
    node.desc = UIKit:ttfLabel({
        text = "",
        size = 18,
        color = 0xd1ca95,
        shadow = true,
    }):addTo(node):align(display.LEFT_CENTER, 10, half_height)

    node.button = cc.ui.UIPushButton.new({
        normal = "blue_btn_up_154x39.png",pressed = "blue_btn_down_154x39.png",
    }):addTo(node):align(display.RIGHT_CENTER, WIDGET_WIDTH - 6, half_height)
        :setButtonLabel(UIKit:ttfLabel({
            text = _("详情"),
            size = 18,
            color = 0xfff3c7,
            shadow = true}))
    function node:SetProgressInfo(str, percent)
        self.desc:setString(str)
        self.progress:setPercentage(percent)
        return self
    end
    function node:OnClicked(func)
        self.button:onButtonClicked(func)
        return self
    end
    function node:SetCanGet()
        self:SetButtonImages({normal = "yellow_btn_up_154x39.png", pressed = "yellow_btn_down_154x39.png"})
        self:SetButtonLabel(_("领取"))
        return self
    end
    function node:SetButtonImages(images)
        self.button:setButtonImage(cc.ui.UIPushButton.NORMAL, images["normal"], true)
        self.button:setButtonImage(cc.ui.UIPushButton.PRESSED, images["pressed"], true)
        self.button:setButtonImage(cc.ui.UIPushButton.DISABLED, images["disabled"], true)
        return self
    end
    function node:SetButtonLabel(str)
        self.button:setButtonLabelString(str)
        return self
    end
    return node:align(display.LEFT_CENTER)
end

return WidgetPVEEvent


