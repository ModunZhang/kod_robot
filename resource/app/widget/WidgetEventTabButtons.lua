local promise = import("..utils.promise")
local cocos_promise = import("..utils.cocos_promise")
local Localize = import("..utils.Localize")
local WidgetPushButton = import("..widget.WidgetPushButton")
local WidgetTab = import(".WidgetTab")
local timer = app.timer
local WIDGET_WIDTH = 640
local WIDGET_HEIGHT = 300
local TAB_HEIGHT = 42
local ITEM_HEIGHT = 47
local WidgetEventTabButtons = class("WidgetEventTabButtons", function()
    local rect = cc.rect(0, 0, WIDGET_WIDTH, WIDGET_HEIGHT + TAB_HEIGHT)
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
function WidgetEventTabButtons:isTouchInViewRect(event)
    local viewRect = self:convertToWorldSpace(cc.p(self.view_rect.x, self.view_rect.y))
    viewRect.width = self.view_rect.width
    viewRect.height = self.view_rect.height
    return cc.rectContainsPoint(viewRect, cc.p(event.x, event.y))
end
function WidgetEventTabButtons:OnUserDataChanged_buildings(userData, deltaData)
    self:RefreshBuildQueueByType("build", "soldier", "material", "technology")
end
function WidgetEventTabButtons:OnUserDataChanged_houseEvents(userData, deltaData)
    if deltaData("houseEvents.add")
        or deltaData("houseEvents.edit") then
        self:EventChangeOn("build", true)
        self:RefreshBuildQueueByType("build")
    elseif deltaData("houseEvents.remove") then
        self:EventChangeOn("build")
        self:RefreshBuildQueueByType("build", "soldier", "material", "technology")
        app:GetAudioManager():PlayeEffectSoundWithKey("COMPLETE")
    end
end
function WidgetEventTabButtons:OnUserDataChanged_buildingEvents(userData, deltaData)
    if deltaData("buildingEvents.add")
        or deltaData("buildingEvents.edit") then
        self:EventChangeOn("build", true)
        self:RefreshBuildQueueByType("build")
    elseif deltaData("buildingEvents.remove") then
        self:EventChangeOn("build")
        self:RefreshBuildQueueByType("build", "soldier", "material", "technology")
        app:GetAudioManager():PlayeEffectSoundWithKey("COMPLETE")
    end
end
function WidgetEventTabButtons:OnUserDataChanged_dragonEquipmentEvents(userData, deltaData)
    if deltaData("dragonEquipmentEvents.add")
        or deltaData("dragonEquipmentEvents.edit") then
        self:EventChangeOn("material", true)
    elseif deltaData("dragonEquipmentEvents.remove") then
        self:EventChangeOn("material")
        app:GetAudioManager():PlayeEffectSoundWithKey("COMPLETE")
    end
    self:RefreshBuildQueueByType("material")
end
function WidgetEventTabButtons:OnUserDataChanged_materialEvents(userData, deltaData)
    local ok, value = deltaData("materialEvents.edit")
    if ok then
        if value[1].finishTime == 0 then
            self:EventChangeOn("material")
            app:GetAudioManager():PlayeEffectSoundWithKey("COMPLETE")
        end
        self:EventChangeOn("material", true)
    elseif deltaData("materialEvents.add") then
        self:EventChangeOn("material", true)
    end
    self:RefreshBuildQueueByType("material")
end
function WidgetEventTabButtons:OnUserDataChanged_soldierEvents(userData, deltaData)
    if deltaData("soldierEvents.add")
        or deltaData("soldierEvents.edit") then
        self:EventChangeOn("soldier", true)
    elseif deltaData("soldierEvents.remove") then
        self:EventChangeOn("soldier")
        app:GetAudioManager():PlayeEffectSoundWithKey("COMPLETE")
    end
    self:RefreshBuildQueueByType("soldier")
end
function WidgetEventTabButtons:OnUserDataChanged_militaryTechEvents(userData, deltaData)
    if deltaData("militaryTechEvents.add")
        or deltaData("militaryTechEvents.edit") then
        self:EventChangeOn("technology", true)
    elseif deltaData("militaryTechEvents.remove") then
        self:EventChangeOn("technology")
        app:GetAudioManager():PlayeEffectSoundWithKey("COMPLETE")
    end
    self:RefreshBuildQueueByType("technology")
end
function WidgetEventTabButtons:OnUserDataChanged_soldierStarEvents(userData, deltaData)
    if deltaData("soldierStarEvents.add")
        or deltaData("soldierStarEvents.edit") then
        self:EventChangeOn("technology", true)
    elseif deltaData("soldierStarEvents.remove") then
        self:EventChangeOn("technology")
        app:GetAudioManager():PlayeEffectSoundWithKey("COMPLETE")
    end
    self:RefreshBuildQueueByType("technology")
end
function WidgetEventTabButtons:OnUserDataChanged_productionTechEvents(userData, deltaData)
    if deltaData("productionTechEvents.add")
        or deltaData("productionTechEvents.edit") then
        self:EventChangeOn("technology", true)
    elseif deltaData("productionTechEvents.remove") then
        self:EventChangeOn("technology")
        app:GetAudioManager():PlayeEffectSoundWithKey("COMPLETE")
    end
    self:RefreshBuildQueueByType("technology")
end
function WidgetEventTabButtons:EventChangeOn(event_type, is_begin)
    self:RefreshBuildQueueByType(event_type)
    if is_begin then
        self:PromiseOfShowTab(event_type)
    else
        if self:GetCurrentTab() == event_type then
            self:PromiseOfSwitch()
        end
    end
end
------
function WidgetEventTabButtons:ctor(city, ratio)
    self.view_rect = cc.rect(0, 0, WIDGET_WIDTH * ratio, (WIDGET_HEIGHT + TAB_HEIGHT) * ratio)
    self:setClippingRegion(self.view_rect)

    self.item_array = {}
    local node = display.newNode():addTo(self):scale(ratio)

    cc.Layer:create():addTo(node):pos(0, -WIDGET_HEIGHT + TAB_HEIGHT)
        :setContentSize(cc.size(WIDGET_WIDTH, WIDGET_HEIGHT + TAB_HEIGHT))
        :setCascadeOpacityEnabled(true)

    self.node = node
    self.tab_buttons, self.tab_map = self:CreateTabButtons()
    self.tab_buttons:addTo(node, 2):pos(0, 0)
    self.back_ground = self:CreateBackGround():addTo(node)

    self.city = city
    local User = city:GetUser()

    self:Reset()
    self:ShowStartEvent()
    self:RefreshBuildQueueByType("build", "soldier", "material", "technology")

    scheduleAt(self, function()
        if self:IsShowing() then return end
        self:RefreshAllEvents()
    end)

    User:AddListenOnType(self, "soldierEvents")
    User:AddListenOnType(self, "soldierStarEvents")
    User:AddListenOnType(self, "militaryTechEvents")
    User:AddListenOnType(self, "productionTechEvents")
    User:AddListenOnType(self, "materialEvents")
    User:AddListenOnType(self, "dragonEquipmentEvents")
    User:AddListenOnType(self, "houseEvents")
    User:AddListenOnType(self, "buildingEvents")
    User:AddListenOnType(self, "buildings")
end
function WidgetEventTabButtons:onExit()
    local User = city:GetUser()
    User:RemoveListenerOnType(self, "soldierEvents")
    User:RemoveListenerOnType(self, "soldierStarEvents")
    User:RemoveListenerOnType(self, "militaryTechEvents")
    User:RemoveListenerOnType(self, "productionTechEvents")
    User:RemoveListenerOnType(self, "materialEvents")
    User:RemoveListenerOnType(self, "dragonEquipmentEvents")
    User:RemoveListenerOnType(self, "houseEvents")
    User:RemoveListenerOnType(self, "buildingEvents")
    User:RemoveListenerOnType(self, "buildings")
end
function WidgetEventTabButtons:RefreshAllEvents()
    local event = User:GetShortestTechEvent()
    if event then
        local time, percent = UtilsForEvent:GetEventInfo(event)
        self:GetTabByKey("technology"):SetOrResetProgress(time, percent)
    else
        self:GetTabByKey("technology"):SetOrResetProgress(nil)
    end

    local event = User:GetSoldierEventsBySeq()[1]
    if event then
        local time, percent = UtilsForEvent:GetEventInfo(event)
        self:GetTabByKey("soldier"):SetOrResetProgress(time, percent)
    else
        self:GetTabByKey("soldier"):SetOrResetProgress(nil)
    end

    local event = User:GetMakingMaterialsEventsBySeq()[1]
    if event then
        local time, percent = UtilsForEvent:GetEventInfo(event)
        self:GetTabByKey("material"):SetOrResetProgress(time, percent)
    else
        self:GetTabByKey("material"):SetOrResetProgress(nil)
    end
    
    local event = UtilsForBuilding:GetBuildingEventsBySeq(User)[1]
    if event then
        local time, percent = UtilsForEvent:GetEventInfo(event)
        self:GetTabByKey("build"):SetOrResetProgress(time, percent)
    else
        self:GetTabByKey("build"):SetOrResetProgress(nil)
    end

    if self:IsShow() then
        if self:GetCurrentTab() == "technology" then
            self:IteratorAllItem(function(_, v)
                if v.event then
                    v:SetProgressInfo(self:TechDescribe(v.event))
                    self:SetProgressItemBtnLabel(
                        DataUtils:getFreeSpeedUpLimitTime()
                        >UtilsForEvent:GetEventInfo(v.event),
                        v
                    )
                end
            end)
        elseif self:GetCurrentTab() == "soldier" then
            self:IteratorAllItem(function(i, v)
                if i ~= 1 and v.event then
                    v:SetProgressInfo(self:SoldierDescribe(v.event))
                end
            end)
        elseif self:GetCurrentTab() == "material" then
            self:IteratorAllItem(function(i, v)
                if i ~= 1 and v.event then
                    if v.event.type then
                        v:SetProgressInfo(self:MaterialDescribe(v.event))
                    else
                        v:SetProgressInfo(self:EquipmentDescribe(v.event))
                    end
                end
            end)
        elseif self:GetCurrentTab() == "build" then
            self:IteratorAllItem(function(i, v)
                if i ~= 1 and v.event then
                    v:SetProgressInfo(self:BuildingDescribe(v.event))
                    self:SetProgressItemBtnLabel(
                        DataUtils:getFreeSpeedUpLimitTime()
                        >UtilsForEvent:GetEventInfo(v.event),
                        v)
                end
            end)
        end
    end
end
function WidgetEventTabButtons:RefreshBuildQueueByType(...)
    local city = self.city
    local User = self.city:GetUser()
    local cur_tab = self:GetCurrentTab()
    for _,key in ipairs{...} do
        local item = self.tab_map[key]
        local able = self:IsTabEnable(key)
        if key == "build" then
            local count = UtilsForBuilding:GetBuildingEventsCount(User)
            local total = User.basicInfo.buildQueue
            item:SetActiveNumber(count, total):Enable(able)
        elseif key == "soldier" then
            local count = #User.soldierEvents
            local total = #User:GetUnlockBuildingsBy("barracks")
            item:SetActiveNumber(count, total):Enable(able)
        elseif key == "material" then
            local count = 0
            count = count + #User.dragonEquipmentEvents
            count = count + User:GetMakingMaterialsEventCount()
            local total = 0
            total = total + #User:GetUnlockBuildingsBy("toolShop")
            total = total + #User:GetUnlockBuildingsBy("blackSmith")
            item:SetActiveNumber(count, total):Enable(able)
        elseif key == "technology" then
            local total = 0
            for i,v in ipairs({
                "academy",
                "trainingGround",
                "hunterHall",
                "stable",
                "workshop",
            }) do
                total = total + #User:GetUnlockBuildingsBy(v)
            end
            local count = User:GetTotalMilitaryTechEventsNumber() + #User.productionTechEvents
            item:SetActiveNumber(count, total):Enable(able)
        end
    end
end
function WidgetEventTabButtons:ShowStartEvent()
    if self:HasAnyBuildingEvent() then
        return self:PromiseOfShowTab("build")
    elseif self:HasAnySoldierEvent() then
        return self:PromiseOfShowTab("soldier")
    elseif self:HasAnyMaterialEvent() then
        return self:PromiseOfShowTab("material")
    elseif self:HasAnyTechnologyEvent() then
        return self:PromiseOfShowTab("technology")
    end
end
function WidgetEventTabButtons:HasAnyBuildingEvent()
    return UtilsForBuilding:GetBuildingEventsCount(self.city:GetUser())
end
function WidgetEventTabButtons:HasAnySoldierEvent()
    return #self.city:GetUser().soldierEvents > 0
end
function WidgetEventTabButtons:HasAnyMaterialEvent()
    local User = self.city:GetUser()
    return #User.dragonEquipmentEvents > 0 or User:IsMakingMaterials()
end
function WidgetEventTabButtons:HasAnyTechnologyEvent()
    return self.city:GetUser():HasAnyMilitaryTechEvent()
end
-- 构造ui
function WidgetEventTabButtons:CreateTabButtons()
    local node = display.newNode()
    display.newSprite("tab_background_578x50.png"):addTo(node):align(display.LEFT_BOTTOM)
    local origin_x = 138 * 4 + 28
    -- hide
    local btn = cc.ui.UIPushButton.new({normal = "hide_btn_up.png",
        pressed = "hide_btn_down.png"}):addTo(node)
        :align(display.LEFT_BOTTOM, origin_x, 0)
        :onButtonClicked(function(event)
            if not self:IsShow() then
                self:PromiseOfShow()
            else
                self:PromiseOfHide()
            end
        end)
    self.arrow = cc.ui.UIImage.new("hide_icon.png"):addTo(btn):align(display.CENTER, 56/2, TAB_HEIGHT/2)


    local icon_map = {
        { "technology", "tech_42x38.png" },
        { "material", "material_42x36.png" },
        { "soldier", "soldier_42x36.png" },
        { "build", "build_42x36.png" },
    }
    local tab_map = {}
    origin_x = origin_x - 4
    for i, v in ipairs(icon_map) do
        local tab_type = v[1]
        local tab_png = v[2]
        tab_map[tab_type] = WidgetTab.new({
            on = "tab_button_down_142x42.png",
            off = "tab_button_up_142x42.png",
            progress = true,
            tab_png = tab_png,
        }, 142, TAB_HEIGHT)
            :addTo(node):align(display.LEFT_BOTTOM,origin_x + (i - 5) * (142 + 1), 3)
            :OnTabPress(handler(self, self.OnTabClicked))
            :EnableTag(true):SetActiveNumber(0, 0)
    end
    return node, tab_map
end
function WidgetEventTabButtons:CreateBackGround()
    local back = cc.ui.UIImage.new("tab_background_640x106.png", {scale9 = true,
        capInsets = cc.rect(2, 2, WIDGET_WIDTH - 4, 106 - 4)
    }):align(display.LEFT_BOTTOM):setLayoutSize(WIDGET_WIDTH, ITEM_HEIGHT + 2)
    return back
end
function WidgetEventTabButtons:CreateItem()
    return self:CreateProgressItem():align(display.LEFT_CENTER)
end
function WidgetEventTabButtons:CreateBottom()
    return self:CreateOpenItem():align(display.LEFT_CENTER)
end
function WidgetEventTabButtons:CreateMilitaryItem(building)
    return self:CreateOpenMilitaryTechItem(building):align(display.LEFT_CENTER)
end
function WidgetEventTabButtons:CreateProgressItem()
    local node = display.newSprite("tab_event_bar.png")
    local half_height = node:getContentSize().height / 2
    node.progress = display.newProgressTimer("tab_progress_bar.png",
        display.PROGRESS_TIMER_BAR):addTo(node)
        :align(display.LEFT_CENTER, 4, half_height)
    node.progress:setBarChangeRate(cc.p(1,0))
    node.progress:setMidpoint(cc.p(0,0))
    node.desc = UIKit:ttfLabel({
        text = "Building",
        size = 18,
        color = 0xd1ca95,
        shadow = true,
    }):addTo(node):align(display.LEFT_CENTER, 10, half_height)

    node.time = UIKit:ttfLabel({
        text = "Time",
        size = 18,
        color = 0xd1ca95,
        shadow = true,
    }):addTo(node):align(display.RIGHT_CENTER, 470, half_height)

    node.speed_btn = WidgetPushButton.new({normal = "green_btn_up_154x39.png",
        pressed = "green_btn_down_154x39.png",
    }
    ,{}
    ,{
        disabled = { name = "GRAY", params = {0.2, 0.3, 0.5, 0.1} }
    }):addTo(node):align(display.RIGHT_CENTER, WIDGET_WIDTH - 6, half_height)
        :setButtonLabel(UIKit:ttfLabel({
            text = _("加速"),
            size = 18,
            color = 0xfff3c7,
            shadow = true}))
    function node:SetProgressInfo(str, percent, time)
        self.desc:setString(str)
        self.time:setString(time or "")
        self.progress:setPercentage(percent)
        return self
    end
    function node:OnClicked(func)
        self.speed_btn:onButtonClicked(func)
        return self
    end
    function node:SetEvent(event)
        self.event = event
        return self
    end
    function node:SetButtonImages(images)
        self.speed_btn:setButtonImage(cc.ui.UIPushButton.NORMAL, images["normal"], true)
        self.speed_btn:setButtonImage(cc.ui.UIPushButton.PRESSED, images["pressed"], true)
        self.speed_btn:setButtonImage(cc.ui.UIPushButton.DISABLED, images["disabled"], true)
        return self
    end
    function node:SetButtonLabel(str)
        self.speed_btn:setButtonLabel(UIKit:ttfLabel({
            text = str,
            size = 18,
            color = 0xfff3c7,
            shadow = true}))
        return self
    end
    function node:GetSpeedUpButton()
        return self.speed_btn
    end
    return node
end
function WidgetEventTabButtons:CreateOpenItem()
    local node = display.newSprite("tab_event_bar.png")
    local half_height = node:getContentSize().height / 2

    node.label = UIKit:ttfLabel({
        text = "Building",
        size = 18,
        font = UIKit:getFontFilePath(),
        color = 0xd1ca95,
        shadow = true,
    }):addTo(node):align(display.LEFT_CENTER, 10, half_height)

    node.button = WidgetPushButton.new({
        normal = "blue_btn_up_154x39.png",
        pressed = "blue_btn_down_154x39.png",
    }
    ,{}
    ,{
        disabled = { name = "GRAY", params = {0.2, 0.3, 0.5, 0.1} }
    }):addTo(node):align(display.RIGHT_CENTER, WIDGET_WIDTH - 6, half_height)
        :setButtonLabel(UIKit:ttfLabel({
            text = _("打开"),
            size = 18,
            color = 0xfff3c7,
            shadow = true
        }))
    function node:SetLabel(str)
        self.label:setString(str)
        return self
    end
    function node:OnOpenClicked(func)
        self.button:onButtonClicked(func)
        return self
    end
    return node
end
function WidgetEventTabButtons:CreateOpenMilitaryTechItem(building)
    return self:CreateOpenItem():OnOpenClicked(function()
        UIKit:newGameUI('GameUIMilitaryTechBuilding', City, building):AddToCurrentScene(true)
    end)
end
function WidgetEventTabButtons:IsTabEnable(tab)
    local User = self.city:GetUser()
    if tab == "build" or tab == nil then
        return true
    elseif tab == "soldier" and User:IsBuildingUnlockedBy("barracks") then
        return true
    elseif tab == "material"
        and (User:IsBuildingUnlockedBy("toolShop")
        or User:IsBuildingUnlockedBy("blackSmith")) then
        return true
    elseif tab == "technology" then
        local city = self.city
        local total_num = 0
        local buildings = {
            "academy",
            "trainingGround",
            "hunterHall",
            "stable",
            "workshop",
        }
        for _,v in ipairs(buildings) do
            if city:GetFirstBuildingByType(v):IsUnlocked() then
                total_num = total_num + 1
            end
        end
        return total_num > 0
    end
    return false
end
-- 操作
function WidgetEventTabButtons:IteratorAllItem(func)
    for i, v in pairs(self.item_array) do
        if func(i, v) then
            return
        end
    end
end
function WidgetEventTabButtons:InsertItem(item, pos)
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
function WidgetEventTabButtons:InsertItem_(item, pos)
    item:addTo(self.back_ground, 2)
    if pos then
        table.insert(self.item_array, pos, item)
    else
        table.insert(self.item_array, item)
    end
end

-- 玩家操作动画
function WidgetEventTabButtons:PromiseOfShowTab(tab)
    self:HighLightTab(tab)
    return self:PromiseOfForceShow()
end
function WidgetEventTabButtons:HighLightTab(tab)
    self:ResetOtherTabByCurrentTab(tab)
    self.tab_map[tab]:Enable(true):Active(true)
end
function WidgetEventTabButtons:OnTabClicked(widget, is_pressed)
    local tab
    for k, v in pairs(self.tab_map) do
        if v == widget then
            tab = k
        end
    end
    self:ResetOtherTabByCurrentTab(tab)
    self.tab_map[tab]:SetSelect(true)
    if self:IsShow() then
        if is_pressed then
            self:PromiseOfSwitch()
        else
            self:PromiseOfHide()
        end
    else
        self:PromiseOfForceShow()
    end
end
function WidgetEventTabButtons:ResetOtherTabByCurrentTab(tab)
    for k, v in pairs(self.tab_map) do
        if k ~= tab then
            v:Enable(self:IsTabEnable(k)):Active(false)
        end
    end
end
function WidgetEventTabButtons:PromiseOfForceShow()
    if self:IsShow() then
        return self:PromiseOfSwitch()
    else
        return self:PromiseOfShow()
    end
end
function WidgetEventTabButtons:Lock(lock)
    self.locked = lock
end
function WidgetEventTabButtons:IsShow()
    return not self.arrow:isFlippedY()
end
function WidgetEventTabButtons:IsShowing()
    return self.node:getNumberOfRunningActions() > 0
end
function WidgetEventTabButtons:ResizeBelowHorizon(new_height)
    local height = new_height < ITEM_HEIGHT and ITEM_HEIGHT or new_height
    local size = self.back_ground:getContentSize()
    self.back_ground:setContentSize(cc.size(size.width, height))
    self.node:setPositionY(- height)
    self.tab_buttons:setPositionY(height)
end
function WidgetEventTabButtons:Length(array_len)
    return array_len * ITEM_HEIGHT + 2
end
function WidgetEventTabButtons:PromiseOfSwitch()
    return self:PromiseOfHide():next(function()
        return self:PromiseOfShow()
    end)
end
function WidgetEventTabButtons:PromiseOfHide()
    self.node:stopAllActions()
    self:Lock(true)
    local hide_height = - self.back_ground:getContentSize().height
    return cocos_promise.promiseOfMoveTo(self.node, 0, hide_height, 0.15, "sineIn"):next(function()
        self:Reset()
    end)
end
function WidgetEventTabButtons:PromiseOfShow()
    if self:IsTabEnable(self:GetCurrentTab()) then
        self:Reload()
        return cocos_promise.promiseOfMoveTo(self.node, 0, 0, 0.15, "sineIn"):next(function()
            self:RefreshAllEvents()
            self.arrow:flipY(false)
            if self.pop_callbacks and #self.pop_callbacks > 0 then
                table.remove(self.pop_callbacks, 1)()
                self.pop_callbacks = {}
            end
        end)
    end
    return cocos_promise.defer()
end
function WidgetEventTabButtons:GetTabByKey(key)
    return self.tab_map[key]
end
function WidgetEventTabButtons:GetCurrentTab()
    for k, v in pairs(self.tab_map) do
        if v:IsSelected() then
            return k, v
        end
    end
end
function WidgetEventTabButtons:Reload()
    self:Reset()
    self:Load()
end
function WidgetEventTabButtons:Reset()
    for k, v in pairs(self.tab_map) do
        v:Enable(self:IsTabEnable(k)):SetHighLight(false)
    end
    self.back_ground:removeAllChildren()
    self.item_array = {}
    self.node:stopAllActions()
    self:ResizeBelowHorizon(0)
    self.arrow:flipY(true)
    self:Lock(false)
end
function WidgetEventTabButtons:Load()
    if not self:GetCurrentTab() then
        self.tab_map["build"]:SetSelect(true)
    end
    for k, v in pairs(self.tab_map) do
        if v:IsSelected() then
            self:HighLightTab(k)
            if k == "build" then
                self:LoadBuildingEvents()
            elseif k == "soldier" then
                self:LoadSoldierEvents()
            elseif k == "technology" then
                self:LoadTechnologyEvents()
            elseif k == "material" then
                self:LoadMaterialEvents()
            end
            self:ResizeBelowHorizon(self:Length(#self.item_array))
            return
        end
    end
end


--------------
function WidgetEventTabButtons:IsAbleToFreeSpeedup(event)
    local time = UtilsForEvent:GetEventInfo(event)
    return DataUtils:getFreeSpeedUpLimitTime() > time
end
function WidgetEventTabButtons:UpgradeBuildingHelpOrSpeedup(event)
    local User = self.city:GetUser()
    local eventType = event.location and "buildingEvents" or "houseEvents"
    if self:IsAbleToFreeSpeedup(event) then
        local time = UtilsForEvent:GetEventInfo(event)
        if time > 2 then
            NetManager:getFreeSpeedUpPromise(eventType, event.id)
        end
    else
        if not Alliance_Manager:GetMyAlliance():IsDefault() then
            -- 是否已经申请过联盟加速
            if not User:IsRequestHelped(event.id) then
                NetManager:getRequestAllianceToSpeedUpPromise(eventType, event.id)
                return
            end
        end
        -- 没加入联盟或者已加入联盟并且申请过帮助时执行使用道具加速
        UIKit:newGameUI("GameUIBuildingSpeedUp", event):AddToCurrentScene(true)
    end
end
function WidgetEventTabButtons:MiliTaryTechUpgradeOrSpeedup(event)
    local User = self.city:GetUser()
    local time, percent = UtilsForEvent:GetEventInfo(event)

    if DataUtils:getFreeSpeedUpLimitTime() > time and time > 2 then
        NetManager:getFreeSpeedUpPromise(User:EventType(event), event.id)
    else
        if not Alliance_Manager:GetMyAlliance():IsDefault() then
            if not User:IsRequestHelped(event.id) then
                NetManager:getRequestAllianceToSpeedUpPromise(User:EventType(event),event.id)
                return
            end
        end
        -- 没加入联盟或者已加入联盟并且申请过帮助时执行使用道具加速
        UIKit:newGameUI("GameUIMilitaryTechSpeedUp", event):AddToCurrentScene(true)
    end
end
function WidgetEventTabButtons:SoldierRecruitUpgradeOrSpeedup()
    UIKit:newGameUI("GameUIBarracksSpeedUp"):AddToCurrentScene(true)
end
function WidgetEventTabButtons:MaterialEventUpgradeOrSpeedup()
    UIKit:newGameUI("GameUIToolShopSpeedUp", self.city:GetFirstBuildingByType("toolShop")):AddToCurrentScene(true)
end
function WidgetEventTabButtons:DragonEquipmentEventsUpgradeOrSpeedup()
    UIKit:newGameUI("GameUIBlackSmithSpeedUp", self.city:GetFirstBuildingByType("blackSmith")):AddToCurrentScene(true)
end
function WidgetEventTabButtons:SetProgressItemBtnLabel(canFreeSpeedUp, event_item)
    if event_item.event.finishTime/1000 < timer:GetServerTime() then return end
    local User = self.city:GetUser()
    local old_status = event_item.status
    local btn_label
    local btn_images
    if canFreeSpeedUp then
        btn_label = _("免费加速")
        btn_images = {normal = "purple_btn_up_154x39.png",
            pressed = "purple_btn_down_154x39.png",
        }
        event_item.status = "freeSpeedup"
    else
        -- 未加入联盟或者已经申请过联盟加速
        if Alliance_Manager:GetMyAlliance():IsDefault()
            or User:IsRequestHelped(event_item.event.id) then
            btn_label = _("加速")
            btn_images = {normal = "green_btn_up_154x39.png",
                pressed = "green_btn_down_154x39.png",
            }
            event_item.status = "speedup"
        else
            btn_label = _("帮助")
            btn_images = {normal = "yellow_btn_up_154x39.png",
                pressed = "yellow_btn_down_154x39.png",
            }
            event_item.status = "help"
        end
    end
    if old_status~= event_item.status then
        event_item:SetButtonLabel(btn_label)
        event_item:SetButtonImages(btn_images)
    end
end
function WidgetEventTabButtons:LoadBuildingEvents()
    self:InsertItem(self:CreateBottom():OnOpenClicked(function(event)
        UIKit:newGameUI('GameUIHasBeenBuild', self.city):AddToCurrentScene(true)
    end):SetLabel(_("查看已拥有的建筑")))
    local events = UtilsForBuilding:GetBuildingEventsBySeq(self.city:GetUser())
    local items = {}
    for _,v in ipairs(events) do
        local event_item = self:CreateItem()
            :SetProgressInfo(self:BuildingDescribe(v))
            :SetEvent(v)
            :OnClicked(function(event)
                if event.name == "CLICKED_EVENT" then
                    self:UpgradeBuildingHelpOrSpeedup(v)
                end
            end)
        self:SetProgressItemBtnLabel(self:IsAbleToFreeSpeedup(v), event_item)
        table.insert(items, event_item)
    end
    self:InsertItem(items)
end
function WidgetEventTabButtons:LoadSoldierEvents()
    self:InsertItem(self:CreateBottom():OnOpenClicked(function(event)
        UIKit:newGameUI('GameUIBarracks', self.city, self.city:GetFirstBuildingByType("barracks"), "recruit"):AddToCurrentScene(true)
    end):SetLabel(_("查看现有的士兵")))
    local User = self.city:GetUser()
    for i,event in ipairs(User:GetSoldierEventsBySeq()) do
        local item = self:CreateItem()
            :SetProgressInfo(self:SoldierDescribe(event))
            :SetEvent(event)
            :OnClicked(
                function(e)
                    if e.name == "CLICKED_EVENT" then
                        self:SoldierRecruitUpgradeOrSpeedup()
                    end
                end
            )
        self:InsertItem(item)
    end
end
local material_buildings = {
    "toolShop",
    "blackSmith",
}
function WidgetEventTabButtons:LoadMaterialEvents()
    local User = self.city:GetUser()
    self:InsertItem(self:CreateBottom():OnOpenClicked(function(event)
        UIKit:newGameUI('GameUIMaterials',
            self.city:GetFirstBuildingByType("toolShop"),
            self.city:GetFirstBuildingByType("blackSmith")
        ):AddToCurrentScene(true)
    end):SetLabel(_("查看材料")))

    local material_events = {}

    local event = User.dragonEquipmentEvents[1]
    if event then
        table.insert(material_events, {"blackSmith", event})
    end

    for _,event in ipairs(User.materialEvents) do
        if event.finishTime ~= 0 then
            table.insert(material_events, {"toolShop", event})
        end
    end

    table.sort(material_events, function(a, b)
        return a[2].finishTime > b[2].finishTime
    end)

    for _,v in ipairs(material_events) do
        local building_type,event = unpack(v)
        if building_type == "blackSmith" then
            local item = self:CreateItem()
                :SetProgressInfo(self:EquipmentDescribe(event))
                :SetEvent(event)
                :OnClicked(function(e) self:DragonEquipmentEventsUpgradeOrSpeedup() end)
            self:InsertItem(item)
        elseif building_type == "toolShop" then
            local item = self:CreateItem()
                :SetProgressInfo(self:MaterialDescribe(event))
                :SetEvent(event)
                :OnClicked(function(e) self:MaterialEventUpgradeOrSpeedup() end)
            self:InsertItem(item)
        end
    end
end
local military_techs = {
    trainingGround = 5,
    hunterHall = 4,
    stable = 3,
    workshop = 2,
    academy = 1,
}
local military_techs_desc = {
    trainingGround = _("训练营地空闲"),
    hunterHall = _("猎手大厅空闲"),
    stable = _("马厩空闲"),
    workshop = _("车间空闲"),
    academy = _("查看学院科技"),
}
function WidgetEventTabButtons:LoadTechnologyEvents()
    local city = self.city
    local User = self.city:GetUser()
    local technology_buildings = {}
    local technology_events = {}
    for _,building_type in ipairs({"trainingGround",
        "hunterHall",
        "stable",
        "workshop",
        "academy"}) do
        if building_type == "academy" then
            if User:HasProductionTechEvent() then
                for _,event in ipairs(User.productionTechEvents) do
                    table.insert(technology_events, {building_type, event})
                end
            else
                table.insert(technology_events, {building_type})
            end
        else
            local User = city:GetUser()
            technology_buildings[building_type] = city:GetFirstBuildingByType(building_type)
            if technology_buildings[building_type]:IsUnlocked() then
                if User:HasMilitaryTechEventBy(building_type) then
                    local event = User:GetShortMilitaryTechEventBy(building_type)
                    table.insert(technology_events, {building_type, event})
                else
                    table.insert(technology_events, {building_type})
                end
            end
        end
    end

    table.sort(technology_events, function(a, b)
        local type1, event1 = unpack(a)
        local type2, event2 = unpack(b)
        if event1 and event2 then
            return event1.finishTime > event2.finishTime
        elseif event1 and not event2 then
            return false
        elseif not event1 and event2 then
            return true
        end
        return military_techs[type1] < military_techs[type2]
    end)
    for i,v in ipairs(technology_events) do
        local building_type, event = unpack(v)
        local desc = military_techs_desc[building_type]
        local building = technology_buildings[building_type]
        if building_type == "academy" then
            if event then
                local item = self:CreateItem()
                    :SetProgressInfo(self:TechDescribe(event))
                    :SetEvent(event)
                    :OnClicked(function(e)
                        self:ProductionTechnologyEventUpgradeOrSpeedup(event)
                    end)
                self:SetProgressItemBtnLabel(DataUtils:getFreeSpeedUpLimitTime() > UtilsForEvent:GetEventInfo(event), item)
                self:InsertItem(item)
            else
                self:InsertItem(self:CreateBottom():OnOpenClicked(function(event)
                    UIKit:newGameUI('GameUIQuickTechnology', self.city):AddToCurrentScene(true)
                end):SetLabel(desc))
            end
        else
            if event then
                local item = self:CreateItem()
                    :SetProgressInfo(self:TechDescribe(event))
                    :SetEvent(event)
                    :OnClicked(function(e)
                        self:MiliTaryTechUpgradeOrSpeedup(event)
                    end)
                self:SetProgressItemBtnLabel(DataUtils:getFreeSpeedUpLimitTime() > UtilsForEvent:GetEventInfo(event), item)
                self:InsertItem(item)
            else
                self:InsertItem(self:CreateMilitaryItem(building):SetLabel(desc))
            end
        end
    end
end
function WidgetEventTabButtons:BuildingDescribe(event)
    local User = self.city:GetUser()
    local str
    if event.location then
        local building = UtilsForBuilding:GetBuildingByEvent(User, event)
        if building.level == 0 then
            str = string.format(_("%s (解锁)"), Localize.building_name[building.type])
        else
            str = string.format(_("%s (升级到 等级%d)"), Localize.building_name[building.type], building.level + 1)
        end
    else
        local house = UtilsForBuilding:GetBuildingByEvent(User, event)
        if house.level == 0 then
            str = string.format(_("%s (建造)"), Localize.building_name[house.type])
        else
            str = string.format(_("%s (升级到 等级%d)"), Localize.building_name[house.type], house.level + 1)
        end
    end
    local time, percent = UtilsForEvent:GetEventInfo(event)
    return str, percent , GameUtils:formatTimeStyle1(time)
end
function WidgetEventTabButtons:SoldierDescribe(event)
    local time, percent = UtilsForEvent:GetEventInfo(event)
    return string.format( _("招募%s x%d"),
        Localize.soldier_name[event.name], event.count),
    percent,
    GameUtils:formatTimeStyle1(time)
end
function WidgetEventTabButtons:EquipmentDescribe(event)
    local time, percent = UtilsForEvent:GetEventInfo(event)
    return string.format( _("正在制作 %s"), Localize.equip[event.name]), percent , GameUtils:formatTimeStyle1(time)
end
function WidgetEventTabButtons:MaterialDescribe(event)
    local time, percent = UtilsForEvent:GetEventInfo(event)
    local count = 0
    for _,v in pairs(event.materials) do
        count = count + v.count
    end
    return string.format( _("制造材料 x%d"), count), percent , GameUtils:formatTimeStyle1(time)
end
function WidgetEventTabButtons:TechDescribe(event)
    local User = self.city:GetUser()
    local str
    if User:IsProductionTechEvent(event) then
        local next_level = User.productionTechs[event.name].level + 1
        str = _("研发") .. string.format(" %s Lv %d", Localize.productiontechnology_name[event.name], next_level)
    elseif User:IsSoldierStarEvent(event) then
        str = UtilsForEvent:GetMilitaryTechEventLocalize(event.name, UtilsForSoldier:SoldierStarByName(User, event.name))
    elseif User:IsMilitaryTechEvent(event) then
        str = UtilsForEvent:GetMilitaryTechEventLocalize(event.name, User:GetMilitaryTechLevel(event.name))
    else
        return "", 0, "00:00:00"
    end
    local time, percent = UtilsForEvent:GetEventInfo(event)
    return str, percent , GameUtils:formatTimeStyle1(time)
end
function WidgetEventTabButtons:EventPercent(event)
    local time = timer:GetServerTime()
    return event:LeftTime(time), event:Percent(time)
end
function WidgetEventTabButtons:ProductionTechnologyEventUpgradeOrSpeedup(event)
    local time = UtilsForEvent:GetEventInfo(event)
    local User = self.city:GetUser()
    if DataUtils:getFreeSpeedUpLimitTime() > time and time > 2 then
        NetManager:getFreeSpeedUpPromise("productionTechEvents", event.id)
    else
        if not Alliance_Manager:GetMyAlliance():IsDefault() then
            if not User:IsRequestHelped(event.id) then
                NetManager:getRequestAllianceToSpeedUpPromise("productionTechEvents",event.id)
                return
            end
        end
        -- 没加入联盟或者已加入联盟并且申请过帮助时执行使用道具加速
        UIKit:newGameUI("GameUITechnologySpeedUp"):AddToCurrentScene(true)
    end
end
function WidgetEventTabButtons:PromiseOfPopUp()
    local p = promise.new()
    self.pop_callbacks = {}
    if not self:IsShow() or self:IsShowing() or #self.item_array == 1 then
        table.insert(self.pop_callbacks, function()
            p:resolve()
        end)
        return p
    end
    return cocos_promise.defer()
end




return WidgetEventTabButtons


