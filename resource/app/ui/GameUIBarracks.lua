--
-- Author: gaozhou
-- Date: 2014-08-18 14:33:28
--
local window = import("..utils.window")
local Localize = import("..utils.Localize")
local WidgetTips = import("..widget.WidgetTips")
local WidgetSoldierBox = import("..widget.WidgetSoldierBox")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local WidgetTimerProgress = import("..widget.WidgetTimerProgress")
local WidgetRecruitSoldier = import("..widget.WidgetRecruitSoldier")
local SoldierManager = import("..entity.SoldierManager")
local GameUIBarracks = UIKit:createUIClass("GameUIBarracks", "GameUIUpgradeBuilding")
local WidgetRecruitSoldier_tag = 1
function GameUIBarracks:ctor(city, barracks,default_tab)
    GameUIBarracks.super.ctor(self, city, _("兵营"),barracks,default_tab)
    self.barracks_city = city
    self.barracks = barracks

    self.special_soldier_items={}
end
function GameUIBarracks:OnMoveInStage()
    self.soldier_map = {}
    self.timerAndTips = self:CreateTimerAndTips()
    self.recruit = self:CreateSoldierUI()
    self.specialRecruit = self:CreateSpecialSoldierUI()
    self:TabButtons()
    self.barracks:AddUpgradeListener(self)
    self.barracks:AddBarracksListener(self)
    self.barracks_city:GetSoldierManager():AddListenOnType(self,SoldierManager.LISTEN_TYPE.SOLDIER_CHANGED)
    self.barracks_city:GetSoldierManager():AddListenOnType(self,SoldierManager.LISTEN_TYPE.SOLDIER_STAR_CHANGED)
    app.timer:AddListener(self)
    GameUIBarracks.super.OnMoveInStage(self)
end
function GameUIBarracks:onExit()
    self.barracks:RemoveUpgradeListener(self)
    self.barracks:RemoveBarracksListener(self)
    self.barracks_city:GetSoldierManager():RemoveListenerOnType(self,SoldierManager.LISTEN_TYPE.SOLDIER_CHANGED)
    self.barracks_city:GetSoldierManager():RemoveListenerOnType(self,SoldierManager.LISTEN_TYPE.SOLDIER_STAR_CHANGED)
    app.timer:RemoveListener(self)
    GameUIBarracks.super.onExit(self)
end
function GameUIBarracks:RightButtonClicked()
    if self:GetView():getChildByTag(WidgetRecruitSoldier_tag) then
        self:GetView():getChildByTag(WidgetRecruitSoldier_tag):removeFromParent()
    end
    GameUIBarracks.super.RightButtonClicked(self)
end
function GameUIBarracks:OnBuildingUpgradingBegin()
end
function GameUIBarracks:OnBuildingUpgradeFinished()
    self:RefershUnlockInfo()
end
function GameUIBarracks:OnBuildingUpgrading()
end
function GameUIBarracks:OnBeginRecruit(barracks, event)
    self.tips:setVisible(false)
    self.timer:setVisible(true)
    self:OnRecruiting(barracks, event, app.timer:GetServerTime())
end
function GameUIBarracks:OnRecruiting(barracks, event, current_time)
    if self.timerAndTips:isVisible() then
        if not self.timer:isVisible() then
            self.timer:setVisible(true)
        end
        if self.tips:isVisible() then
            self.tips:setVisible(false)
        end
        local soldier_type, count = event:GetRecruitInfo()
        local soldier_name = Localize.soldier_name[soldier_type]
        self.timer:SetDescribe(string.format("%s%s x%d", _("招募"), soldier_name, count))
        self.timer:SetProgressInfo(GameUtils:formatTimeStyle1(event:LeftTime(current_time)), event:Percent(current_time))
    end
end
function GameUIBarracks:OnEndRecruit(barracks)
    self.tips:setVisible(true)
    self.timer:setVisible(false)
end
function GameUIBarracks:CreateTimerAndTips()
    local timerAndTips = display.newNode():addTo(self:GetView())
    self.tips = WidgetTips.new(_("招募队列空闲"), _("请选择一个兵种进行招募")):addTo(timerAndTips)
        :align(display.CENTER, window.cx, window.top - 160)
        :show()

    self.timer = WidgetTimerProgress.new(549, 108):addTo(timerAndTips)
        :align(display.CENTER, window.cx, window.top - 160)
        :hide()
        :OnButtonClicked(function(event)
            UIKit:newGameUI("GameUIBarracksSpeedUp",self.barracks):AddToCurrentScene(true)
        end)
    return timerAndTips
end

