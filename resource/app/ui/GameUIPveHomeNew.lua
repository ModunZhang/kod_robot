local light_gem = import("..particles.light_gem")
local ChatManager = import("..entity.ChatManager")
local UILib = import("..ui.UILib")
local window = import("..utils.window")
local WidgetChat = import("..widget.WidgetChat")
local WidgetUseItems = import("..widget.WidgetUseItems")
local WidgetChangeMap = import("..widget.WidgetChangeMap")
local WidgetHomeBottom = import("..widget.WidgetHomeBottom")
local GameUIPVEHomeNew = UIKit:createUIClass('GameUIPVEHomeNew')

function GameUIPVEHomeNew:DisplayOn()
    self.visible_count = self.visible_count + 1
    self:FadeToSelf(self.visible_count > 0)
end
function GameUIPVEHomeNew:DisplayOff()
    self.visible_count = self.visible_count - 1
    self:FadeToSelf(self.visible_count > 0)
end
function GameUIPVEHomeNew:FadeToSelf(isFullDisplay)
    self:stopAllActions()
    if isFullDisplay then
        self:show()
        transition.fadeIn(self, {
            time = 0.2,
        })
    else
        transition.fadeOut(self, {
            time = 0.2,
            onComplete = function()
                self:hide()
            end,
        })
    end
end


function GameUIPVEHomeNew:ctor()
    GameUIPVEHomeNew.super.ctor(self, {type = UIKit.UITYPE.BACKGROUND})
end
function GameUIPVEHomeNew:onEnter()
    self.visible_count = 1
    self:CreateTop()
    self.bottom = self:CreateBottom()
end
function GameUIPVEHomeNew:CreateTop()
    local top_bg = display.newSprite("head_bg.png")
        :align(display.TOP_CENTER, window.cx, window.top)
        :addTo(self)
    local size = top_bg:getContentSize()
    top_bg:setTouchEnabled(true)

    cc.ui.UIPushButton.new({normal = "chat_btn_up_60x48.png",
        pressed = "chat_btn_down_60x48.png"}):addTo(top_bg)
        :pos(88, size.height/2 + 10)
        :onButtonClicked(function()

            end)


    local star = display.newSprite("alliance_shire_star_60x58_1.png")
    :addTo(top_bg):pos(size.width - 210, 55):scale(0.8)

    self.stars = UIKit:ttfLabel({
        text = "22/66",
        size = 22,
        color = 0xffedae,
        shadow = true,
    }):addTo(star):align(display.LEFT_CENTER, 65, 58/2)



    local reward_btn = cc.ui.UIPushButton.new(
        {normal = "back_ground_box.png", pressed = "back_ground_box.png"}
        ,{})
        :addTo(top_bg, 1):align(display.CENTER, size.width - 80, 55):scale(0.8)
        :onButtonClicked(function(event)
            end)

    display.newSprite("bottom_icon_package_66x66.png"):addTo(reward_btn)

    local button = cc.ui.UIPushButton.new(
        {normal = "gem_btn_up_196x68.png", pressed = "gem_btn_down_196x68.png"},
        {scale9 = false}
    ):onButtonClicked(function(event)
        UIKit:newGameUI("GameUIStore"):AddToCurrentScene(true)
    end):addTo(top_bg):pos(top_bg:getContentSize().width - 130, -20)
    local gem_icon = display.newSprite("gem_icon_62x61.png"):addTo(button):pos(60, 3)
    light_gem():addTo(gem_icon, 1022):pos(62/2, 61/2)

    self.gem_label = UIKit:ttfLabel({
        text = string.formatnumberthousands(City:GetUser():GetGemResource():GetValue()),
        size = 20,
        color = 0xffd200,
    }):addTo(button):align(display.CENTER, -30, 8)


    local pve_back = display.newSprite("back_ground_pve.png"):addTo(top_bg)
    :align(display.LEFT_TOP, 40, 16):flipX(true)
    local size = pve_back:getContentSize()
    display.newSprite("dragon_lv_icon.png"):addTo(pve_back):pos(size.width - 20, 25)
    local add_btn = cc.ui.UIPushButton.new(
        {normal = "add_btn_up.png",pressed = "add_btn_down.png"}
        ,{})
        :addTo(pve_back):align(display.CENTER, 25, 25)
        :onButtonClicked(function ( event )
            WidgetUseItems.new():Create({
                item_type = WidgetUseItems.USE_TYPE.STAMINA
            }):AddToCurrentScene()
        end)
    display.newSprite("+.png"):addTo(add_btn)
    self.strenth = UIKit:ttfLabel({
        text = "100/100",
        size = 20,
        color = 0xffedae,
        shadow = true,
    }):addTo(pve_back):align(display.CENTER, size.width / 2, 25)
end

function GameUIPVEHomeNew:CreateBottom()
    local bottom_bg = WidgetHomeBottom.new(City):addTo(self)
        :align(display.BOTTOM_CENTER, display.cx, display.bottom)

    self.chat = WidgetChat.new():addTo(bottom_bg)
        :align(display.CENTER, bottom_bg:getContentSize().width/2, bottom_bg:getContentSize().height-11)

    self.change_map = WidgetChangeMap.new(WidgetChangeMap.MAP_TYPE.PVE):addTo(self)

    return bottom_bg
end
function GameUIPVEHomeNew:ChangeChatChannel(channel_index)
    self.chat:ChangeChannel(channel_index)
end


return GameUIPVEHomeNew












