--
-- Author: Kenny Dai
-- Date: 2015-05-08 21:33:31
--
local window = import("..utils.window")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local WidgetPushButton = import("..widget.WidgetPushButton")

local GameUIAllianceInfoMenu = UIKit:createUIClass("GameUIAllianceInfoMenu","UIAutoClose")

function GameUIAllianceInfoMenu:ctor(callback,alliance_buttong_str,enable_alliance_info)
    GameUIAllianceInfoMenu.super.ctor(self)
    self.body = display.newScale9Sprite("back_ground_588x346.png",window.cx, window.bottom_top - 416, cc.size(588,290), cc.rect(10,10,568,326)):align(display.BOTTOM_CENTER) --window.bottom_top - 70
    local body = self.body
    self:addTouchAbleChild(body)
    self.callback = callback
    self.alliance_buttong_str = alliance_buttong_str or ""
    self.enable_alliance_info = enable_alliance_info or false
end

function GameUIAllianceInfoMenu:UIAnimationMoveIn()
    
    transition.moveTo(self.body,{
        time = 0.15,
        y = window.bottom_top - 70,
        onComplete = function()
            self:OnMoveInStage()
        end
    })
end
function GameUIAllianceInfoMenu:UIAnimationMoveOut()
    self:CallEventCallback("uiAnimationMoveout", self.body)
     transition.moveBy(self.body,{
        time = 0.15,
        y = window.bottom_top - 416,
        onComplete = function()
            self:OnMoveOutStage()
        end
    })
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

	-- local button = WidgetPushButton.new({normal = "brown_btn_up_552x56.png",pressed = "brown_btn_down_552x56.png",disabled = "disbale_552x56.png"})
 --            :setButtonLabel(UIKit:ttfLabel({
 --                text = self.alliance_buttong_str ,
 --                size = 20,
 --                color = 0xffedae,
 --            }))
 --            :onButtonClicked(function(event)
 --                if event.name == "CLICKED_EVENT" then
 --                    self:CallButtonActionWithTag("allianceInfo")
 --                end
 --            end)
 --            :align(display.CENTER_TOP, size.width/2, 325)
 --            :addTo(body):setButtonEnabled(self.enable_alliance_info)
 --    display.newSprite("icon_check_alliance_36x40.png"):addTo(button):pos(-240,-28)

   local button =  WidgetPushButton.new({normal = "brown_btn_up_552x56.png",pressed = "brown_btn_down_552x56.png"})
            :setButtonLabel(UIKit:ttfLabel({
                text = _("查看玩家"),
                size = 20,
                color = 0xffedae,
            }))
            :onButtonClicked(function(event)
                if event.name == "CLICKED_EVENT" then
                    self:CallButtonActionWithTag("playerInfo")
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
                    self:CallButtonActionWithTag("sendMail")
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
                    self:CallButtonActionWithTag("copyAction")
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
                    self:CallButtonActionWithTag("blockChat")
                end
            end)
            :align(display.CENTER_TOP, size.width/2, 65)
            :addTo(body)
    display.newSprite("chat_shield_62x56.png"):addTo(button):pos(-240,-28):scale(36/62)
end

function GameUIAllianceInfoMenu:CallButtonActionWithTag(tag)
    self.tag_call = tag
    self:LeftButtonClicked()
end

function GameUIAllianceInfoMenu:CallEventCallback(event,data)
    if self.callback then self.callback(event,data) end
end

function GameUIAllianceInfoMenu:OnMoveOutStage()
    local tag = self.tag_call or ""
    self:CallEventCallback('out',{layer = self.body,tag = tag})
    if self.callback then self.callback("buttonCallback",tag) end
    GameUIAllianceInfoMenu.super.OnMoveOutStage(self)
end

function GameUIAllianceInfoMenu:OnMoveInStage()
    self:CallEventCallback('in',self.body)
end

return GameUIAllianceInfoMenu





