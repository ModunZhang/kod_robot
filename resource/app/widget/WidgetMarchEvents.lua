local promise = import("..utils.promise")
local Alliance = import("..entity.Alliance")
local cocos_promise = import("..utils.cocos_promise")
local WidgetPushButton = import("..widget.WidgetPushButton")
local WidgetUseItems = import("..widget.WidgetUseItems")
local UILib = import("..ui.UILib")
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
function WidgetMarchEvents:OnUserDataChanged_helpToTroops(userData, deltaData)
    self:PromiseOfSwitch()
end
local function HasMyEvent(ok, events)
    if ok then
        for i,v in ipairs(events) do
            if v.attackPlayerData.id == User._id then
                return true
            end
        end
    end
end
function WidgetMarchEvents:OnAllianceDataChanged_marchEvents(userData, deltaData) 
    if HasMyEvent(deltaData("marchEvents.attackMarchEvents.add"))
    or HasMyEvent(deltaData("marchEvents.attackMarchEvents.edit"))
    or HasMyEvent(deltaData("marchEvents.attackMarchEvents.remove"))
    --
    or HasMyEvent(deltaData("marchEvents.attackMarchReturnEvents.add"))
    or HasMyEvent(deltaData("marchEvents.attackMarchReturnEvents.edit"))
    or HasMyEvent(deltaData("marchEvents.attackMarchReturnEvents.remove"))
    --
    or HasMyEvent(deltaData("marchEvents.strikeMarchEvents.add"))
    or HasMyEvent(deltaData("marchEvents.strikeMarchEvents.edit"))
    or HasMyEvent(deltaData("marchEvents.strikeMarchEvents.remove"))
    --
    or HasMyEvent(deltaData("marchEvents.strikeMarchReturnEvents.add"))
    or HasMyEvent(deltaData("marchEvents.strikeMarchReturnEvents.edit"))
    or HasMyEvent(deltaData("marchEvents.strikeMarchReturnEvents.remove"))
    then
        self:PromiseOfSwitch()
    end
end
function WidgetMarchEvents:OnAllianceDataChanged_villageEvents(userData, deltaData)
    if deltaData("villageEvents.add")
    or deltaData("villageEvents.edit")
    or deltaData("villageEvents.remove") then
        self:PromiseOfSwitch()
    end
end
    

function WidgetMarchEvents:AddOrRemoveAllianceEvent(isAdd)
    local User = User
    local alliance = Alliance_Manager:GetMyAlliance()
    if isAdd then
        User:AddListenOnType(self, "helpToTroops")
        alliance:AddListenOnType(self, "marchEvents")
        alliance:AddListenOnType(self, "villageEvents")
    else
        User:RemoveListenerOnType(self, "helpToTroops")
        alliance:RemoveListenerOnType(self, "marchEvents")
        alliance:RemoveListenerOnType(self, "villageEvents")
    end
end

---------------------------
function WidgetMarchEvents:ctor(ratio)
    self:setNodeEventEnabled(true)
    self.view_rect = cc.rect(0, 0, WIDGET_WIDTH * ratio, (WIDGET_HEIGHT) * ratio)
    self:setClippingRegion(self.view_rect)

    self.item_array = {}
    self.node = display.newNode():addTo(self):scale(ratio)
    cc.Layer:create():addTo(self.node):pos(0, -WIDGET_HEIGHT):setContentSize(cc.size(WIDGET_WIDTH, WIDGET_HEIGHT)):setCascadeOpacityEnabled(true)
    self.hide_btn = self:CreateHideButton():addTo(self.node)
    self.back_ground = self:CreateBackGround():addTo(self.node)
    self:Reset()
