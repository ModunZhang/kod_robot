local promise = import("..utils.promise")
local cocos_promise = import("..utils.cocos_promise")
local Localize = import("..utils.Localize")
local SoldierManager = import("..entity.SoldierManager")
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
-- 建筑事件
function WidgetEventTabButtons:OnSpeedUpBuilding()
    self:EventChangeOn("build")
end
function WidgetEventTabButtons:OnDestoryDecorator()
    self:EventChangeOn("build")
end
function WidgetEventTabButtons:OnUpgradingBegin(building, current_time, city)
    self:GetTabByKey("build"):SetOrResetProgress(self:BuildingPercent(building))
    self:EventChangeOn("build", true)
    self:RefreshBuildQueueByType("build")
end
function WidgetEventTabButtons:OnUpgrading(building, current_time, city)
    self:GetTabByKey("build"):SetOrResetProgress(self:BuildingPercent(building))
    if self:IsShow() and self:GetCurrentTab() == "build" then
        self:IteratorAllItem(function(i, v)
            if i ~= 1 and v:GetEventKey() == building:UniqueKey() then
                v:SetProgressInfo(self:BuildingDescribe(building))
                self:SetProgressItemBtnLabel(self:IsAbleToFreeSpeedup(building),building:UniqueUpgradingKey(),v)
            end
        end)
    end
end
function WidgetEventTabButtons:OnUpgradingFinished(building, city)
    self:EventChangeOn("build")
    self:RefreshBuildQueueByType("build", "soldier", "material", "technology")
end
-- 兵营事件
function WidgetEventTabButtons:OnBeginRecruit(barracks, event)
    self:GetTabByKey("soldier"):SetOrResetProgress(self:EventPercent(event))
    self:EventChangeOn("soldier", true)
end
function WidgetEventTabButtons:OnRecruiting(barracks, event, current_time)
    self:GetTabByKey("soldier"):SetOrResetProgress(self:EventPercent(event))
    if self:IsShow() and self:GetCurrentTab() == "soldier" then
        self:IteratorAllItem(function(i, v)
            if i ~= 1 then
                v:SetProgressInfo(self:SoldierDescribe(event))
            end
        end)
    end
end
function WidgetEventTabButtons:OnEndRecruit(barracks)
    self:EventChangeOn("soldier")
end
-- 装备事件
function WidgetEventTabButtons:OnSpeedUpMakingEquipment()
    self:EventChangeOn("material")
end
function WidgetEventTabButtons:OnBeginMakeEquipmentWithEvent(black_smith, event)
    self:GetTabByKey("material"):SetOrResetProgress(self:EventPercent(event))
    self:EventChangeOn("material", true)
end
function WidgetEventTabButtons:OnMakingEquipmentWithEvent(black_smith, event, current_time)
    self:GetTabByKey("material"):SetOrResetProgress(self:EventPercent(event))
    if self:IsShow() and self:GetCurrentTab() == "material" then
        self:IteratorAllItem(function(i, v)
            if i ~= 1 and v:GetEventKey() == event:UniqueKey() then
                v:SetProgressInfo(self:EquipmentDescribe(event))
            end
        end)
    end
end
function WidgetEventTabButtons:OnEndMakeEquipmentWithEvent(black_smith, event, equipment)
    self:EventChangeOn("material")
end
-- 材料事件
function WidgetEventTabButtons:OnSpeedUpMakingMaterial()
    self:EventChangeOn("material")
end
function WidgetEventTabButtons:OnBeginMakeMaterialsWithEvent(tool_shop, event)
    self:GetTabByKey("material"):SetOrResetProgress(self:EventPercent(event))
    self:EventChangeOn("material", true)
end
function WidgetEventTabButtons:OnMakingMaterialsWithEvent(tool_shop, event, current_time)
    self:GetTabByKey("material"):SetOrResetProgress(self:EventPercent(event))
    if self:IsShow() and self:GetCurrentTab() == "material" then
        self:IteratorAllItem(function(i, v)
            if i ~= 1 and v:GetEventKey() == event:UniqueKey() then
                v:SetProgressInfo(self:MaterialDescribe(event))
            end
        end)
    end
