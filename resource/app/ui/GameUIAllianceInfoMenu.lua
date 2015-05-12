--
-- Author: Kenny Dai
-- Date: 2015-05-08 21:33:31
--
local window = import("..utils.window")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local WidgetPushButton = import("..widget.WidgetPushButton")

local GameUIAllianceInfoMenu = UIKit:createUIClass("GameUIAllianceInfoMenu","UIAutoClose")

function GameUIAllianceInfoMenu:ctor()
    GameUIAllianceInfoMenu.super.ctor(self)
    self.body = display.newSprite("back_ground_588x346.png"):align(display.BOTTOM_CENTER, window.cx, window.bottom_top - 70)
    local body = self.body
    self:addTouchAbleChild(body)
end

function GameUIAllianceInfoMenu:onExit()
    GameUIAllianceInfoMenu.super.onExit(self)
end
function GameUIAllianceInfoMenu:onEnter()
    GameUIAllianceInfoMenu.super.onEnter(self)
    self:LoadAllMenus()
end
function GameUIAllianceInfoMenu:LoadAllMenus()
    local body = self.body
    local size = body:getContentSize()

	local button = WidgetPushButton.new({normal = "brown_btn_up_552x56.png",pressed = "brown_btn_down_552x56.png"})
            :setButtonLabel(UIKit:ttfLabel({
                text = _("查看联盟"),
                size = 20,
                color = 0xffedae,
            }))
            :onButtonClicked(function(event)
                if event.name == "CLICKED_EVENT" then
                	UIKit:newGameUI("GameUIAllianceInfo",nil,"info"):AddToCurrentScene(true)
                	self:LeftButtonClicked()
                end
            end)
            :align(display.CENTER_TOP, size.width/2, 325)
            :addTo(body)
    display.newSprite("icon_check_alliance_36x40.png"):addTo(button):pos(-240,-28)

   local button =  WidgetPushButton.new({normal = "brown_btn_up_552x56.png",pressed = "brown_btn_down_552x56.png"})
            :setButtonLabel(UIKit:ttfLabel({
                text = _("查看玩家"),
                size = 20,
                color = 0xffedae,
            }))
            :onButtonClicked(function(event)
                if event.name == "CLICKED_EVENT" then
                end
            end)
            :align(display.CENTER_TOP, size.width/2, 260)
            :addTo(body)
    display.newSprite("chat_check_out_62x56.png"):addTo(button):pos(-240,-28):scale(36/62)

   local button = 	WidgetPushButton.new({normal = "brown_btn_up_552x56.png",pressed = "brown_btn_down_552x56.png"})
            :setButtonLabel(UIKit:ttfLabel({
                text = _("发送邮件"),
                size = 20,
                color = 0xffedae,
            }))
            :onButtonClicked(function(event)
                if event.name == "CLICKED_EVENT" then
                end
            end)
            :align(display.CENTER_TOP, size.width/2, 195)
            :addTo(body)
    display.newSprite("chat_mail_62x56.png"):addTo(button):pos(-240,-28):scale(36/62)

   local button =  WidgetPushButton.new({normal = "brown_btn_up_552x56.png",pressed = "brown_btn_down_552x56.png"})
            :setButtonLabel(UIKit:ttfLabel({
                text = _("复制"),
                size = 20,
                color = 0xffedae,
            }))
            :onButtonClicked(function(event)
                if event.name == "CLICKED_EVENT" then
                end
            end)
            :align(display.CENTER_TOP, size.width/2, 130)
            :addTo(body)
    display.newSprite("chat_copy_62x56.png"):addTo(button):pos(-240,-28):scale(36/62)

    local button = WidgetPushButton.new({normal = "brown_btn_up_552x56.png",pressed = "brown_btn_down_552x56.png"})
            :setButtonLabel(UIKit:ttfLabel({
                text = _("屏蔽"),
                size = 20,
                color = 0xffedae,
            }))
            :onButtonClicked(function(event)
                if event.name == "CLICKED_EVENT" then
                end
            end)
            :align(display.CENTER_TOP, size.width/2, 65)
            :addTo(body)
    display.newSprite("chat_shield_62x56.png"):addTo(button):pos(-240,-28):scale(36/62)
end
return GameUIAllianceInfoMenu





