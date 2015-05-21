local window = import("..utils.window")
local UIPageView = import("..ui.UIPageView")
local WidgetChat = import("..widget.WidgetChat")
local WidgetChangeMap = import("..widget.WidgetChangeMap")
local WidgetPushButton = import("..widget.WidgetPushButton")
local GameUICityInfo = UIKit:createUIClass('GameUICityInfo')

function GameUICityInfo:ctor(user, location)
    GameUICityInfo.super.ctor(self, {type = UIKit.UITYPE.BACKGROUND})
    self.user = user
    self.location = location
end

function GameUICityInfo:onEnter()
    GameUICityInfo.super.onEnter(self)
    self:CreateTop()
    self:CreateBottom()
end
function GameUICityInfo:onExit()
    GameUICityInfo.super.onExit(self)
end
function GameUICityInfo:CreateTop()
    local top_bg = display.newSprite("top_bg_768x116.png"):addTo(self)
        :align(display.TOP_CENTER, display.cx, display.top )
    if display.width>640 then
        top_bg:scale(display.width/768)
    end
    -- 玩家按钮
    local button = cc.ui.UIPushButton.new(
        {normal = "player_btn_up_314x86.png", pressed = "player_btn_down_314x86.png"},
        {scale9 = false}
    ):onButtonClicked(function(event)
        -- if event.name == "CLICKED_EVENT" then
        --     UIKit:newGameUI('GameUIVip', self.city,"info"):AddToCurrentScene(true)
        -- end
        end):addTo(top_bg):align(display.LEFT_CENTER,top_bg:getContentSize().width/2-2, top_bg:getContentSize().height/2+10)
    button:setRotationSkewY(180)
    -- 玩家名字背景加文字
    local ox = 159
    local name_bg = display.newSprite("player_name_bg_168x30.png"):addTo(top_bg)
        :align(display.TOP_LEFT, ox, top_bg:getContentSize().height-10):setCascadeOpacityEnabled(true)
    self.name_label = cc.ui.UILabel.new({
        text = self.user:Name(),
        size = 18,
        font = UIKit:getFontFilePath(),
        align = cc.ui.TEXT_ALIGN_RIGHT,
        color = UIKit:hex2c3b(0xf3f0b6)
    }):addTo(name_bg):align(display.LEFT_CENTER, 14, name_bg:getContentSize().height/2 + 3)

    -- 玩家战斗值图片
    display.newSprite("power_16x19.png"):addTo(top_bg):pos(ox + 20, 65)


    -- 玩家战斗值文字
    UIKit:ttfLabel({
        text = _("战斗值："),
        size = 14,
        color = 0x9a946b,
        shadow = true
    }):addTo(top_bg):align(display.LEFT_CENTER, ox + 30, 65)

    -- 玩家战斗值数字
    self.power_label = UIKit:ttfLabel({
        text = self.user:Power(),
        size = 20,
        color = 0xf3f0b6,
        shadow = true
    }):addTo(top_bg):align(display.LEFT_CENTER, ox + 14, 42)

    -- 资源按钮
    local button = cc.ui.UIPushButton.new(
        {normal = "player_btn_up_314x86.png", pressed = "player_btn_down_314x86.png"},
        {scale9 = false}
    ):onButtonClicked(function(event)
        -- if event.name == "CLICKED_EVENT" then
        --     UIKit:newGameUI("GameUIResourceOverview",self.city):AddToCurrentScene(true)
        -- end
        end):addTo(top_bg):align(display.LEFT_CENTER, top_bg:getContentSize().width/2+2, top_bg:getContentSize().height/2+10)

    -- 资源图片和文字
    local first_row = 18
    local first_col = 18
    local label_padding = 15
    local padding_width = 100
    local padding_height = 35
    for i, v in ipairs({
        {"res_wood_82x73.png", "wood_label"},
        {"res_stone_88x82.png", "stone_label"},
        {"res_citizen_88x82.png", "citizen_label"},
        {"res_food_91x74.png", "food_label"},
        {"res_iron_91x63.png", "iron_label"},
        {"res_coin_81x68.png", "coin_label"},
    }) do
        local row = i > 3 and 1 or 0
        local col = (i - 1) % 3
        local x, y = first_col + col * padding_width, first_row - (row * padding_height)
        display.newSprite(v[1]):addTo(button):pos(x, y):scale(0.4)

        self[v[2]] = UIKit:ttfLabel({text = "-",
            size = 18,
            color = 0xf3f0b6,
            shadow = true
        }):addTo(button):pos(x + label_padding, y)
    end

    -- 玩家信息背景
    local player_bg = display.newSprite("player_bg_110x106.png")
    :align(display.LEFT_BOTTOM, display.width>640 and 58 or 64, 10)
    :addTo(top_bg, 2):setCascadeOpacityEnabled(true)
    self.player_icon = UIKit:GetPlayerIconOnly(self.user:Icon())
    :addTo(player_bg):pos(55, 64):scale(0.72)
    self.exp = display.newProgressTimer("player_exp_bar_110x106.png", 
        display.PROGRESS_TIMER_RADIAL):addTo(player_bg):pos(55, 53)
    self.exp:setRotationSkewY(180)

    local level_bg = display.newSprite("level_bg_72x19.png"):addTo(player_bg):pos(55, 18)
    self.level_label = UIKit:ttfLabel({
        text = self.user:Level(),
        size = 14,
        color = 0xfff1cc,
        shadow = true,
    }):addTo(level_bg):align(display.CENTER, 37, 11)

    -- vip
    local vip_btn = cc.ui.UIPushButton.new(
        {},
        {scale9 = false}
    ):addTo(top_bg):align(display.CENTER, ox + 195, 65)
        :onButtonClicked(function(event)
            -- if event.name == "CLICKED_EVENT" then
            --     UIKit:newGameUI('GameUIVip', City,"VIP"):AddToCurrentScene(true)
            -- end
        end)
    local vip_btn_img = User:IsVIPActived() and "vip_bg_110x124.png" or "vip_bg_disable_110x124.png"
    vip_btn:setButtonImage(cc.ui.UIPushButton.NORMAL, vip_btn_img, true)
    vip_btn:setButtonImage(cc.ui.UIPushButton.PRESSED, vip_btn_img, true)
    self.vip_level = display.newNode():addTo(vip_btn):pos(-3, 0):scale(0.8)
    display.newSprite(string.format("VIP_%d_46x32.png", 1))
    :addTo(self.vip_level)

    return top_bg
end


function GameUICityInfo:CreateBottom()
    -- 底部背景
    local bottom_bg = display.newSprite("bottom_bg_768x136.png")
        :align(display.BOTTOM_CENTER, display.cx, display.bottom)
        :addTo(self)
    bottom_bg:setTouchEnabled(true)
    if display.width >640 then
        bottom_bg:scale(display.width/768)
    end

    self.chat = WidgetChat.new():addTo(bottom_bg)
        :align(display.CENTER, bottom_bg:getContentSize().width/2, bottom_bg:getContentSize().height-11)

    cc.ui.UILabel.new({text = "您正在访问其他玩家的城市, 无法使用其他功能, 点击左下角返回城市",
        size = 20,
        font = UIKit:getFontFilePath(),
        align = cc.ui.TEXT_ALIGN_CENTER,
        valign = cc.ui.TEXT_VALIGN_CENTER,
        dimensions = cc.size(400, 100),
        color = UIKit:hex2c3b(0xe19319)})
        :addTo(bottom_bg):align(display.LEFT_CENTER, 250, display.bottom + 101/2)

    local map_node = WidgetChangeMap.new(WidgetChangeMap.MAP_TYPE.OTHER_CITY, self.location):addTo(self)
end

return GameUICityInfo