end
function WidgetEventTabButtons:OnEndMakeMaterialsWithEvent(tool_shop, event, current_time)
    self:EventChangeOn("material")
end
function WidgetEventTabButtons:OnGetMaterialsWithEvent(tool_shop, event)
    self:EventChangeOn("material")
end

-- 军事科技
function WidgetEventTabButtons:OnSoldierStarEventsTimer(star_event)
    self:GetTabByKey("technology"):SetOrResetProgress(self:EventPercent(star_event))
    if self:IsShow() and self:GetCurrentTab() == "technology" then
        self:IteratorAllItem(function(i, v)
            if v.GetEventKey and v:GetEventKey() == star_event:Id() then
                v:SetProgressInfo(self:MilitaryTechDescribe(star_event))
                self:SetProgressItemBtnLabel(DataUtils:getFreeSpeedUpLimitTime()>star_event:GetTime(),star_event:Id(),v)
            end
        end)
    end
end
function WidgetEventTabButtons:OnMilitaryTechEventsTimer(tech_event)
    self:GetTabByKey("technology"):SetOrResetProgress(self:EventPercent(tech_event))
    if self:IsShow() and self:GetCurrentTab() == "technology" then
        self:IteratorAllItem(function(i, v)
            if v.GetEventKey and v:GetEventKey() == tech_event:Id() then
                v:SetProgressInfo(self:MilitaryTechDescribe(tech_event))
                self:SetProgressItemBtnLabel(DataUtils:getFreeSpeedUpLimitTime()>tech_event:GetTime(),tech_event:Id(),v)
            end
        end)
    end
