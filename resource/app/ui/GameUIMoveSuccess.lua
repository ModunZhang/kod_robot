local GameUIMoveSuccess = UIKit:createUIClass("GameUIMoveSuccess", "UIAutoClose")
function GameUIMoveSuccess:ctor(fromIndex, toIndex)
    GameUIMoveSuccess.super.ctor(self)
    -- self.bg = cc.ui.UIPushButton.new({normal = "player_levelup_bg.png"}, nil, {})
    --     :align(display.CENTER, display.cx, display.cy)
    --     :onButtonClicked(function()
    --         self:LeftButtonClicked()
    --     end)

    -- self.bg = cc.ui.UIPushButton.new({
    -- normal = "tips_bg_header_640x140.png"}, nil, {})
    -- :align(display.CENTER, display.cx, display.cy)
    -- :onButtonClicked(function()
    --     self:LeftButtonClicked()
    -- end)
    self.bg = display.newNode():pos(display.cx, display.cy + 250)
    local header_sp = display.newSprite("tips_bg_header_640x140.png")
                      :align(display.TOP_CENTER, - 15, - 30)
                      :addTo(self.bg, 1)
    local rect = cc.rect(0,0,display.width,header_sp:getPositionY()-18)
    local height = 285
    display.newScale9Sprite("tips_bg_content_1_640x140.png", 
        0, header_sp:getPositionY()-height, cc.size(640, height))
    :addTo(self.bg):align(display.BOTTOM_CENTER)



    self:addTouchAbleChild(self.bg)


    display.newSprite("move_alliance_bg.png")
    :addTo(self.bg):pos(0,-200)
    display.newSprite("move_alliance_bg.png")
    :addTo(self.bg):pos(0,-263)

    display.newSprite("icon_world_88x88.png")
    :addTo(self.bg):pos(-180, -200):scale(0.5)
    UIKit:ttfLabel({
        text = _("圈数"),
        size = 22,
        color = 0xffedae,
    }):addTo(self.bg):align(display.LEFT_CENTER, -150, -200)

    UIKit:ttfLabel({
        text = DataUtils:getMapRoundByMapIndex(toIndex),
        size = 22,
        color = 0xa1dd00,
    }):addTo(self.bg):align(display.CENTER, 170, -200)

    display.newSprite("buff_68x68.png")
    :addTo(self.bg):pos(-180, -263):scale(0.5)
    UIKit:ttfLabel({
        text = _("增益数量"),
        size = 22,
        color = 0xffedae,
    }):addTo(self.bg):align(display.LEFT_CENTER, -150, -263)

    UIKit:ttfLabel({
        text = DataUtils:getMapBuffNumByMapIndex(toIndex),
        size = 22,
        color = 0xa1dd00,
    }):addTo(self.bg):align(display.CENTER, 170, -263)

    UIKit:ttfLabel({
        text = _("联盟已经迁移"),
        size = 40,
        color = 0xf7f7f7,
        shadow = true,
    }):addTo(self.bg):align(display.CENTER, 0, -110)



    self:Play()
end
function GameUIMoveSuccess:onExit()
    app:EnterMyAllianceScene()
end
function GameUIMoveSuccess:Play()
    app:GetAudioManager():PlayeEffectSoundWithKey("USE_ITEM")
    self.bg:scale(0.3):show():stopAllActions()
    transition.scaleTo(self.bg, {
        scale = 1,
        time = 0.3,
        easing = "backout",
        onComplete = function()

        end,
    })
end

return GameUIMoveSuccess




