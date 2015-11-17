--
-- Author: Danny He
-- Date: 2015-02-24 08:49:25
--
local GameUISettingPush = UIKit:createUIClass("GameUISettingPush","UIAutoClose")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local UIListView = import(".UIListView")
local WidgetBackGroundTabButtons = import("..widget.WidgetBackGroundTabButtons")
local window = import("..utils.window")
local UICheckBoxButton = import(".UICheckBoxButton")

local CHECKBOX_BUTTON_IMAGES = {
    off = "CheckBoxButtonOff_100x56.png",
    on = "CheckBoxButtonOn_100x56.png",
}

function GameUISettingPush:onEnter()
    GameUISettingPush.super.onEnter(self)
    self:BuildUI()
end

function GameUISettingPush:BuildUI()
    local bg = WidgetUIBackGround.new({height=762})
    self:addTouchAbleChild(bg)
    bg:pos(((display.width - bg:getContentSize().width)/2),window.bottom_top)
    self.bg = bg
    local titleBar = display.newSprite("title_blue_600x56.png"):align(display.LEFT_BOTTOM,3,747):addTo(bg)
    local closeButton = cc.ui.UIPushButton.new({normal = "X_1.png",pressed = "X_2.png"}, {scale9 = false})
        :addTo(titleBar)
        :align(display.BOTTOM_RIGHT,titleBar:getContentSize().width,0)
        :onButtonClicked(function ()
            self:LeftButtonClicked()
        end)
    UIKit:ttfLabel({
        text = _("推送通知"),
        size = 22,
        shadow = true,
        color = 0xffedae
    }):addTo(titleBar):align(display.CENTER,300,28)

    WidgetBackGroundTabButtons.new({
        {
            label = _("通知"),
            tag = "notice",
            default = true
        },
        {
            label = _("提醒"),
            tag = "remind",
        },
    }, function(tag)
        if tag == 'notice' then
            if not self.push_node then
                self.push_node =self:CreatePushNode():addTo(bg)
            else
                self.push_node:show()
            end
            if self.remind_node then
                self.remind_node:hide()
            end
        else
            if not self.remind_node then
                self.remind_node = self:CreateRemindNode():addTo(bg)
            else
                self.remind_node:show()
            end
            if self.push_node then
                self.push_node:hide()
            end
        end
    end):addTo(bg):pos(bg:getContentSize().width/2,34)
end
function GameUISettingPush:CreatePushNode()
    local list = UIListView.new({
        viewRect = cc.rect(26,83, 560, 666),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
    })

    local push_datas = {
        {_("建筑队列完成提醒"),app:GetPushManager():GetBuildPushState()},
        {_("招募兵种完成提醒"),app:GetPushManager():GetSoldierPushState()},
        {_("科技研发完成提醒"),app:GetPushManager():GetTechnologyPushState()},
        {_("工具&装备制造完成提醒"),app:GetPushManager():GetToolEquipemtPushState()},
        {_("瞭望塔预警提醒"),app:GetPushManager():GetWatchTowerPushState()},
        {_("圣地战提醒"),User.apnStatus.onAllianceShrineEventStart},
        {_("联盟战提醒"),User.apnStatus.onAllianceFightPrepare},
        {_("被攻打提醒"),User.apnStatus.onCityBeAttacked},
    }

    for i,v in ipairs(push_datas) do
        local item = list:newItem()
        item:setItemSize(556, 110)
        local content = UIKit:CreateBoxPanelWithBorder({width = 556,height = 96})
        UIKit:ttfLabel({
            text = v[1],
            size = 20,
            color= 0x615b44
        }):align(display.CENTER_LEFT,15,48):addTo(content)

        local button = UICheckBoxButton.new(CHECKBOX_BUTTON_IMAGES)
            :setButtonLabelAlignment(display.CENTER)
            :onButtonStateChanged(function(event)
                self:onButtonStateChanged(event.target)
            end)
            :align(display.RIGHT_CENTER, 540, 48)
            :addTo(content)
            :setButtonSelected(v[2],true)
        button:setTag(i)
        item:addContent(content)
        list:addItem(item)
    end
    list:reload()
    return list
end
function GameUISettingPush:onButtonStateChanged(button)
    local tag = button:getTag()
    local isOn = button:isButtonSelected()
    if tag == 1 then
        app:GetPushManager():SwitchBuildPush(isOn)
    elseif tag == 2 then
        app:GetPushManager():SwitchSoldierPush(isOn)
    elseif tag == 3 then
        app:GetPushManager():SwitchTechnologyPush(isOn)
    elseif tag == 4 then
        app:GetPushManager():SwitchToolEquipmentPush(isOn)
    elseif tag == 5 then
        app:GetPushManager():SwitchWatchTowerPush(isOn)
    elseif tag == 6 then
        NetManager:getSetApnStatusPromise("onAllianceShrineEventStart",isOn)
    elseif tag == 7 then
        NetManager:getSetApnStatusPromise("onAllianceFightPrepare",isOn)
        NetManager:getSetApnStatusPromise("onAllianceFightStart",isOn)
    elseif tag == 8 then
        NetManager:getSetApnStatusPromise("onCityBeAttacked",isOn)
    end
end
function GameUISettingPush:CreateRemindNode()
    local remind_node = display.newNode()
    remind_node:setContentSize(self.bg:getContentSize())
    local bg = remind_node

    local gem_remind_bg = UIKit:CreateBoxPanelWithBorder({width = 556,height = 96})
        :align(display.CENTER_TOP,304,732)
        :addTo(bg)
    UIKit:ttfLabel({
        text = _("金龙币消费提醒"),
        size = 20,
        color= 0x615b44
    }):align(display.CENTER_LEFT,15,48):addTo(gem_remind_bg)
    local gem_remind_button = UICheckBoxButton.new(CHECKBOX_BUTTON_IMAGES)
        :setButtonLabelAlignment(display.CENTER)
        :onButtonStateChanged(function(event)
            self:onRemindButtonStateChanged(event.target)
        end)
        :align(display.RIGHT_CENTER, 540, 48)
        :addTo(gem_remind_bg)
        :setButtonSelected(app:GetGameDefautlt():IsOpenGemRemind() ,true)
    gem_remind_button:setTag(1)

    return remind_node
end
function GameUISettingPush:onRemindButtonStateChanged(button)
    local tag = button:getTag()
    local isOn = button:isButtonSelected()
    if tag == 1 then
        if isOn then
            app:GetGameDefautlt():OpenGemRemind()
        else
            app:GetGameDefautlt():CloseGemRemind()()
        end
    end
end
return GameUISettingPush


