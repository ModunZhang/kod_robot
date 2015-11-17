--
-- Author: gaozhou
-- Date: 2014-08-18 14:33:28
--
local window = import("..utils.window")
local Localize = import("..utils.Localize")
local WidgetTips = import("..widget.WidgetTips")
local WidgetFteArrow = import("..widget.WidgetFteArrow")
local WidgetSoldierBox = import("..widget.WidgetSoldierBox")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local WidgetTimerProgress = import("..widget.WidgetTimerProgress")
local WidgetRecruitSoldier = import("..widget.WidgetRecruitSoldier")
local GameUIBarracks = UIKit:createUIClass("GameUIBarracks", "GameUIUpgradeBuilding")
local WidgetRecruitSoldier_tag = 1
function GameUIBarracks:ctor(city, barracks,default_tab,need_recruit_soldier)
    GameUIBarracks.super.ctor(self, city, _("兵营"),barracks,default_tab)
    self.barracks_city = city
    self.barracks = barracks
    self.need_recruit_soldier = need_recruit_soldier

end
function GameUIBarracks:OnMoveInStage()
    self.soldier_map = {}
    self.timerAndTips = self:CreateTimerAndTips()
    self.recruit = self:CreateSoldierUI()
    self.specialRecruit = self:CreateSpecialSoldierUI()
    self:TabButtons()
    GameUIBarracks.super.OnMoveInStage(self)
    local User = self.barracks_city:GetUser()
    User:AddListenOnType(self, "soldiers")
    User:AddListenOnType(self, "soldierStars")
    User:AddListenOnType(self, "soldierEvents")
    User:AddListenOnType(self, "buildingEvents")
    scheduleAt(self, function()
        if self.timerAndTips:isVisible() then
            local event = User:GetSoldierEventsBySeq()[1]
            self.timer:setVisible(event ~= nil)
            self.tips:setVisible(event == nil)
            if event then
                local time, percent = UtilsForEvent:GetEventInfo(event)
                self.timer:SetDescribe(string.format(_("招募%s x%d"), 
                Localize.soldier_name[event.name], event.count))
                self.timer:SetProgressInfo(GameUtils:formatTimeStyle1(time), percent)
            end
        end
    end)
end
function GameUIBarracks:onExit()
    local User = self.barracks_city:GetUser()
    User:RemoveListenerOnType(self, "soldiers")
    User:RemoveListenerOnType(self, "soldierStars")
    User:RemoveListenerOnType(self, "soldierEvents")
    User:RemoveListenerOnType(self, "buildingEvents")
    GameUIBarracks.super.onExit(self)
end
function GameUIBarracks:RightButtonClicked()
    if self:GetView():getChildByTag(WidgetRecruitSoldier_tag) then
        self:GetView():getChildByTag(WidgetRecruitSoldier_tag):removeFromParent()
    end
    GameUIBarracks.super.RightButtonClicked(self)
end
function GameUIBarracks:OnUserDataChanged_buildingEvents()
    self:RefershUnlockInfo()
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
            UIKit:newGameUI("GameUIBarracksSpeedUp"):AddToCurrentScene(true)
        end)
    return timerAndTips
end

function GameUIBarracks:CreateSoldierUI()
    local recruit = display.newNode():addTo(self:GetView())

    local rect = self.timer:getCascadeBoundingBox()
    local list_view ,listnode=  UIKit:commonListView({
        -- bgColor = UIKit:hex2c4b(0x7a100000),
        viewRect = cc.rect(0,0, rect.width, rect.y - 10 - window.bottom - 110),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
    })
    listnode:align(display.BOTTOM_CENTER, window.cx, window.bottom_top+20):addTo(recruit)
    self.list_view = list_view
    -- self.list_view = self:CreateVerticalListViewDetached(rect.x, window.bottom + 70, rect.x + rect.width, rect.y - 20):addTo(recruit)
    local titles ={
        {
            title = _("防守型部队"),
            title_img = "title_blue_554x34.png",
        },
        {
            title = _("攻击型部队"),
            title_img = "title_red_556x34.png",
        },
    }
    for i, v in ipairs({
        {"swordsman", "ranger", "lancer", "catapult"},
        {"sentinel", "crossbowman", "horseArcher", "ballista"}
    }) do
        local item = self:CreateSpecialItemWithListView(self.list_view, v,titles[i].title, titles[i].title_img,i == 1 and _("此系列单位生命属性较高") or _("此系列单位攻击属性较高"))
        self.list_view:addItem(item)
    end

   

    local soldier_map = self.barracks_city:GetUser().soldiers
    for k, v in pairs(self.soldier_map) do
        v:SetNumber(soldier_map[k])
    end

    self.list_view:reload()
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
            title_img = "title_red_556x34.png",
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
        local item = self:CreateSpecialItemWithListView(self.special_list_view, v,titles[i].title, titles[i].title_img,i == 1 and _("此系列单位无维护费") or "")
        self.special_list_view:addItem(item)
    end

    local soldier_map = self.barracks_city:GetUser().soldiers
    for k, v in pairs(self.soldier_map) do
        v:SetNumber(soldier_map[k])
    end

    self.special_list_view:reload()
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
local arrow_left_dir_map = {
    swordsman = true,
    sentinel = true,
    ranger = true,
    crossbowman = true,
    lancer = false,
    horseArcher = false,
    catapult = false,
    ballista = false,
}
function GameUIBarracks:CreateItemWithListView(list_view, soldiers)
    local rect = list_view:getViewRect()
    local origin_x = - rect.width / 2
    local widget_rect = self.timer:getCascadeBoundingBox()
    local unit_width = 130
    local gap_x = (widget_rect.width - unit_width * 4) / 3
    local row_item = display.newNode()
    local need_up_view = false
    for i, soldier_name in pairs(soldiers) do
        self.soldier_map[soldier_name] =
            WidgetSoldierBox.new(nil, function(event)
                if self.soldier_map[soldier_name]:IsLocked() then
                    return
                end
                self.soldier_map[soldier_name]:removeChildByTag(111)
                WidgetRecruitSoldier.new(self.barracks, self.barracks_city, soldier_name)
                    :addTo(self,1000, WidgetRecruitSoldier_tag):pos(0,0)
            end):addTo(row_item)
                :alignByPoint(cc.p(0.5, 0.5), origin_x + (unit_width + gap_x) * (i - 1) + unit_width / 2, 0)
                :SetSoldier(soldier_name, self.barracks_city:GetUser():SoldierStarByName(soldier_name))
        if self.need_recruit_soldier == soldier_name then
            if arrow_left_dir_map[soldier_name] then
                WidgetFteArrow.new(_("点击士兵"))
                :addTo(self.soldier_map[soldier_name],1,111)
                :TurnLeft():align(display.LEFT_CENTER, 50, 20)    
            else
                WidgetFteArrow.new(_("点击士兵"))
                :addTo(self.soldier_map[soldier_name],1,111)
                :TurnRight():align(display.RIGHT_CENTER, -50, 20)
            end
            self.soldier_map[soldier_name]:zorder(10)
            need_up_view = true
        end
    end

    local item = list_view:newItem()
    item:addContent(row_item)
    if need_up_view then 
        item:zorder(100)
    end
    item:setItemSize(widget_rect.width, 172)
    return item
