--
-- Author: Danny He
-- Date: 2015-02-24 17:12:47
--
local GameUISettingShield = UIKit:createUIClass("GameUISettingShield","UIAutoClose")
local window = import("..utils.window")
local WidgetPushButton = import("..widget.WidgetPushButton")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local UIListView = import(".UIListView")

function GameUISettingShield:ctor()
    GameUISettingShield.super.ctor(self)
    self.chatManager = app:GetChatManager()
end

function GameUISettingShield:onEnter()
    GameUISettingShield.super.onEnter(self)
    self:BuildUI()
end

function GameUISettingShield:GetChatManager()
    return self.chatManager
end

function GameUISettingShield:BuildUI()
    local bg = WidgetUIBackGround.new({height=762})
    self:addTouchAbleChild(bg)
    bg:pos(((display.width - bg:getContentSize().width)/2),window.bottom_top)
    local titleBar = display.newSprite("title_blue_600x56.png"):align(display.LEFT_BOTTOM,3,747):addTo(bg)
    local closeButton = cc.ui.UIPushButton.new({normal = "X_1.png",pressed = "X_2.png"}, {scale9 = false})
        :addTo(titleBar)
        :align(display.BOTTOM_RIGHT,titleBar:getContentSize().width,0)
        :onButtonClicked(function ()
            self:LeftButtonClicked()
        end)
    UIKit:ttfLabel({
        text = _("屏蔽用户"),
        size = 22,
        shadow = true,
        color = 0xffedae
    }):addTo(titleBar):align(display.CENTER,300,28)
    local tip_bg = UIKit:CreateBoxPanelWithBorder({width = 556,height = 106}):addTo(bg):align(display.CENTER_TOP,304,732)
    UIKit:ttfLabel({
        text = _("你无法收到屏蔽用户发送的邮件。同时在聊天界面也看不到这个用户的任何发言。"),
        size = 20,
        color=0x615b44,
        align=cc.TEXT_ALIGNMENT_CENTER,
        dimensions = cc.size(556, 60),
    }):addTo(tip_bg):align(display.CENTER, 278, 53)
    local list_bg = display.newScale9Sprite("background_568x120.png", 0,0,cc.size(568,586),cc.rect(15,10,538,100))
        :addTo(bg):align(display.BOTTOM_CENTER, 304, 20)
    self.list_view = UIListView.new{
        viewRect = cc.rect(11,10,546,566),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL,
    }:addTo(list_bg)
    self:RefreshListView()
end

function GameUISettingShield:RefreshListView()
    self.list_view:removeAllItems()
    local blockListDataSource = self:GetChatManager():GetBlockList()
    local index = 1
    for _,v in pairs(blockListDataSource) do
        local newItem = self:GetBlackListItem(index,v)
        self.list_view:addItem(newItem)
        index = index + 1
    end
    self.list_view:reload()
end

function GameUISettingShield:GetBlackListItem(index,chat)
    local item = self.list_view:newItem()
    local content = display.newScale9Sprite(string.format("back_ground_548x40_%d.png", index % 2 == 0 and 1 or 2)):size(546,96)
    local iconBg = UIKit:GetPlayerCommonIcon(chat.icon):scale(0.7):addTo(content):pos(50,48)
    local name_lable = UIKit:ttfLabel({
        text = chat.name or "player",
        size = 22,
        color= 0x403c2f,
        align= cc.TEXT_ALIGNMENT_LEFT
    }):addTo(content):pos(100,68)

    local alliance_label = UIKit:ttfLabel({
        text = chat.allianceTag or "",
        size = 16,
        color= 0x403c2f,
        align= cc.TEXT_ALIGNMENT_LEFT
    }):addTo(content):pos(100,38)

    WidgetPushButton.new({normal = 'yellow_btn_up_148x58.png',pressed = 'yellow_btn_down_148x58.png'},{scale9 = true})
        :setButtonLabel("normal",UIKit:commonButtonLable({
            text = _("取消屏蔽"),
            color = 0xfff3c7,
            size = 22,
            shadow = true
        }))
        :addTo(content):pos(460,48)
        :onButtonClicked(function()
            self:GetChatManager():RemoveItemFromBlockList(chat)
            self:RefreshListView()
        end)
    item:addContent(content)
    item:setItemSize(546,96)
    return item
end

return GameUISettingShield