end
function WidgetMarchEvents:onEnter()
    self:AddOrRemoveAllianceEvent(true)
    if self:HasAnyMarchEvent() then
        self:PromiseOfSwitch()
    end
    scheduleAt(self, function()
        self:IteratorItems(function(v)
            if v.eventType == "attackMarchEvents" 
            or v.eventType == "attackMarchReturnEvents"
            or v.eventType == "strikeMarchEvents"
            or v.eventType == "strikeMarchReturnEvents"
                then
                local time, percent = UtilsForEvent:GetEventInfo(v.event)
                v.time:setString(GameUtils:formatTimeStyle1(time))
                v.progress:setPercentage(percent)
            elseif v.eventType == "villageEvents" then
                local time, percent = UtilsForEvent:GetEventInfo(v.event)
                local collectCount, collectPercent = UtilsForEvent:GetCollectPercent(v.event)
                v.desc:setString(string.format("%s %d%%", v.prefix, collectPercent))
                v.time:setString(GameUtils:formatTimeStyle1(time))
                v.progress:setPercentage(collectPercent)
            elseif v.eventType == "shrineEvents" then
                local time = UtilsForShrine:GetEventTime(v.event)
                v.time:setString(GameUtils:formatTimeStyle1(time))
            end
        end)
    end)
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
    self.back_ground:removeAllChildren()
    self.item_array = {}
    self:ResizeBelowHorizon(0)
    self.node:stopAllActions()
    self.arrow:flipY(true)
    self:Lock(false)
    self:setVisible(self:HasAnyMarchEvent())
end

