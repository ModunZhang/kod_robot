--
-- Author: Kenny Dai
-- Date: 2015-01-19 08:58:38
--

local WidgetProgress = import(".WidgetProgress")
local WidgetPushButton = import(".WidgetPushButton")
local WidgetSpeedUp = import(".WidgetSpeedUp")
local GameUIMilitaryTechSpeedUp = import("..ui.GameUIMilitaryTechSpeedUp")
local Localize = import("..utils.Localize")

local WidgetMilitaryTechnologyStatus = class("WidgetMilitaryTechnologyStatus", function ()
    local node = display.newNode()
    node:setNodeEventEnabled(true)
    node:align(display.CENTER_LEFT)
    node:setContentSize(cc.size(556,106))
    return node
end)

function WidgetMilitaryTechnologyStatus:ctor(building)
    self.building_type = building:GetType()
    local width , height = 556,106
    -- 描述
    self.top_bg = display.newScale9Sprite("back_ground_398x97.png", 0, 0,cc.size(556,106),cc.rect(15,10,368,77))
        :addTo(self)
    local top_bg = self.top_bg

    self.normal_node = self:CreateNormalStatus()
    self.upgrading_node = self:CreateUpgradingStatus()
    self:RefreshTop()
end
function WidgetMilitaryTechnologyStatus:CreateNormalStatus()
    local normal_node = display.newNode()
    normal_node:setContentSize(cc.size(556,106))
    normal_node:addTo(self):align(display.CENTER)
    UIKit:ttfLabel({
        text = _("研发队列空闲"),
        size = 22,
        color = 0x403c2f
    }):align(display.CENTER, normal_node:getContentSize().width/2,normal_node:getContentSize().height/2+20)
        :addTo(normal_node)
    UIKit:ttfLabel({
        text = _("请选择一个科技进行研发"),
        size = 20,
        color = 0x615b44
    }):align(display.CENTER, normal_node:getContentSize().width/2,normal_node:getContentSize().height/2-20)
        :addTo(normal_node)
    normal_node:setVisible(false)
    return normal_node
end
function WidgetMilitaryTechnologyStatus:CreateUpgradingStatus()
    local upgrading_node = display.newNode()
    upgrading_node:setContentSize(cc.size(556,106))
    upgrading_node:addTo(self):align(display.CENTER)
    --进度条
    local progress = WidgetProgress.new(0xffedae, nil, nil, {
        icon_bg = "back_ground_43x43.png",
        icon = "hourglass_30x38.png",
        bar_pos = {x = 0,y = 0}
    }):addTo(upgrading_node)
        :align(display.LEFT_CENTER, 34, 36)

    local upgrading_tip = UIKit:ttfLabel({
        size = 22,
        color = 0x403c2f
    }):align(display.LEFT_CENTER, 30,80)
        :addTo(upgrading_node)

    local upgrading_event
    local building_type = self.building_type
    if User:HasMilitaryTechEventBy(building_type) then
        upgrading_event = User:GetShortMilitaryTechEventBy(building_type)
        local time, percent = UtilsForEvent:GetEventInfo(upgrading_event)
        progress:SetProgressInfo(GameUtils:formatTimeStyle1(time), percent)
    end
    local is_free = false
    if upgrading_event then
        is_free = UtilsForEvent:GetEventInfo(upgrading_event) <= DataUtils:getFreeSpeedUpLimitTime()
    end
    local speed_up_btn = WidgetPushButton.new({normal = "green_btn_up_148x58.png",pressed = "green_btn_down_148x58.png"})
        :setButtonLabel(UIKit:ttfLabel({
            text = _("加速"),
            size = 22,
            color = 0xffedae,
            shadow= true
        }))
        :onButtonClicked(function (e)
            UIKit:newGameUI("GameUIMilitaryTechSpeedUp", self.event):AddToCurrentScene(true)
        end)
        :align(display.CENTER, 474, 44):addTo(upgrading_node)
    speed_up_btn:setVisible(not is_free)
    local free_speed_up_btn = WidgetPushButton.new({normal = "purple_btn_up_148x58.png",pressed = "purple_btn_down_148x58.png"})
        :setButtonLabel(UIKit:ttfLabel({
            text = _("免费加速"),
            size = 22,
            color = 0xffedae,
            shadow= true
        }))
        :onButtonClicked(function (e)
            local event = self.event
            local time, percent = UtilsForEvent:GetEventInfo(event)
            if time > 2 then
                NetManager:getFreeSpeedUpPromise(User:EventType(event),self.event.id)
            end
        end)
        :align(display.CENTER, 474, 44):addTo(upgrading_node)
    free_speed_up_btn:setVisible(is_free)



    function upgrading_node:SetProgressInfo(time_label, percent,isFree)
        progress:SetProgressInfo(time_label, percent)
        speed_up_btn:setVisible(not isFree)
        free_speed_up_btn:setVisible(isFree)
    end
    function upgrading_node:SetUpgradeTip(tip)
        upgrading_tip:setString(tip)
    end
    function upgrading_node:GetUpgradeTip()
        return upgrading_tip:getString()
    end
    upgrading_node:hide()
    return upgrading_node
end
function WidgetMilitaryTechnologyStatus:RefreshTop()
    local User = User
    local building_type = self.building_type

    if User:HasMilitaryTechEventBy(building_type) then
        self.event = User:GetShortMilitaryTechEventBy(building_type)
        local event = self.event
        local upgrade_node = self.upgrading_node:show()
        if User:IsMilitaryTechEvent(event) then
            local str = UtilsForEvent:GetMilitaryTechEventLocalize(event.name, User:GetMilitaryTechLevel(event.name))
            upgrade_node:SetUpgradeTip(str)
        end
        if User:IsSoldierStarEvent(event) then
            local star = UtilsForSoldier:SoldierStarByName(User, event.name)
            upgrade_node:SetUpgradeTip(string.format(_("晋升%s的星级 star %d"),Localize.soldier_name[event.name],star + 1))
        end
        self.normal_node:setVisible(false)
    else
        self.normal_node:setVisible(true)
        self.upgrading_node:setVisible(false)
        self.upgrading_node:SetProgressInfo("",0)
    end
end
function WidgetMilitaryTechnologyStatus:onEnter()
    User:AddListenOnType(self, "militaryTechEvents")
    User:AddListenOnType(self, "soldierStarEvents")
    scheduleAt(self, function()
        local event = User:GetShortMilitaryTechEventBy(self.building_type)
        if event then
            local time, percent = UtilsForEvent:GetEventInfo(event)
            self.upgrading_node:SetProgressInfo(
                GameUtils:formatTimeStyle1(time),
                percent,
                time <= DataUtils:getFreeSpeedUpLimitTime()
            )
        end
    end)
end
function WidgetMilitaryTechnologyStatus:onExit()
    User:AddListenOnType(self, "soldierStarEvents")
    User:AddListenOnType(self, "militaryTechEvents")
end
function WidgetMilitaryTechnologyStatus:OnUserDataChanged_soldierStarEvents(userData, deltaData)
    self:RefreshTop()
end
function WidgetMilitaryTechnologyStatus:OnUserDataChanged_militaryTechEvents(userData, deltaData)
    self:RefreshTop()
end
return WidgetMilitaryTechnologyStatus



