end
function GameUIBarracks:CreateSpecialItemWithListView( list_view, soldiers ,title,title_img , desc)
    local rect = list_view:getViewRect()
    local origin_x = 14
    local widget_width = 568
    local unit_width = 120
    local gap_x = (widget_width - unit_width * 4-origin_x*2) / 3
    local row_height = desc and 264 or 230
    local row_item = WidgetUIBackGround.new({height = row_height,width = widget_width},WidgetUIBackGround.STYLE_TYPE.STYLE_2)
    for i, soldier_name in pairs(soldiers) do
        self.soldier_map[soldier_name] =
            WidgetSoldierBox.new(nil, function(event)
                if self.soldier_map[soldier_name]:IsLocked() then
                    return
                end
                WidgetRecruitSoldier.new(self.barracks, self.barracks_city, soldier_name,self.barracks_city:GetUser():SoldierStarByName(soldier_name))
                    :addTo(self,1000, WidgetRecruitSoldier_tag)
                    :align(display.CENTER, window.cx, 500 / 2)
            end):addTo(row_item)
                :alignByPoint(cc.p(0.5, 0.5), origin_x + (unit_width + gap_x) * (i - 1) + unit_width / 2, row_height - 130)
                :SetSoldier(soldier_name, self.barracks_city:GetUser():SoldierStarByName(soldier_name))
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

    -- 介绍
    if desc then
        local desc_bg = display.newScale9Sprite("back_ground_166x84.png", 0,0,cc.size(548,34),cc.rect(15,10,136,64))
            :align(display.BOTTOM_CENTER, row_item:getContentSize().width/2, 10)
            :addTo(row_item)
        local re_status = UIKit:ttfLabel({
            text = desc,
            size = 20,
            color = 0x514d3e
        }):addTo(desc_bg)
            :align(display.CENTER, desc_bg:getContentSize().width/2,desc_bg:getContentSize().height/2)
    end

    local item = list_view:newItem()
    item:addContent(row_item)
    item:setItemSize(widget_width, row_height)
    return item
end
function GameUIBarracks:OnUserDataChanged_soldiers()
    local soldier_map = self.barracks_city:GetUser().soldiers
    for k, v in pairs(self.soldier_map) do
        if not v:IsLocked() then
            v:SetNumber(soldier_map[k])
        end
    end
end
function GameUIBarracks:OnUserDataChanged_soldierStars(userData, deltaData)
    local ok, value = deltaData("soldierStars")
    if ok then
        for soldier_name,star in pairs(value) do
            if self.soldier_map[soldier_name] then
                self.soldier_map[soldier_name]:SetSoldier(soldier_name, star)
            end
        end
    end
end
function GameUIBarracks:OnUserDataChanged_soldierEvents(userData, deltaData)
    if deltaData("soldierEvents.remove") then
        self.tips:setVisible(true)
        self.timer:setVisible(false)
    elseif deltaData("soldierEvents.add") then
       self.tips:setVisible(false) 
       self.timer:setVisible(true)
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
    self:OnUserDataChanged_soldiers()
end

function GameUIBarracks:GetRecruitSpecialTime()
    local re_time = DataUtils:GetNextRecruitTime()
    return tolua.type(re_time) == "boolean", re_time
end


return GameUIBarracks