end
function WidgetEventTabButtons:OnMilitaryTechEventsChanged(soldier_manager,changed_map)
    if #changed_map[1]~=0 then
        self:EventChangeOn("technology", #changed_map[1]>0)
    end
    if #changed_map[3]>0 then
        app:GetAudioManager():PlayeEffectSoundWithKey("COMPLETE")
        self:EventChangeOn("technology")
    end
    self:RefreshBuildQueueByType("technology")
end
function WidgetEventTabButtons:OnMilitaryTechEventsAllChanged()
    self:RefreshBuildQueueByType("technology")
end
function WidgetEventTabButtons:OnSoldierStarEventsChanged(soldier_manager, changed)
    if #changed[1]~=0 then
        self:EventChangeOn("technology", #changed[1]>0)
    end
    if #changed[3]>0 then
        app:GetAudioManager():PlayeEffectSoundWithKey("COMPLETE")
        self:EventChangeOn("technology")
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
    local node = display.newNode():addTo(self)
    node:scale(ratio)
    cc.Layer:create():addTo(node):pos(0, -WIDGET_HEIGHT + TAB_HEIGHT):setContentSize(cc.size(WIDGET_WIDTH, WIDGET_HEIGHT + TAB_HEIGHT)):setCascadeOpacityEnabled(true)
    self.node = node
    self.tab_buttons, self.tab_map = self:CreateTabButtons()
    self.tab_buttons:addTo(node, 2):pos(0, 0)
    self.back_ground = self:CreateBackGround():addTo(node)

    self.city = city
    self.barracks = city:GetFirstBuildingByType("barracks")
    self.toolShop = city:GetFirstBuildingByType("toolShop")
    self.blackSmith = city:GetFirstBuildingByType("blackSmith")

    self.toolShop:AddToolShopListener(self)
    self.barracks:AddBarracksListener(self)
    self.blackSmith:AddBlackSmithListener(self)
    city:GetSoldierManager():AddListenOnType(self,SoldierManager.LISTEN_TYPE.OnSoldierStarEventsTimer)
    city:GetSoldierManager():AddListenOnType(self,SoldierManager.LISTEN_TYPE.OnMilitaryTechEventsTimer)
    city:GetSoldierManager():AddListenOnType(self,SoldierManager.LISTEN_TYPE.MILITARY_TECHS_EVENTS_CHANGED)
    city:GetSoldierManager():AddListenOnType(self,SoldierManager.LISTEN_TYPE.MILITARY_TECHS_EVENTS_ALL_CHANGED)
    city:GetSoldierManager():AddListenOnType(self,SoldierManager.LISTEN_TYPE.SOLDIER_STAR_EVENTS_CHANGED)
    city:AddListenOnType(self, City.LISTEN_TYPE.UPGRADE_BUILDING)
    city:AddListenOnType(self, City.LISTEN_TYPE.DESTROY_DECORATOR)
    city:AddListenOnType(self,city.LISTEN_TYPE.PRODUCTION_EVENT_TIMER)
    city:AddListenOnType(self,city.LISTEN_TYPE.PRODUCTION_EVENT_CHANGED)
    city:AddListenOnType(self,city.LISTEN_TYPE.PRODUCTION_EVENT_REFRESH)

    self:Reset()
    self:ShowStartEvent()
    self:RefreshBuildQueueByType("build", "soldier", "material", "technology")
end
function WidgetEventTabButtons:onExit()
    self.toolShop:RemoveToolShopListener(self)
    self.barracks:RemoveBarracksListener(self)
    self.blackSmith:RemoveBlackSmithListener(self)
    self.city:RemoveListenerOnType(self, City.LISTEN_TYPE.UPGRADE_BUILDING)
    self.city:RemoveListenerOnType(self, City.LISTEN_TYPE.DESTROY_DECORATOR)
    self.city:GetSoldierManager():RemoveListenerOnType(self,SoldierManager.LISTEN_TYPE.OnSoldierStarEventsTimer)
    self.city:GetSoldierManager():RemoveListenerOnType(self,SoldierManager.LISTEN_TYPE.OnMilitaryTechEventsTimer)
    self.city:GetSoldierManager():RemoveListenerOnType(self,SoldierManager.LISTEN_TYPE.MILITARY_TECHS_EVENTS_CHANGED)
    self.city:GetSoldierManager():RemoveListenerOnType(self,SoldierManager.LISTEN_TYPE.MILITARY_TECHS_EVENTS_ALL_CHANGED)
    self.city:GetSoldierManager():RemoveListenerOnType(self,SoldierManager.LISTEN_TYPE.SOLDIER_STAR_EVENTS_CHANGED)
    self.city:RemoveListenerOnType(self,self.city.LISTEN_TYPE.PRODUCTION_EVENT_REFRESH)
    self.city:RemoveListenerOnType(self,self.city.LISTEN_TYPE.PRODUCTION_EVENT_CHANGED)
    self.city:RemoveListenerOnType(self,self.city.LISTEN_TYPE.PRODUCTION_EVENT_REFRESH)
end
function WidgetEventTabButtons:RefreshBuildQueueByType(...)
    local cur_tab = self:GetCurrentTab()
    local city = self.city
    for _,key in ipairs{...} do
        local item = self.tab_map[key]
        local able = cur_tab ~= key and self:IsTabEnable(key)
        if key == "build" then
            local count = #city:GetUpgradingBuildings()
            local total = city:BuildQueueCounts()
            if item:IsChanged(count, total) then item:SetOrResetProgress() end
            item:SetActiveNumber(count, total):Enable(able):SetOrResetProgress()
        elseif key == "soldier" then
            local count = self.barracks:IsRecruting() and 1 or 0
            local total = self.barracks:IsUnlocked() and 1 or 0
            if item:IsChanged(count, total) then item:SetOrResetProgress() end
            item:SetActiveNumber(count, total):Enable(able)
        elseif key == "material" then
            local count = 0
            count = count + (self.blackSmith:IsMakingEquipment() and 1 or 0)
            count = count + (self.toolShop:IsMakingAny(timer:GetServerTime()) and 1 or 0)
            local total = 0
            total = total + (self.toolShop:IsUnlocked() and 1 or 0)
            total = total + (self.blackSmith:IsUnlocked() and 1 or 0)
            if item:IsChanged(count, total) then item:SetOrResetProgress() end
            item:SetActiveNumber(count, total):Enable(able)
        elseif key == "technology" then
            local total = 0
            local buildings = {
                "academy",
                "trainingGround",
                "hunterHall",
                "stable",
                "workshop",
            }
            for i,v in ipairs(buildings) do
                if city:GetFirstBuildingByType(v):IsUnlocked() then
                    total = total + 1
                end
            end
            local count = city:GetSoldierManager():GetTotalUpgradingMilitaryTechNum() + city:GetProductionTechEventCount()
            if item:IsChanged(count, total) then item:SetOrResetProgress() end
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
    return #self.city:GetUpgradingBuildings() > 0
end
function WidgetEventTabButtons:HasAnySoldierEvent()
    return self.barracks:IsRecruting()
end
function WidgetEventTabButtons:HasAnyMaterialEvent()
    return self.blackSmith:IsMakingEquipment() or self.toolShop:IsMakingAny(timer:GetServerTime())
end
function WidgetEventTabButtons:HasAnyTechnologyEvent()
    return self.city:GetSoldierManager():IsUpgradingAnyMilitaryTech() or self.city:HaveProductionTechEvent()
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
        { "technology", "tech_39x38.png" },
        { "material", "build_39x38.png" },
        { "soldier", "soldier_44x34.png" },
        { "build", "build_44x34.png" },
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
        size = 16,
        color = 0xd1ca95,
    }):addTo(node):align(display.LEFT_CENTER, 10, half_height)

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
    function node:SetProgressInfo(str, percent)
        self.desc:setString(str)
        self.progress:setPercentage(percent)
        return self
    end
    function node:OnClicked(func)
        self.speed_btn:onButtonClicked(func)
        return self
    end
    function node:GetEventKey()
        return self.key
    end
    function node:SetEventKey(key)
        self.key = key
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
    if tab == "build" or tab == nil then
        return true
    elseif tab == "soldier" and self.barracks:IsUnlocked() then
        return true
    elseif tab == "material" and (self.toolShop:IsUnlocked() or self.blackSmith:IsUnlocked()) then
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
            self.arrow:flipY(false)
            if self.pop_callbacks and #self.pop_callbacks > 0 then
                table.remove(self.pop_callbacks, 1)()
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
function WidgetEventTabButtons:IsAbleToFreeSpeedup(building)
    return building:IsAbleToFreeSpeedUpByTime(app.timer:GetServerTime())
