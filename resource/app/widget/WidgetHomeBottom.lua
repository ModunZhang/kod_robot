local WidgetNumberTips = import(".WidgetNumberTips")
local WidgetChangeMap = import(".WidgetChangeMap")
local WidgetHomeBottom = class("WidgetHomeBottom", function()
    local bottom_bg = display.newSprite("bottom_bg_768x136.png")
    if display.width >640 then
        bottom_bg:scale(display.width/768)
    end
    bottom_bg:setNodeEventEnabled(true)
    bottom_bg:setTouchEnabled(true)
    return bottom_bg
end)


function WidgetHomeBottom:MailUnreadChanged(...)
    self.mail_count:SetNumber(MailManager:GetUnReadMailsNum()+MailManager:GetUnReadReportsNum())
end
function WidgetHomeBottom:OnTaskChanged()
    self.task_count:SetNumber(self.city:GetUser():GetTaskManager():GetCompleteTaskCount())
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
            self.task_count = WidgetNumberTips.new():addTo(self):pos(x+20, first_row+20)
            self.task_count:setLocalZOrder(11)
        elseif i == 3 then
            self.mail_count = WidgetNumberTips.new():addTo(self):pos(x+20, first_row+20)
            self.mail_count:setLocalZOrder(11)
        end
    end
end
function WidgetHomeBottom:onEnter()
    local user = self.city:GetUser()
    MailManager:AddListenOnType(self,MailManager.LISTEN_TYPE.UNREAD_MAILS_CHANGED)
    user:AddListenOnType(self, user.LISTEN_TYPE.TASK)
    
    self:OnTaskChanged()
    self:MailUnreadChanged()
end
function WidgetHomeBottom:onExit()
    local user = self.city:GetUser()
    MailManager:RemoveListenerOnType(self,MailManager.LISTEN_TYPE.UNREAD_MAILS_CHANGED)
    user:RemoveListenerOnType(self, user.LISTEN_TYPE.TASK)
end
function WidgetHomeBottom:OnBottomButtonClicked(event)
    local tag = event.target:getTag()
    if not tag then return end
    if tag == 4 then -- tag 4 = alliance button
        UIKit:newGameUI('GameUIAlliance'):AddToCurrentScene(true)
    elseif tag == 3 then
        UIKit:newGameUI('GameUIMail',self.city):AddToCurrentScene(true)
    elseif tag == 2 then
        UIKit:newGameUI('GameUIItems',self.city):AddToCurrentScene(true)
    elseif tag == 1 then
        UIKit:newGameUI('GameUIMission',self.city):AddToCurrentScene(true)
    elseif tag == 5 then
        UIKit:newGameUI('GameUISetting',self.city):AddToCurrentScene(true)
    end
end


return WidgetHomeBottom



