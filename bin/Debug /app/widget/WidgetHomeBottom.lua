local WidgetNumberTips = import(".WidgetNumberTips")
local WidgetChangeMap = import(".WidgetChangeMap")
local fire_var = import("app.particles.fire_var")
local WidgetHomeBottom = class("WidgetHomeBottom", function()
    local bottom_bg = display.newSprite("bottom_bg_768x136.png")
    if display.width >640 then
        bottom_bg:scale(display.width/768)
    end
    bottom_bg:setNodeEventEnabled(true)
    bottom_bg:setTouchEnabled(true)
    return bottom_bg
end)


local ALLIANCE_TAG = 222


function WidgetHomeBottom:MailUnreadChanged(...)
    self.mail_count:SetNumber(MailManager:GetUnReadMailsNum()+MailManager:GetUnReadReportsNum())
end
function WidgetHomeBottom:OnUserDataChanged_growUpTasks()
    self.task_count:SetNumber(UtilsForTask:GetCompleteTaskCount(self.city:GetUser().growUpTasks))
end
function WidgetHomeBottom:ctor(city)
    self.city = city
    -- 底部按钮
    local first_row = 64
    local first_col = 240
    local label_padding = 20
    local padding_width = 100
    for i, v in ipairs({
        {"bottom_icon_mission_62x62.png", _("任务")},
        {"bottom_icon_package_66x66.png", _("物品")},
        {"mail_icon_62x62.png", _("邮件")},
        {"bottom_icon_alliance_66x70.png", _("联盟")},
        {"bottom_icon_package_77x67.png", _("更多")},
    }) do
        local col = i - 1
        local x, y = first_col + col * padding_width, first_row
        local button = cc.ui.UIPushButton.new({normal = v[1]})
            :onButtonClicked(handler(self, self.OnBottomButtonClicked))
            :addTo(self):pos(x, y)
            :onButtonPressed(function(event)
                event.target:runAction(cc.ScaleTo:create(0.1, 1.2))
            end):onButtonRelease(function(event)
            event.target:runAction(cc.ScaleTo:create(0.1, 1))
            end):setTag(i):setLocalZOrder(10)
        UIKit:ttfLabel({
            text = v[2],
            size = 16,
            color = 0xf5e8c4})
            :addTo(self):align(display.CENTER,x, y-40)

        if i == 1 then
            self.task_btn = button
            self.task_count = WidgetNumberTips.new():addTo(self):pos(x+20, first_row+20)
            self.task_count:setLocalZOrder(11)
        elseif i == 3 then
            self.mail_count = WidgetNumberTips.new():addTo(self):pos(x+20, first_row+20)
            self.mail_count:setLocalZOrder(11)
        elseif i == 4 then
            self.alliance_btn = button
            self.alliance_btn:setLocalZOrder(9)
            local alliance = Alliance_Manager:GetMyAlliance()
            if not alliance:IsDefault() and
                alliance:GetSelf():IsTitleEqualOrGreaterThan("quartermaster") then
                self.join_request_count = WidgetNumberTips.new():addTo(self):pos(x+20, first_row+20)
                self.join_request_count:setLocalZOrder(11)
                self.join_request_count:SetNumber(#Alliance_Manager:GetMyAlliance().joinRequestEvents or 0)
            end
            if not User.countInfo.firstJoinAllianceRewardGeted then
                fire_var():addTo(self.alliance_btn, -1000, 321)
            end
        end
    end
    display.newNode():addTo(self):schedule(function()
        self:TipsOnTaskCount()
    end, 5)
end
function WidgetHomeBottom:onEnter()
    local user = self.city:GetUser()
    MailManager:AddListenOnType(self,MailManager.LISTEN_TYPE.UNREAD_MAILS_CHANGED)
    user:AddListenOnType(self, "growUpTasks")
    user:AddListenOnType(self, "countInfo")
    Alliance_Manager:GetMyAlliance():AddListenOnType(self, "joinRequestEvents")

    self:OnUserDataChanged_growUpTasks()
    self:MailUnreadChanged()
end
function WidgetHomeBottom:onExit()
    local user = self.city:GetUser()
    MailManager:RemoveListenerOnType(self,MailManager.LISTEN_TYPE.UNREAD_MAILS_CHANGED)
    user:RemoveListenerOnType(self, "growUpTasks")
    user:RemoveListenerOnType(self, "countInfo")
    Alliance_Manager:GetMyAlliance():RemoveListenerOnType(self, "joinRequestEvents")
end
function WidgetHomeBottom:OnBottomButtonClicked(event)
    local tag = event.target:getTag()
    if not tag then return end
    if tag == 4 then -- tag 4 = alliance button
        local alliance = Alliance_Manager:GetMyAlliance()
        if alliance:IsDefault() and not User.countInfo.firstJoinAllianceRewardGeted then
            UIKit:newGameUI("GameUIAllianceJoinTips"):AddToCurrentScene(true)
        else
            UIKit:newGameUI('GameUIAlliance'):AddToCurrentScene(true)
        end
        self.alliance_btn:removeChildByTag(ALLIANCE_TAG)
    elseif tag == 3 then
        UIKit:newGameUI('GameUIMail',self.city):AddToCurrentScene(true)
    elseif tag == 2 then
        UIKit:newGameUI('GameUIItems',self.city,"myItems"):AddToCurrentScene(true)
    elseif tag == 1 then
        UIKit:newGameUI('GameUIMission',self.city):AddToCurrentScene(true)
    elseif tag == 5 then
        UIKit:newGameUI('GameUISetting',self.city):AddToCurrentScene(true)
    end
end
function WidgetHomeBottom:TipsOnTaskCount()
    if self.task_count:getNumberOfRunningActions() > 0 or
        not self.task_count:isVisible() then
        return
    end
    self.task_count:runAction(cc.JumpBy:create(1, cc.p(0,0), 30, 3))
end
function WidgetHomeBottom:OnUserDataChanged_countInfo(userData, deltaData)
    if User.countInfo.firstJoinAllianceRewardGeted then
        self.alliance_btn:removeChildByTag(321, cleanup)
    end
end
function WidgetHomeBottom:OnAllianceDataChanged_joinRequestEvents(alliance,deltaData)
    if self.join_request_count then
        self.join_request_count:SetNumber(#alliance.joinRequestEvents or 0)
    end
end
-- fte
local WidgetFteArrow = import(".WidgetFteArrow")
local WidgetFteMark = import(".WidgetFteMark")
function WidgetHomeBottom:TipsOnAlliance()
    -- WidgetFteMark.new()
    --     :Size(100, 100)
    --     :addTo(self.alliance_btn, 1, 111)
    self.alliance_btn:removeChildByTag(ALLIANCE_TAG)

    WidgetFteArrow.new(_("加入或创建联盟\n开启多人团战玩法"))
        :TurnDown():align(display.BOTTOM_CENTER, 0, 50)
        :addTo(self.alliance_btn, 1, ALLIANCE_TAG)

    self:stopAllActions()
    self:performWithDelay(function() self.alliance_btn:removeChildByTag(ALLIANCE_TAG) end, 5)
end


return WidgetHomeBottom






