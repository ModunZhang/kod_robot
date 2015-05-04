local cocos_promise = import("..utils.cocos_promise")
local window = import("..utils.window")
local UIListView = import("..ui.UIListView")
local WidgetPopDialog = import(".WidgetPopDialog")
local WidgetDropItem = import(".WidgetDropItem")
local WidgetGrowUpTask = class("WidgetGrowUpTask", WidgetPopDialog)
function WidgetGrowUpTask:ctor(category)
    WidgetGrowUpTask.super.ctor(self, 630, category:Title(), display.cy + 300)
    self.touch_layer = display.newLayer():addTo(self, 10)
    self.touch_layer:setTouchEnabled(false)

    self.category = category
end
function WidgetGrowUpTask:onEnter()
    WidgetGrowUpTask.super.onEnter(self)
    local body = self:GetBody()
    local size = body:getContentSize()
    self.listview = UIListView.new{
        -- bgColor = UIKit:hex2c4b(0x7a100000),
        viewRect = cc.rect(0, 20, size.width, size.height - 40),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
    }:addTo(body)
    self:RefreshItems()
end
function WidgetGrowUpTask:onExit()
    WidgetGrowUpTask.super.onExit(self)
end
function WidgetGrowUpTask:CloseOtherItems(content)
    for _,v in ipairs(self.listview.items_) do
        if content ~= v and v:getContent().state_ == WidgetDropItem.STATE.open then
            v:getContent():OnClose(false)
        end
    end
end
function WidgetGrowUpTask:HideOtherContent(content)
    for _,v in ipairs(self.listview.items_) do
        if content ~= v and v:getContent().state_ == WidgetDropItem.STATE.open then
            transition.scaleTo(v:getContent().content_box, {scaleY = 0, time = 0.2})
        end
    end
end
function WidgetGrowUpTask:RefreshItems()
    self.listview:removeAllItems()
    for _,v in ipairs(self.category.tasks) do
        self.listview:addItem(self:CreateItem(self.listview, v))
    end
    self.listview:reload()
    if self.listview.items_[1] then
        self.listview.items_[1]:getContent():OnOpen(false)
    end
end
function WidgetGrowUpTask:CreateItem(listview, task)
    local item = listview:newItem()
    local content = WidgetDropItem.new({title=task:Title()}, function(drop_item, ani)
        local is_open_with_ani = drop_item and ani
        if drop_item then
            drop_item:CreateRewardsPanel(task)
        end
        local w,h = item:getItemSize()
        local x,y = item:getContent():getPosition()
        local new_h = item:getContent():getCascadeBoundingBox().height + 10
        local offset = (new_h - h) * 0.5
        local item_rect = item:getCascadeBoundingBox()
        self.touch_layer:setTouchEnabled(true)
        if ani then
            transition.moveTo(item:getContent(), {x = x, y = y + offset, time = 0.2,
                onComplete = function()
                    if drop_item then
                        self:HideOtherContent(item)
                        local viewRect_ = listview:getViewRectInWorldSpace()
                        local offset_y = (viewRect_.y + viewRect_.height) - (item_rect.y + item_rect.height)
                        transition.moveBy(listview.container, {x = 0, y = offset_y, time = 0.1, onComplete = function()
                            if is_open_with_ani then
                                self:CloseOtherItems(item)
                                listview.scrollNode:stopAllActions()
                                local rect = item:getCascadeBoundingBox()
                                local viewRect_ = listview:getViewRectInWorldSpace()
                                local offset_y = (viewRect_.y + viewRect_.height) - (rect.y + rect.height)
                                local x,y = listview.container:getPosition()
                                listview.container:pos(x, y + offset_y)
                            end
                        end})
                    end
                    self.touch_layer:setTouchEnabled(false)
                end
            })
        else
            item:getContent():pos(x, y + offset)
            self.touch_layer:setTouchEnabled(false)
            if drop_item then
                local viewRect_ = listview:getViewRectInWorldSpace()
                local offset_y = (viewRect_.y + viewRect_.height) - (item_rect.y + item_rect.height)
                local x,y = listview.container:getPosition()
                listview.container:pos(x, y + offset_y)
            end
        end
        item:setItemSize(w, new_h, false, ani)
    end):align(display.CENTER)
    item:addContent(content)
    local rect = content:getCascadeBoundingBox()
    item:setItemSize(rect.width, rect.height + 10,false,false)
    return item
end



return WidgetGrowUpTask

