function WidgetMarchEvents:Load()
    local items = {}
    local alliance = Alliance_Manager:GetMyAlliance()
    for i,v in ipairs(alliance.marchEvents.strikeMarchEvents) do
        if UtilsForEvent:IsMyMarchEvent(v) then
            local item = self:CreateAttackItem(v, "strikeMarchEvents")
            table.insert(items, item)
        end
    end
    for i,v in ipairs(alliance.marchEvents.strikeMarchReturnEvents) do
        if UtilsForEvent:IsMyMarchEvent(v) then
            local item = self:CreateReturnItem(v, "strikeMarchReturnEvents")
            table.insert(items, item)
        end
    end
    for i,v in ipairs(alliance.marchEvents.attackMarchEvents) do
        if UtilsForEvent:IsMyMarchEvent(v) then
            local item = self:CreateAttackItem(v, "attackMarchEvents")
            table.insert(items, item)
        end
    end
    for i,v in ipairs(alliance.marchEvents.attackMarchReturnEvents) do
        if UtilsForEvent:IsMyMarchEvent(v) then
            local item = self:CreateReturnItem(v, "attackMarchReturnEvents")
            table.insert(items, item)
        end
    end
    for i,v in ipairs(alliance.villageEvents) do
        if UtilsForEvent:IsMyVillageEvent(v) then
            local item = self:CreateDefenceItem(v, "villageEvents")
            table.insert(items, item)
        end
    end
    for i,v in ipairs(User.helpToTroops) do
        local item = self:CreateDefenceItem(v, "helpToTroops")
        table.insert(items, item)
    end
    for _,event in ipairs(alliance.shrineEvents) do
        for _,v in ipairs(event.playerTroops) do
            if v.id == User._id then
                local item = self:CreateDefenceItem(event, "shrineEvents")
                table.insert(items, item)
                break
            end
        end
    end
    self:InsertItem(items)
    self:ResizeBelowHorizon(self:Length(#self.item_array))
end

function WidgetMarchEvents:Length(array_len)
    return array_len * ITEM_HEIGHT
end

function WidgetMarchEvents:ResizeBelowHorizon(new_height)
    local height = new_height < ITEM_HEIGHT and ITEM_HEIGHT or new_height
    local size = self.back_ground:getContentSize()
    self.back_ground:setContentSize(cc.size(size.width, height))
    self.node:setPositionY(- height)
    self.hide_btn:setPositionY(height - 1)
end
function WidgetMarchEvents:GetDragonHead(dragon_type)
    -- 龙图标
    local dragon_bg_1 = display.newSprite("back_ground_15x43.png")
    local dragon_bg = display.newSprite("back_ground_43x43_1.png")
        :align(display.LEFT_CENTER,0,dragon_bg_1:getContentSize().height/2)
        :addTo(dragon_bg_1)
    display.newSprite(UILib.small_dragon_head[dragon_type])
        :align(display.CENTER, dragon_bg:getContentSize().width/2, dragon_bg:getContentSize().height/2)
        :addTo(dragon_bg)
    return dragon_bg_1
end
-- 只有加速按钮和部队
function WidgetMarchEvents:CreateReturnItem(event, eventType)
    local node = display.newSprite("tab_event_bar.png"):align(display.LEFT_CENTER)
    local half_height = node:getContentSize().height / 2
    node.progress = display.newProgressTimer("tab_progress_bar.png",
        display.PROGRESS_TIMER_BAR):addTo(node)
        :align(display.LEFT_CENTER, 4, half_height)
    node.progress:setBarChangeRate(cc.p(1,0))
    node.progress:setMidpoint(cc.p(0,0))
    local time, percent = UtilsForEvent:GetEventInfo(event)
    node.progress:setPercentage(percent)
    WidgetPushTransparentButton.new(cc.rect(0,0,469,41)):onButtonClicked(function()
        display.getRunningScene():GetSceneLayer():TrackCorpsById(event.id)
    end):addTo(node):align(display.LEFT_CENTER, 4, half_height)

    self:GetDragonHead(event.attackPlayerData.dragon.type):align(display.LEFT_CENTER, 2, half_height)
        :addTo(node)

    node.prefix = UtilsForEvent:GetMarchReturnEventPrefix(event)
    node.desc = UIKit:ttfLabel({
        text = node.prefix,
        size = 18,
        color = 0xd1ca95,
        shadow = true,
    }):addTo(node):align(display.LEFT_CENTER, 55, half_height)

    node.time = UIKit:ttfLabel({
        text = GameUtils:formatTimeStyle1(time),
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
            size = 16,
            color= 0xfff3c7,
            shadow = true,
        }))
        :onButtonClicked(function()
            self:OnSpeedUpButtonClicked(event, eventType)
        end)


    node.return_btn = WidgetPushButton.new({
        normal = "yellow_btn_up_75x39.png",
        pressed = "yellow_btn_down_75x39.png",
        disabled= "disable_75x39.png",
    }):addTo(node):align(display.RIGHT_CENTER, WIDGET_WIDTH - 84, half_height)
        :setButtonLabel(UIKit:commonButtonLable({
            text = _("部队"),
            size = 16,
            color= 0xfff3c7,
            shadow = true,
        }))
        :onButtonClicked(function()
            self:OnInfoButtonClicked(event, eventType)
        end)
    node.eventType = eventType
    node.event = event
    return node
end
--加速和撤退
function WidgetMarchEvents:CreateAttackItem(event, eventType)
    local node = display.newSprite("tab_event_bar.png"):align(display.LEFT_CENTER)
    local half_height = node:getContentSize().height / 2
    node.progress = display.newProgressTimer("tab_progress_bar.png",
        display.PROGRESS_TIMER_BAR):addTo(node)
        :align(display.LEFT_CENTER, 4, half_height)
    node.progress:setBarChangeRate(cc.p(1,0))
    node.progress:setMidpoint(cc.p(0,0))
    local time, percent = UtilsForEvent:GetEventInfo(event)
    node.progress:setPercentage(percent)
    WidgetPushTransparentButton.new(cc.rect(0,0,469,41)):onButtonClicked(function()
        display.getRunningScene():GetSceneLayer():TrackCorpsById(event.id)
    end):addTo(node):align(display.LEFT_CENTER, 4, half_height)

    self:GetDragonHead(event.attackPlayerData.dragon.type):align(display.LEFT_CENTER, 2, half_height)
        :addTo(node)

    node.prefix = UtilsForEvent:GetMarchEventPrefix(event, eventType)
    node.desc = UIKit:ttfLabel({
        text = node.prefix,
        size = 18,
        color = 0xd1ca95,
        shadow = true,
    }):addTo(node):align(display.LEFT_CENTER, 55, half_height)

    node.time = UIKit:ttfLabel({
        text = GameUtils:formatTimeStyle1(time),
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
            size = 16,
            color= 0xfff3c7,
            shadow = true,
        }))
        :onButtonClicked(function()
            self:OnSpeedUpButtonClicked(event, eventType)
        end)


    node.return_btn = WidgetPushButton.new({
        normal = "march_return_btn_up.png",
        pressed = "march_return_btn_down.png",
        disabled= "disable_75x39.png",
    }):addTo(node):align(display.RIGHT_CENTER, WIDGET_WIDTH - 84, half_height)
        :setButtonLabel(UIKit:commonButtonLable({
            text = _("撤退"),
            size = 16,
            color= 0xfff3c7,
            shadow = true,
        }))
        :onButtonClicked(function()
            self:OnRetreatButtonClicked(event, eventType)
        end)
    node.eventType = eventType
    node.event = event
    return node
