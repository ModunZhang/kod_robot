local promise = import("..utils.promise")
local MarchAttackEvent = import("..entity.MarchAttackEvent")
local Alliance = import("..entity.Alliance")
local cocos_promise = import("..utils.cocos_promise")
local WidgetPushButton = import("..widget.WidgetPushButton")
local WidgetUseItems = import("..widget.WidgetUseItems")
local timer = app.timer
local WIDGET_WIDTH = 640
local WIDGET_HEIGHT = 600
local ITEM_HEIGHT = 47
local GameUtils = GameUtils
local WidgetPushTransparentButton = import("..widget.WidgetPushTransparentButton")
local Alliance_Manager = Alliance_Manager

local WidgetMarchEvents = class("WidgetMarchEvents", function()
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

function WidgetMarchEvents:isTouchInViewRect(event)
    local viewRect = self:convertToWorldSpace(cc.p(self.view_rect.x, self.view_rect.y))
    viewRect.width = self.view_rect.width
    viewRect.height = self.view_rect.height
    return cc.rectContainsPoint(viewRect, cc.p(event.x, event.y))
end

---------------------------
--Observer Methods
function WidgetMarchEvents:OnHelpToTroopsChanged(changed_map)
    self:PromiseOfSwitch()
end

function WidgetMarchEvents:OnMarchDataChanged()
    self:PromiseOfSwitch()
end

function WidgetMarchEvents:OnFightEventTimerChanged(fightEvent)
    local item = self.items_map[fightEvent:Id()]
    if item then
        -- local desc =  string.format(" %s %s", item.prefix,GameUtils:formatTimeStyle1(fightEvent:GetTime()))
        -- item.desc:setString(desc)
        item.time:setString(GameUtils:formatTimeStyle1(fightEvent:GetTime()))
    end
end

function WidgetMarchEvents:OnAttackMarchEventTimerChanged(attackMarchEvent)
    local item = self.items_map[attackMarchEvent:Id()]
    if item then
        -- local desc =  string.format(" %s %s", item.prefix,GameUtils:formatTimeStyle1(attackMarchEvent:GetTime()))
        -- item.desc:setString(desc)
        item.time:setString(GameUtils:formatTimeStyle1(attackMarchEvent:GetTime()))
        item.progress:setPercentage(attackMarchEvent:GetPercent())
    end
end

function WidgetMarchEvents:OnVillageEventTimer(villageEvent)
    local item = self.items_map[villageEvent:Id()]
    if item then
        local desc =  string.format(" %s %d%%", item.prefix,villageEvent:CollectPercent())
        item.desc:setString(desc)
        item.time:setString(GameUtils:formatTimeStyle1(villageEvent:GetTime()))
        item.progress:setPercentage(villageEvent:CollectPercent())
    end
end

function WidgetMarchEvents:AddOrRemoveAllianceEvent(isAdd)
    local alliance_belvedere = self:GetAllianceBelvedere()
    if isAdd then
        City:AddListenOnType(self,City.LISTEN_TYPE.HELPED_TO_TROOPS)
        alliance_belvedere:AddListenOnType(self, alliance_belvedere.LISTEN_TYPE.OnMarchDataChanged)
        alliance_belvedere:AddListenOnType(self, alliance_belvedere.LISTEN_TYPE.OnAttackMarchEventTimerChanged)
        alliance_belvedere:AddListenOnType(self, alliance_belvedere.LISTEN_TYPE.OnVillageEventTimer)
        alliance_belvedere:AddListenOnType(self, alliance_belvedere.LISTEN_TYPE.OnFightEventTimerChanged)
    else
        City:RemoveListenerOnType(self,City.LISTEN_TYPE.HELPED_TO_TROOPS)
        alliance_belvedere:RemoveListenerOnType(self, alliance_belvedere.LISTEN_TYPE.OnMarchDataChanged)
        alliance_belvedere:RemoveListenerOnType(self, alliance_belvedere.LISTEN_TYPE.OnAttackMarchEventTimerChanged)
        alliance_belvedere:RemoveListenerOnType(self, alliance_belvedere.LISTEN_TYPE.OnVillageEventTimer)
        alliance_belvedere:RemoveListenerOnType(self, alliance_belvedere.LISTEN_TYPE.OnFightEventTimerChanged)
    end
end

---------------------------
function WidgetMarchEvents:ctor(alliance, ratio)
    self:setNodeEventEnabled(true)
    self.alliance = alliance
    self.alliance_belvedere = alliance:GetAllianceBelvedere() -- 获取瞭望塔对象
    self.view_rect = cc.rect(0, 0, WIDGET_WIDTH * ratio, (WIDGET_HEIGHT) * ratio)
    self:setClippingRegion(self.view_rect)

    self.item_array = {}
    self.node = display.newNode():addTo(self):scale(ratio)
    cc.Layer:create():addTo(self.node):pos(0, -WIDGET_HEIGHT):setContentSize(cc.size(WIDGET_WIDTH, WIDGET_HEIGHT)):setCascadeOpacityEnabled(true)
    self.hide_btn = self:CreateHideButton():addTo(self.node)
    self.back_ground = self:CreateBackGround():addTo(self.node)
    self:Reset()
end

function WidgetMarchEvents:GetAllianceBelvedere()
    assert(self.alliance_belvedere)
    return self.alliance_belvedere
end

function WidgetMarchEvents:onEnter()
    self:AddOrRemoveAllianceEvent(true)
    if self:HasAnyMarchEvent() then
        self:PromiseOfSwitch()
    end
end

function WidgetMarchEvents:onExit()
    self:AddOrRemoveAllianceEvent(false)
end

function WidgetMarchEvents:CreateHideButton()
    local btn = cc.ui.UIPushButton.new({normal = "march_hide_btn_up.png",
        pressed = "march_hide_btn_down.png"})
        :align(display.CENTER_BOTTOM, WIDGET_WIDTH/2, 0)
        :onButtonClicked(function(event)
            if not self:IsShow() then
                self:PromiseOfShow()
            else
                self:PromiseOfHide()
            end
        end)
    local size = btn:getCascadeBoundingBox()
    self.arrow = cc.ui.UIImage.new("march_hide_arrow.png")
        :addTo(btn):align(display.CENTER, 0, size.height/2)
    return btn
end

function WidgetMarchEvents:CreateBackGround()
    local back = cc.ui.UIImage.new("tab_background_640x106.png", {scale9 = true,
        capInsets = cc.rect(2, 2, WIDGET_WIDTH - 4, 106 - 4)
    }):align(display.LEFT_BOTTOM):setLayoutSize(WIDGET_WIDTH, ITEM_HEIGHT + 2)
    return back
end
--
function WidgetMarchEvents:InsertItem(item, pos)
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
function WidgetMarchEvents:InsertItem_(item, pos)
    item:addTo(self.back_ground, 2)
    if pos then
        table.insert(self.item_array, pos, item)
    else
        table.insert(self.item_array, item)
    end
end

function WidgetMarchEvents:IteratorItems(func)
    for __,v in ipairs(self.item_array) do
        func(v)
    end
end

--
function WidgetMarchEvents:Lock(lock)
    self.locked = lock
end

function WidgetMarchEvents:IsShow()
    return not self.arrow:isFlippedY()
end

function WidgetMarchEvents:PromiseOfSwitch()
    return self:PromiseOfHide():next(function()
        return self:PromiseOfShow()
    end)
end

function WidgetMarchEvents:PromiseOfHide()
    self.node:stopAllActions()
    self:Lock(true)
    local hide_height = - self.back_ground:getContentSize().height
    return cocos_promise.promiseOfMoveTo(self.node, 0, hide_height, 0.15, "sineIn"):next(function()
        self:Reset()
    end)
end

function WidgetMarchEvents:PromiseOfShow()
    if self:HasAnyMarchEvent() then
        self:Reload()
        self.node:stopAllActions()
        return cocos_promise.promiseOfMoveTo(self.node, 0, 0, 0.15, "sineIn"):next(function()
            self.arrow:flipY(false)
        end)
    end
    return cocos_promise.defer()
end

function WidgetMarchEvents:IsShow()
    return not self.arrow:isFlippedY()
end

function WidgetMarchEvents:Reload()
    self:Reset()
    self:Load()
end

function WidgetMarchEvents:Reset()
    self.items_map = {}
    self.back_ground:removeAllChildren()
    self.item_array = {}
    self:ResizeBelowHorizon(0)
    self.node:stopAllActions()
    self.arrow:flipY(true)
    self:Lock(false)
    local has_events = self:GetAllianceBelvedere():HasMyEvents()
    self:setVisible(has_events)
end

function WidgetMarchEvents:Load()
    local my_events = self:GetAllianceBelvedere():GetMyEvents()
    local items = {}
    for __,entity in ipairs(my_events) do
        local type_str = entity:GetTypeStr()
        local event = entity:WithObject()
        if  type_str == 'MARCH_OUT'  or type_str == 'STRIKE_OUT' then
            local item = self:CreateAttackItem(entity)
            self.items_map[event:Id()] = item
            table.insert(items,item)
        elseif type_str == 'MARCH_RETURN' or type_str == 'STRIKE_RETURN' then
            local item = self:CreateReturnItem(entity)
            self.items_map[event:Id()] = item
            table.insert(items,item )
        elseif type_str == 'COLLECT' then
            local item = self:CreateDefenceItem(entity)
            self.items_map[event:Id()] = item
            table.insert(items, item)
        elseif type_str == 'SHIRNE' then
            local item = self:CreateDefenceItem(entity)
            item.speed_btn:setButtonEnabled(false) -- 圣地事件没有撤军功能
            self.items_map[event:Id()] = item
            table.insert(items, item)
        elseif type_str == 'HELPTO' then
            local item = self:CreateDefenceItem(entity)
            -- self.items_map[event:Id()] = item
            table.insert(items, item)
        end
    end
    self:InsertItem(items)
    self:ResizeBelowHorizon(self:Length(#self.item_array))
end

function WidgetMarchEvents:Length(array_len)
    return array_len * ITEM_HEIGHT + 2
end

function WidgetMarchEvents:ResizeBelowHorizon(new_height)
    local height = new_height < ITEM_HEIGHT and ITEM_HEIGHT or new_height
    local size = self.back_ground:getContentSize()
    self.back_ground:setContentSize(cc.size(size.width, height))
    self.node:setPositionY(- height)
    self.hide_btn:setPositionY(height)
end
-- 只有加速按钮和部队
function WidgetMarchEvents:CreateReturnItem(entity)
    local event = entity:WithObject()
    local node = display.newSprite("tab_event_bar.png"):align(display.LEFT_CENTER)
    local half_height = node:getContentSize().height / 2
    node.progress = display.newProgressTimer("tab_progress_bar.png",
        display.PROGRESS_TIMER_BAR):addTo(node)
        :align(display.LEFT_CENTER, 4, half_height)
    node.progress:setBarChangeRate(cc.p(1,0))
    node.progress:setMidpoint(cc.p(0,0))
    node.progress:setPercentage(event:GetPercent())
    WidgetPushTransparentButton.new(cc.rect(0,0,469,41)):onButtonClicked(function()
        display.getRunningScene():GetSceneLayer():TrackCorpsById(event:Id())
    end):addTo(node):align(display.LEFT_CENTER, 4, half_height)
    node.prefix = entity:GetEventPrefix()
    node.desc = UIKit:ttfLabel({
        text = node.prefix,
        size = 18,
        color = 0xd1ca95,
        shadow = true,
    }):addTo(node):align(display.LEFT_CENTER, 10, half_height)

    node.time = UIKit:ttfLabel({
        text = GameUtils:formatTimeStyle1(event:GetTime()),
        size = 18,
        color = 0xd1ca95,
        align = cc.TEXT_ALIGNMENT_RIGHT,
        shadow = true,
    }):addTo(node):align(display.RIGHT_CENTER, WIDGET_WIDTH - 170, half_height)
    node.speed_btn = WidgetPushButton.new({
        normal = "march_speedup_btn_up.png",
        pressed = "march_speedup_btn_down.png",
        disabled= "disable_75x39.png",
    }):addTo(node):align(display.RIGHT_CENTER, WIDGET_WIDTH - 6, half_height)
        :setButtonLabel(UIKit:commonButtonLable({
            text = _("加速"),
            size = 18,
            color= 0xfff3c7,
            shadow = true,
        }))
        :onButtonClicked(function()
            self:OnSpeedUpButtonClicked(entity)
        end)


    node.return_btn = WidgetPushButton.new({
        normal = "yellow_btn_up_75x39.png",
        pressed = "yellow_btn_down_75x39.png",
        disabled= "disable_75x39.png",
    }):addTo(node):align(display.RIGHT_CENTER, WIDGET_WIDTH - 84, half_height)
        :setButtonLabel(UIKit:commonButtonLable({
            text = _("部队"),
            size = 18,
            color= 0xfff3c7,
            shadow = true,
        }))
        :onButtonClicked(function()
            self:OnInfoButtonClicked(entity)
        end)
    return node
end
--加速和撤退
function WidgetMarchEvents:CreateAttackItem(entity)
    local event = entity:WithObject()
    local node = display.newSprite("tab_event_bar.png"):align(display.LEFT_CENTER)
    local half_height = node:getContentSize().height / 2
    node.progress = display.newProgressTimer("tab_progress_bar.png",
        display.PROGRESS_TIMER_BAR):addTo(node)
        :align(display.LEFT_CENTER, 4, half_height)
    node.progress:setBarChangeRate(cc.p(1,0))
    node.progress:setMidpoint(cc.p(0,0))
    node.progress:setPercentage(event:GetPercent())
    WidgetPushTransparentButton.new(cc.rect(0,0,469,41)):onButtonClicked(function()
       display.getRunningScene():GetSceneLayer():TrackCorpsById(event:Id())
    end):addTo(node):align(display.LEFT_CENTER, 4, half_height)
    node.prefix = entity:GetEventPrefix()
    node.desc = UIKit:ttfLabel({
        text = node.prefix,
        size = 18,
        color = 0xd1ca95,
        shadow = true,
    }):addTo(node):align(display.LEFT_CENTER, 10, half_height)

    node.time = UIKit:ttfLabel({
        text = GameUtils:formatTimeStyle1(event:GetTime()),
        size = 18,
        color = 0xd1ca95,
        align = cc.TEXT_ALIGNMENT_RIGHT,
        shadow = true,
    }):addTo(node):align(display.RIGHT_CENTER, WIDGET_WIDTH - 170, half_height)

    node.speed_btn = WidgetPushButton.new({
        normal = "march_speedup_btn_up.png",
        pressed = "march_speedup_btn_down.png",
        disabled= "disable_75x39.png",
    }):addTo(node):align(display.RIGHT_CENTER, WIDGET_WIDTH - 6, half_height)
        :setButtonLabel(UIKit:commonButtonLable({
            text = _("加速"),
            size = 18,
            color= 0xfff3c7,
            shadow = true,
        }))
        :onButtonClicked(function()
            self:OnSpeedUpButtonClicked(entity)
        end)


    node.return_btn = WidgetPushButton.new({
        normal = "march_return_btn_up.png",
        pressed = "march_return_btn_down.png",
        disabled= "disable_75x39.png",
    }):addTo(node):align(display.RIGHT_CENTER, WIDGET_WIDTH - 84, half_height)
        :setButtonLabel(UIKit:commonButtonLable({
            text = _("撤退"),
            size = 18,
            color= 0xfff3c7,
            shadow = true,
        }))
        :onButtonClicked(function()
            self:OnRetreatButtonClicked(entity)
        end)
    return node
end
--只有撤退和部队
function WidgetMarchEvents:CreateDefenceItem(entity)
    local event = entity:WithObject()
    local type_str = entity:GetTypeStr()
    local node = display.newSprite("tab_event_bar.png"):align(display.LEFT_CENTER)
    local half_height = node:getContentSize().height / 2
    node.progress = display.newProgressTimer("tab_progress_bar.png",
        display.PROGRESS_TIMER_BAR):addTo(node)
        :align(display.LEFT_CENTER, 4, half_height)
    node.progress:setBarChangeRate(cc.p(1,0))
    node.progress:setMidpoint(cc.p(0,0))
    WidgetPushTransparentButton.new(cc.rect(0,0,469,41)):onButtonClicked(function()
        self:MoveToTargetAction(entity)
    end):addTo(node):align(display.LEFT_CENTER, 4, half_height)
    local display_text = ""
    node.prefix = entity:GetEventPrefix()
    local time_str = ""
    if type_str == 'COLLECT' then
        node.progress:setPercentage(event:CollectPercent())
        display_text = string.format(" %s %d%%", node.prefix,event:CollectPercent())
        time_str = GameUtils:formatTimeStyle1(event:GetTime())
    elseif type_str == 'SHIRNE' then
       node.progress:setPercentage(100)
       display_text = node.prefix
       time_str = ""
    elseif type_str == 'HELPTO' then
        node.progress:setPercentage(100)
       display_text = node.prefix
       time_str = ""
    end
    node.desc = UIKit:ttfLabel({
        text = display_text,
        size = 18,
        color = 0xd1ca95,
        shadow = true,
    }):addTo(node):align(display.LEFT_CENTER, 10, half_height)

    node.time = UIKit:ttfLabel({
        text = time_str,
        size = 18,
        color = 0xd1ca95,
        align = cc.TEXT_ALIGNMENT_RIGHT,
        shadow = true,
    }):addTo(node):align(display.RIGHT_CENTER, WIDGET_WIDTH - 170, half_height)

    node.speed_btn = WidgetPushButton.new({
        normal = "march_return_btn_up.png",
        pressed = "march_return_btn_down.png",
        disabled= "disable_75x39.png",
    }):addTo(node):align(display.RIGHT_CENTER, WIDGET_WIDTH - 6, half_height)
        :setButtonLabel(UIKit:commonButtonLable({
            text = _("撤军"),
            size = 18,
            color= 0xfff3c7,
            shadow = true,
        }))
        :onButtonClicked(function()
            self:OnRetreatButtonClicked(entity)
        end)


    node.return_btn = WidgetPushButton.new({
        normal = "yellow_btn_up_75x39.png",
        pressed = "yellow_btn_down_75x39.png",
        disabled= "disable_75x39.png",
    }):addTo(node):align(display.RIGHT_CENTER, WIDGET_WIDTH - 84, half_height)
        :setButtonLabel(UIKit:commonButtonLable({
            text = _("部队"),
            size = 18,
            color= 0xfff3c7,
            shadow = true,
        }))
        :onButtonClicked(function()
            self:OnInfoButtonClicked(entity)
        end)
    return node
end

function WidgetMarchEvents:HasAnyMarchEvent()
    local alliance_belvedere = self:GetAllianceBelvedere()
    local hasEvent,__ = alliance_belvedere:HasMyEvents()
    return hasEvent
end

function WidgetMarchEvents:OnSpeedUpButtonClicked(entity)
    local widgetUseItems = WidgetUseItems.new():Create({
        item_type = WidgetUseItems.USE_TYPE.WAR_SPEEDUP_CLASS,
        event = entity
    })
    widgetUseItems:AddToCurrentScene()
end

function WidgetMarchEvents:OnRetreatButtonClicked(entity,cb)
    cb = cb or function(...)end
    if entity:GetType() == entity.ENTITY_TYPE.HELPTO then
        UIKit:showMessageDialog(_("提示"),_("确定撤军?"),function()
            NetManager:getRetreatFromHelpedAllianceMemberPromise(entity:WithObject().beHelpedPlayerData.id)
                :done(function()
                    cb(true)
                end)
                :fail(function()
                    cb(false)
                end)
        end)
    elseif entity:GetType() == entity.ENTITY_TYPE.COLLECT then
        UIKit:showMessageDialog(_("提示"),_("确定撤军?"),function()
            NetManager:getRetreatFromVillagePromise(entity:WithObject():VillageData().alliance.id,entity:WithObject():Id())
            :done(function()
                cb(true)
            end):fail(function()
                cb(false)
            end)
        end)
    elseif entity:GetType() == entity.ENTITY_TYPE.MARCH_OUT  or entity:GetType() == entity.ENTITY_TYPE.STRIKE_OUT then
        local widgetUseItems = WidgetUseItems.new():Create({
            item_type = WidgetUseItems.USE_TYPE.RETREAT_TROOP,
            event = entity
        })
        widgetUseItems:AddToCurrentScene()
    end
end

function WidgetMarchEvents:MoveToTargetAction(entity)
    local type_str = entity:GetTypeStr()
    local location,alliance_id
    if type_str == 'SHIRNE' or type_str == 'HELPTO' then
       location = entity:GetDestinationLocationNotString()
       alliance_id = Alliance_Manager:GetMyAlliance():Id()
    else
        location,alliance_id = entity:GetDestinationLocationNotString()
    end
    local map_layer = display.getRunningScene():GetSceneLayer()
    local point = map_layer:ConvertLogicPositionToMapPosition(location.x,location.y,alliance_id)
    map_layer:GotoMapPositionInMiddle(point.x,point.y)
end

function WidgetMarchEvents:OnInfoButtonClicked(entity)
    UIKit:newGameUI("GameUIWatchTowerMyTroopsDetail",entity):AddToCurrentScene(true)
end
return WidgetMarchEvents