function GameUIBarracks:CreateSoldierUI()
    local recruit = display.newNode():addTo(self:GetView())
    -- self.tips = WidgetTips.new(_("招募队列空闲"), _("请选择一个兵种进行招募")):addTo(recruit)
    --     :align(display.CENTER, window.cx, window.top - 160)
    --     :show()

    -- self.timer = WidgetTimerProgress.new(549, 108):addTo(recruit)
    --     :align(display.CENTER, window.cx, window.top - 160)
    --     :hide()
    --     :OnButtonClicked(function(event)
    --         print("hello")
    --     end)
    -- self.timer:GetSpeedUpButton():setButtonEnabled(false)

    local rect = self.timer:getCascadeBoundingBox()
    self.list_view = self:CreateVerticalListViewDetached(rect.x, window.bottom + 70, rect.x + rect.width, rect.y - 20):addTo(recruit)

    for i, v in ipairs({
        {"swordsman", "ranger", "lancer", "catapult"},
        {"sentinel", "crossbowman", "horseArcher", "ballista"}
    }) do
        self.list_view:addItem(self:CreateItemWithListView(self.list_view, v))
    end

    local soldier_map = self.barracks_city:GetSoldierManager():GetSoldierMap()
    for k, v in pairs(self.soldier_map) do
        v:SetNumber(soldier_map[k])
    end

    self.list_view:reload()
    -- :resetPosition()
    return recruit
end
function GameUIBarracks:CreateSpecialSoldierUI()
    local special = display.newNode():addTo(self:GetView())


    local rect = self.timer:getCascadeBoundingBox()
    local list_view ,listnode=  UIKit:commonListView({
        -- bgColor = UIKit:hex2c4b(0x7a100000),
        viewRect = cc.rect(0,0, rect.width, rect.y - 10 - window.bottom - 110),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
    })
    listnode:align(display.BOTTOM_CENTER, window.cx, window.bottom_top+20):addTo(special)
    self.special_list_view = list_view

    local titles ={
        {
            title = _("亡灵部队"),
            title_img = "title_red_554x34.png",
        },
    -- {
    --     title = _("精灵部队"),
    --     title_img = "title_green_554x34.png",
    -- },
    }

    for i, v in ipairs({
        {"skeletonWarrior", "skeletonArcher", "deathKnight", "meatWagon"}
    -- {"priest", "demonHunter", "paladin", "steamTank"}
    }) do
        local item = self:CreateSpecialItemWithListView(self.special_list_view, v,titles[i].title, titles[i].title_img)
        table.insert(self.special_soldier_items,item)
        self.special_list_view:addItem(item)
    end

    local soldier_map = self.barracks_city:GetSoldierManager():GetSoldierMap()
    for k, v in pairs(self.soldier_map) do
        v:SetNumber(soldier_map[k])
    end

    self.special_list_view:reload()
    -- :resetPosition()
    return special
end
function GameUIBarracks:TabButtons()
    self.tab_buttons = self:CreateTabButtons({
        {
            label = _("招募"),
            tag = "recruit",
        },
        {
            label = _("召唤"),
            tag = "specialRecruit",
        }
    },
    function(tag)
        if tag == 'upgrade' then
            self.recruit:setVisible(false)
            self.specialRecruit:setVisible(false)
            self.timerAndTips:setVisible(false)
        elseif tag == "recruit" then
            local event = self.barracks:GetRecruitEvent()
            self.timer:setVisible(event:IsRecruting() )
            self.tips:setVisible(event:IsEmpty())
            if event:IsRecruting() then
                local soldier_type, count = event:GetRecruitInfo()
                local soldier_name = Localize.soldier_name[soldier_type]
                self.timer:SetDescribe(string.format("%s%s x%d", _("招募"), soldier_name, count))
                local current_time = app.timer:GetServerTime()
                self.timer:SetProgressInfo(GameUtils:formatTimeStyle1(event:LeftTime(current_time)), event:Percent(current_time))
            end
            self.recruit:setVisible(true)
            self.timerAndTips:setVisible(true)
            self.specialRecruit:setVisible(false)
            self:RefershUnlockInfo()
        elseif tag == "specialRecruit" then
            self.recruit:setVisible(false)
            self.timerAndTips:setVisible(true)
            self.specialRecruit:setVisible(true)
            self:RefershUnlockInfo()
        end
    end):pos(window.cx, window.bottom + 34)
end
function GameUIBarracks:CreateItemWithListView(list_view, soldiers)
    local rect = list_view:getViewRect()
    local origin_x = - rect.width / 2
    local widget_rect = self.timer:getCascadeBoundingBox()
    local unit_width = 130
    local gap_x = (widget_rect.width - unit_width * 4) / 3
    local row_item = display.newNode()
    for i, soldier_name in pairs(soldiers) do
        self.soldier_map[soldier_name] =
            WidgetSoldierBox.new(nil, function(event)
                if self.soldier_map[soldier_name]:IsLocked() then
                    return
                end
                WidgetRecruitSoldier.new(self.barracks, self.barracks_city, soldier_name)
                    :addTo(self,1000, WidgetRecruitSoldier_tag):pos(0,0)
            end):addTo(row_item)
                :alignByPoint(cc.p(0.5, 0.5), origin_x + (unit_width + gap_x) * (i - 1) + unit_width / 2, 0)
                :SetSoldier(soldier_name, self.barracks_city:GetSoldierManager():GetStarBySoldierType(soldier_name))
    end

    local item = list_view:newItem()
    item:addContent(row_item)
    item:setItemSize(widget_rect.width, 172)
    return item