end
function WidgetEventTabButtons:UpgradeBuildingHelpOrSpeedup(building)
    local eventType = building:EventType()
    if self:IsAbleToFreeSpeedup(building) then
        NetManager:getFreeSpeedUpPromise(eventType,building:UniqueUpgradingKey())
    else
        if not Alliance_Manager:GetMyAlliance():IsDefault() then
            -- 是否已经申请过联盟加速
            local isRequested = Alliance_Manager:GetMyAlliance()
                :HasBeenRequestedToHelpSpeedup(building:UniqueUpgradingKey())
            if not isRequested then
                NetManager:getRequestAllianceToSpeedUpPromise(eventType,building:UniqueUpgradingKey())
                return
            end
        end
        -- 没加入联盟或者已加入联盟并且申请过帮助时执行使用道具加速
        UIKit:newGameUI("GameUIBuildingSpeedUp", building):AddToCurrentScene(true)
    end
end
function WidgetEventTabButtons:MiliTaryTechUpgradeOrSpeedup(event)
    if DataUtils:getFreeSpeedUpLimitTime()>event:GetTime() then
        NetManager:getFreeSpeedUpPromise(event:GetEventType(),event:Id())
    else
        if not Alliance_Manager:GetMyAlliance():IsDefault() then
            -- 是否已经申请过联盟加速
            local isRequested = Alliance_Manager:GetMyAlliance()
                :HasBeenRequestedToHelpSpeedup(event:Id())
            if not isRequested then
                NetManager:getRequestAllianceToSpeedUpPromise(event:GetEventType(),event:Id())
                return
            end
        end
        -- 没加入联盟或者已加入联盟并且申请过帮助时执行使用道具加速
        UIKit:newGameUI("GameUIMilitaryTechSpeedUp", event):AddToCurrentScene(true)
    end