end
--只有撤退和部队
function WidgetMarchEvents:CreateDefenceItem(event, eventType)
    local node = display.newSprite("tab_event_bar.png"):align(display.LEFT_CENTER)
    local half_height = node:getContentSize().height / 2
    node.progress = display.newProgressTimer("tab_progress_bar.png",
        display.PROGRESS_TIMER_BAR):addTo(node)
        :align(display.LEFT_CENTER, 4, half_height)
    node.progress:setBarChangeRate(cc.p(1,0))
    node.progress:setMidpoint(cc.p(0,0))
    WidgetPushTransparentButton.new(cc.rect(0,0,469,41)):onButtonClicked(function()
        self:MoveToTargetAction(event,eventType)
    end):addTo(node):align(display.LEFT_CENTER, 4, half_height)
    local time_str = ""
    local display_text = ""
    local dragonType = ""
    if eventType == "villageEvents" then
        node.prefix = UtilsForEvent:GetVillageEventPrefix(event)
        local time, percent = UtilsForEvent:GetEventInfo(event)
        time_str = GameUtils:formatTimeStyle1(time)
        local collectCount, collectPercent = UtilsForEvent:GetCollectPercent(event)
        display_text = string.format("%s %d%%", node.prefix, collectPercent)
        node.progress:setPercentage(collectPercent)
        dragonType = event.playerData.dragon.type
    elseif eventType == "helpToTroops" then
        local target_pos = event.beHelpedPlayerData.location.x .. "," .. event.beHelpedPlayerData.location.y
        node.prefix = string.format(_("正在协防 %s (%s)"), 
                event.beHelpedPlayerData.name, target_pos)
        node.progress:setPercentage(100)
        display_text = node.prefix
        time_str = ""
        dragonType = event.playerDragon
    elseif eventType == "shrineEvents" then
        node.prefix = UtilsForEvent:GetMarchEventPrefix(event, eventType)
        display_text = node.prefix
        node.progress:setPercentage(100)
        local time = UtilsForShrine:GetEventTime(event)
        time_str = GameUtils:formatTimeStyle1(time)
        for i,v in ipairs(event.playerTroops) do
            if v.id == User._id then
                dragonType = v.dragon.type
            end
        end
    end
    self:GetDragonHead(dragonType):align(display.LEFT_CENTER, 2, half_height)
            :addTo(node)
    node.desc = UIKit:ttfLabel({
        text = display_text,
        size = 18,
        color = 0xd1ca95,
        shadow = true,
    }):addTo(node):align(display.LEFT_CENTER, 55, half_height)

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
            size = 16,
            color= 0xfff3c7,
            shadow = true,
        }))
        :onButtonClicked(function()
            self:OnRetreatButtonClicked(event, eventType)
        end):setButtonEnabled(eventType ~= "shrineEvents")


    node.return_btn = WidgetPushButton.new({
        normal = "yellow_btn_up_75x39.png",
        pressed = "yellow_btn_down_75x39.png",
        disabled= "disable_75x39.png",
    }):addTo(node):align(display.RIGHT_CENTER, WIDGET_WIDTH - 84, half_height)
        :setButtonLabel(UIKit:commonButtonLable({
            text = _("部队"),
            size = 16,
            color= 0xfff3c7,
            shadow = true,
        }))
        :onButtonClicked(function()
            self:OnInfoButtonClicked(event, eventType)
        end)
    node.eventType = eventType
    node.event = event
    return node