end
function GameUIBarracks:CreateSpecialItemWithListView( list_view, soldiers ,title,title_img)
    local rect = list_view:getViewRect()
    local origin_x = 14
    local widget_width = 568
    local unit_width = 120
    local gap_x = (widget_width - unit_width * 4-origin_x*2) / 3
    local row_item = WidgetUIBackGround.new({height=274,width=widget_width},WidgetUIBackGround.STYLE_TYPE.STYLE_2)
    for i, soldier_name in pairs(soldiers) do
        self.soldier_map[soldier_name] =
            WidgetSoldierBox.new(nil, function(event)
                WidgetRecruitSoldier.new(self.barracks, self.barracks_city, soldier_name,self.barracks_city:GetSoldierManager():GetStarBySoldierType(soldier_name))
                    :addTo(self,1000, WidgetRecruitSoldier_tag)
                    :align(display.CENTER, window.cx, 500 / 2)
            end):addTo(row_item)
                :alignByPoint(cc.p(0.5, 0.5), origin_x + (unit_width + gap_x) * (i - 1) + unit_width / 2, 140)
                :SetSoldier(soldier_name, self.barracks_city:GetSoldierManager():GetStarBySoldierType(soldier_name))
    end

    -- title
    local title_bg = display.newSprite(title_img)
        :align(display.TOP_CENTER, row_item:getContentSize().width/2, row_item:getContentSize().height-8)
        :addTo(row_item)

    UIKit:ttfLabel({
        text = title,
        size = 22,
        color = 0xffedae
    }):addTo(title_bg)
        :align(display.CENTER, title_bg:getContentSize().width/2,title_bg:getContentSize().height/2)

    -- 招募时间限制

    local time_bg = display.newSprite("back_ground_548X34.png")
        :align(display.BOTTOM_CENTER, row_item:getContentSize().width/2, 10)
        :addTo(row_item)
    local re_time = DataUtils:GetNextRecruitTime()
    local re_string = ""
    if tolua.type(re_time) == "boolean" then
        re_string = _("招募开启中")
    else
        re_string = _("下一次开启招募:")..GameUtils:formatTimeStyle1(re_time-app.timer:GetServerTime())
    end
    local re_status = UIKit:ttfLabel({
        text = re_string,
        size = 20,
        color = 0x514d3e
    }):addTo(time_bg)
        :align(display.CENTER, time_bg:getContentSize().width/2,time_bg:getContentSize().height/2)

    local item = list_view:newItem()
    item:addContent(row_item)
    item:setItemSize(widget_width, 284)
    function item:SetRecruitStatus(string)
        re_status:setString(string)
    end
    return item
end
function GameUIBarracks:OnSoliderCountChanged()
    local soldier_map = self.barracks_city:GetSoldierManager():GetSoldierMap()
    for k, v in pairs(self.soldier_map) do
        if not v:IsLocked() then
            v:SetNumber(soldier_map[k])
        end
    end
end
function GameUIBarracks:OnSoliderStarCountChanged(soldier_manager,star_changed_map)
    for i,v in pairs(star_changed_map) do
        if self.soldier_map[v] then
            self.soldier_map[v]:SetSoldier(v, soldier_manager:GetStarBySoldierType(v))
        end
    end
end
function GameUIBarracks:RefershUnlockInfo()
    local unlock_soldiers = self.barracks:GetUnlockSoldiers()
    local level = self.barracks:GetLevel()
    for k,v in pairs(self.soldier_map) do
        if unlock_soldiers[k] then
            local is_unlock = unlock_soldiers[k] <= level
            v:Enable(is_unlock)
            if not is_unlock then
                v:SetCondition(string.format(_("兵营%d级解锁"), unlock_soldiers[k]))
            end
        end
    end
    self:OnSoliderCountChanged()
end

function GameUIBarracks:OnTimer(current_time)
    for i,v in ipairs(self.special_soldier_items) do
        local ok,time = self:GetRecruitSpecialTime()
        if ok then
            v:SetRecruitStatus(_("招募开启中"))
        else
            v:SetRecruitStatus(_("下一次开启招募:")..GameUtils:formatTimeStyle1(time-current_time))
        end
    end
end
function GameUIBarracks:GetRecruitSpecialTime()
    local re_time = DataUtils:GetNextRecruitTime()
    return tolua.type(re_time) == "boolean", re_time
end


return GameUIBarracks