end
function WidgetEventTabButtons:SoldierRecruitUpgradeOrSpeedup()
    UIKit:newGameUI("GameUIBarracksSpeedUp", self.city:GetFirstBuildingByType("barracks")):AddToCurrentScene(true)
end
function WidgetEventTabButtons:MaterialEventUpgradeOrSpeedup()
    UIKit:newGameUI("GameUIToolShopSpeedUp", self.city:GetFirstBuildingByType("toolShop")):AddToCurrentScene(true)
end
function WidgetEventTabButtons:DragonEquipmentEventsUpgradeOrSpeedup()
    UIKit:newGameUI("GameUIBlackSmithSpeedUp", self.city:GetFirstBuildingByType("blackSmith")):AddToCurrentScene(true)
end
function WidgetEventTabButtons:SetProgressItemBtnLabel(canFreeSpeedUp,event_key,event_item)
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
        if Alliance_Manager:GetMyAlliance():IsDefault() or
            Alliance_Manager:GetMyAlliance()
                :HasBeenRequestedToHelpSpeedup(event_key) then
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

    local buildings = self.city:GetUpgradingBuildings(true)
    local items = {}
    for i, v in ipairs(buildings) do
        local event_item = self:CreateItem()
            :SetProgressInfo(self:BuildingDescribe(v))
            :SetEventKey(v:UniqueKey()):OnClicked(
            function(event)
                if event.name == "CLICKED_EVENT" then
                    self:UpgradeBuildingHelpOrSpeedup(v)
                end
            end)
        self:SetProgressItemBtnLabel(self:IsAbleToFreeSpeedup(v),v:UniqueUpgradingKey(),event_item)
        table.insert(items, event_item)
    end
    self:InsertItem(items)