end

function WidgetMarchEvents:HasAnyMarchEvent()
    if #User.helpToTroops > 0 then
        return true
    end
    local alliance = Alliance_Manager:GetMyAlliance()
    for i,v in ipairs(alliance.marchEvents.strikeMarchEvents) do
        if UtilsForEvent:IsMyMarchEvent(v) then
            return true
        end
    end
    for i,v in ipairs(alliance.marchEvents.strikeMarchReturnEvents) do
        if UtilsForEvent:IsMyMarchEvent(v) then
            return true
        end
    end
    for i,v in ipairs(alliance.marchEvents.attackMarchEvents) do
        if UtilsForEvent:IsMyMarchEvent(v) then
            return true
        end
    end
    for i,v in ipairs(alliance.marchEvents.attackMarchReturnEvents) do
        if UtilsForEvent:IsMyMarchEvent(v) then
            return true
        end
    end
    for i,v in ipairs(alliance.villageEvents) do
        if UtilsForEvent:IsMyVillageEvent(v) then
            return true
        end
    end
    for _,v in ipairs(alliance.shrineEvents) do
        for _,v in ipairs(v.playerTroops) do
            if v.id == User._id then
                return true
            end
        end
    end
    return false
end

function WidgetMarchEvents:OnSpeedUpButtonClicked(event, eventType)
    local widgetUseItems = WidgetUseItems.new():Create({
        item_name = "warSpeedupClass_1",
        event = event,
        eventType = eventType,
    })
    widgetUseItems:AddToCurrentScene()
end

function WidgetMarchEvents:OnRetreatButtonClicked(event, eventType)
    if event.marchType == "village"
    or event.marchType == "helpDefence"
    or event.marchType == "city"
    or event.marchType == "monster"
    then
        local widgetUseItems = WidgetUseItems.new():Create({
            item_name = "retreatTroop",
            event = event,
            eventType = eventType,
        })
        widgetUseItems:AddToCurrentScene()
    elseif eventType == "villageEvents" then
        UIKit:showMessageDialog(_("提示"),_("确定撤军?"),function()
            NetManager:getRetreatFromVillagePromise(event.id)
        end)
    elseif eventType == "helpToTroops" then
        UIKit:showMessageDialog(_("提示"),_("确定撤军?"),function()
            NetManager:getRetreatFromHelpedAllianceMemberPromise(event.beHelpedPlayerData.id)
        end)
    end
end

function WidgetMarchEvents:MoveToTargetAction(event,eventType)
    dump(event,"event")
    local location,mapIndex
    if eventType == 'helpToTroops' then
        location = event.beHelpedPlayerData.location
        mapIndex = Alliance_Manager:GetMyAlliance().mapIndex
    elseif eventType == 'shrineEvents' then
        location = Alliance_Manager:GetMyAlliance():GetShrinePosition()
        mapIndex = Alliance_Manager:GetMyAlliance().mapIndex
    else
        location = event.toAlliance.location
        if event.toAlliance.id == Alliance_Manager:GetMyAlliance()._id then
            mapIndex = Alliance_Manager:GetMyAlliance().mapIndex
        else
            mapIndex = event.toAlliance.mapIndex
        end
    end
    local map_layer = display.getRunningScene():GetSceneLayer()
    map_layer:TrackCorpsById(nil)
    local point = map_layer:RealPosition(mapIndex,location.x,location.y)
    map_layer:GotoMapPositionInMiddle(point.x,point.y)
end

function WidgetMarchEvents:OnInfoButtonClicked(event, eventType)
    UIKit:newGameUI("GameUIWatchTowerMyTroopsDetail", event, eventType):AddToCurrentScene(true)
end
return WidgetMarchEvents