end
function WidgetEventTabButtons:LoadSoldierEvents()
    self:InsertItem(self:CreateBottom():OnOpenClicked(function(event)
        UIKit:newGameUI('GameUIBarracks', self.city, self.barracks):AddToCurrentScene(true)
    end):SetLabel(_("查看现有的士兵")))
    local event = self.barracks:GetRecruitEvent()
    if event:IsRecruting() then
        local item = self:CreateItem()
            :SetProgressInfo(self:SoldierDescribe(event))
            :SetEventKey(event:Id())
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
    self:InsertItem(self:CreateBottom():OnOpenClicked(function(event)
        UIKit:newGameUI('GameUIMaterials', self.toolShop, self.blackSmith):AddToCurrentScene(true)
    end):SetLabel(_("查看材料")))

    local material_events = {}

    local event = self.blackSmith:GetMakeEquipmentEvent()
    if event:IsMaking() then
        table.insert(material_events, {"blackSmith", event})
    end

    for _,event in pairs(self.toolShop:GetMakeMaterialsEvents()) do
        if event:IsMaking(timer:GetServerTime()) then
            table.insert(material_events, {"toolShop", event})
        end
    end

    table.sort(material_events, function(a, b)
        return a[2]:FinishTime() > b[2]:FinishTime()
    end)

    for _,v in ipairs(material_events) do
        local building_type,event = unpack(v)
        if building_type == "blackSmith" then
            local item = self:CreateItem()
                :SetProgressInfo(self:EquipmentDescribe(event))
                :SetEventKey(event:Id())
                :OnClicked(function(e) self:DragonEquipmentEventsUpgradeOrSpeedup() end)
            self:InsertItem(item)
        elseif building_type == "toolShop" then
            local item = self:CreateItem()
                :SetProgressInfo(self:MaterialDescribe(event))
                :SetEventKey(event:Id())
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
    local technology_buildings = {}
    local technology_events = {}
    local city = self.city
    local soldier_manager = city:GetSoldierManager()
    for _,building_type in ipairs({"trainingGround",
        "hunterHall",
        "stable",
        "workshop",
        "academy"}) do
        if building_type == "academy" then
            if city:HaveProductionTechEvent() then
                city:IteratorProductionTechEvents(function(event)
                    table.insert(technology_events, {building_type, event})
                end)
            else
                table.insert(technology_events, {building_type})
            end
        else
            technology_buildings[building_type] = city:GetFirstBuildingByType(building_type)
            if technology_buildings[building_type]:IsUnlocked() then
                if soldier_manager:IsUpgradingMilitaryTech(building_type) then
                    local event = soldier_manager:GetUpgradingMilitaryTech(building_type)
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
            return event1:FinishTime() > event2:FinishTime()
        elseif event1 and not event2 then
            return false
        elseif not event1 and event2 then
            return true
        end
        return military_techs[type1] < military_techs[type2]
    end)

    for i = #technology_events, 1, -1 do
        print(i, technology_events[i][1])
    end
    for i,v in ipairs(technology_events) do
        local building_type, event = unpack(v)
        local desc = military_techs_desc[building_type]
        local building = technology_buildings[building_type]
        if building_type == "academy" then
            if event then
                local item = self:CreateItem()
                    :SetProgressInfo(self:GetProductionTechnologyEventProgressInfo(event))
                    :SetEventKey(event:Id())
                    :OnClicked(function(e)
                        self:ProductionTechnologyEventUpgradeOrSpeedup(event)
                    end)
                self:SetProgressItemBtnLabel(DataUtils:getFreeSpeedUpLimitTime() > event:GetTime(),event:Id(),item)
                self:InsertItem(item)
            else
                self:InsertItem(self:CreateBottom():OnOpenClicked(function(event)
                    UIKit:newGameUI('GameUIQuickTechnology', self.city):AddToCurrentScene(true)
                end):SetLabel(desc))
            end
        else
            if event then
                local item = self:CreateItem()
                    :SetProgressInfo(self:MilitaryTechDescribe(event))
                    :SetEventKey(event:Id())
                    :OnClicked(function(e)
                        self:MiliTaryTechUpgradeOrSpeedup(event)
                    end)
                self:SetProgressItemBtnLabel(DataUtils:getFreeSpeedUpLimitTime() > event:GetTime(), event:Id(),item)
                self:InsertItem(item)
            else
                self:InsertItem(self:CreateMilitaryItem(building):SetLabel(desc))
            end
        end
    end
end
function WidgetEventTabButtons:BuildingDescribe(building)
    local upgrade_info
    if iskindof(building, "ResourceUpgradeBuilding") and building:IsBuilding() then
        upgrade_info = string.format("%s", _("建造"))
    elseif building:IsUnlocking() then
        upgrade_info = string.format("%s", _("解锁"))
    else
        upgrade_info = string.format("%s%d", _("升级到 等级"), building:GetNextLevel())
    end
    local time, percent = self:BuildingPercent(building)
    local str = string.format("%s (%s) %s",
        Localize.building_name[building:GetType()],
        upgrade_info,
        GameUtils:formatTimeStyle1(time))
    return str, percent
end
function WidgetEventTabButtons:BuildingPercent(building)
    local time = timer:GetServerTime()
    return building:GetUpgradingLeftTimeByCurrentTime(time), building:GetUpgradingPercentByCurrentTime(time)
end
function WidgetEventTabButtons:SoldierDescribe(event)
    local soldier_type, count = event:GetRecruitInfo()
    local soldier_name = Localize.soldier_name[soldier_type]
    local time, percent = self:EventPercent(event)
    return string.format("%s%s x%d %s", _("招募"), soldier_name, count, GameUtils:formatTimeStyle1(time)), percent
end
function WidgetEventTabButtons:EquipmentDescribe(event)
    local time, percent = self:EventPercent(event)
    return string.format("%s %s %s", _("正在制作"), Localize.equip[event:Content()], GameUtils:formatTimeStyle1(time)), percent
end
function WidgetEventTabButtons:MaterialDescribe(event)
    local time, percent = self:EventPercent(event)
    return string.format("%s x%d %s", _("制造材料"), event:TotalCount(), GameUtils:formatTimeStyle1(time)), percent
end
function WidgetEventTabButtons:MilitaryTechDescribe(event)
    local time, percent = self:EventPercent(event)
    return string.format("%s  %s", event:GetLocalizeDesc(), GameUtils:formatTimeStyle1(time)), percent
end
function WidgetEventTabButtons:EventPercent(event)
    local time = timer:GetServerTime()
    return event:LeftTime(time), event:Percent(time)
end
--学院科技
function WidgetEventTabButtons:OnProductionTechnologyEventTimer(event)
    self:GetTabByKey("technology"):SetOrResetProgress(self:EventPercent(event))
    if self:IsShow() and self:GetCurrentTab() == "technology" then
        self:IteratorAllItem(function(i, v)
            if v.GetEventKey and v:GetEventKey() == event:Id() then
                v:SetProgressInfo(self:GetProductionTechnologyEventProgressInfo(event))
                self:SetProgressItemBtnLabel(DataUtils:getFreeSpeedUpLimitTime()>event:GetTime(),event:Id(),v)
            end
        end)
    end
end
function WidgetEventTabButtons:OnProductionTechnologyEventDataChanged(changed_map)
    changed_map = changed_map or {}
    if changed_map.added and #changed_map.added > 0 then
        self:EventChangeOn("technology", true)
    end
    if changed_map.removed and #changed_map.removed > 0 then
        app:GetAudioManager():PlayeEffectSoundWithKey("COMPLETE")
        self:EventChangeOn("technology")
    end
end
function WidgetEventTabButtons:OnProductionTechnologyEventDataRefresh()
    self:EventChangeOn("technology")
end

function WidgetEventTabButtons:ProductionTechnologyEventUpgradeOrSpeedup(event)
    if DataUtils:getFreeSpeedUpLimitTime() > event:GetTime() then
        NetManager:getFreeSpeedUpPromise("productionTechEvents",event:Id())
    else
        if not Alliance_Manager:GetMyAlliance():IsDefault() then
            -- 是否已经申请过联盟加速
            local isRequested = Alliance_Manager:GetMyAlliance():HasBeenRequestedToHelpSpeedup(event:Id())
            if not isRequested then
                NetManager:getRequestAllianceToSpeedUpPromise("productionTechEvents",event:Id()):done(function()
                    self:OnProductionTechnologyEventDataRefresh()
                end)
                return
            end
        end
        -- 没加入联盟或者已加入联盟并且申请过帮助时执行使用道具加速
        UIKit:newGameUI("GameUITechnologySpeedUp"):AddToCurrentScene(true)
    end
end

function WidgetEventTabButtons:GetProductionTechnologyEventProgressInfo(event)
    return _("研发") .. event:Entity():GetLocalizedName() .. " " .. GameUtils:formatTimeStyle1(event:GetTime()),event:GetPercent()
end

function WidgetEventTabButtons:PromiseOfPopUp()
    local p = promise.new()
    self.pop_callbacks = {}
    if not self:IsShow() or self:IsShowing() then
        table.insert(self.pop_callbacks, function()
            p:resolve()
        end)
        return p
    end
    return cocos_promise.defer()
end




return WidgetEventTabButtons


















