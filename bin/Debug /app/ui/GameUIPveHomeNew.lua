local Localize_pve = import("..utils.Localize_pve")
local light_gem = import("..particles.light_gem")
local ChatManager = import("..entity.ChatManager")
local UILib = import("..ui.UILib")
local window = import("..utils.window")
local WidgetChat = import("..widget.WidgetChat")
local WidgetUseItems = import("..widget.WidgetUseItems")
local WidgetChangeMap = import("..widget.WidgetChangeMap")
local WidgetHomeBottom = import("..widget.WidgetHomeBottom")
local GameUIPveHomeNew = UIKit:createUIClass('GameUIPveHomeNew')
local stages = GameDatas.PvE.stages
local timer = app.timer
function GameUIPveHomeNew:DisplayOn()
    self.visible_count = self.visible_count + 1
    self:FadeToSelf(self.visible_count > 0)
end
function GameUIPveHomeNew:DisplayOff()
    self.visible_count = self.visible_count - 1
    self:FadeToSelf(self.visible_count > 0)
end
function GameUIPveHomeNew:FadeToSelf(isFullDisplay)
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


function GameUIPveHomeNew:ctor(level)
    GameUIPveHomeNew.super.ctor(self, {type = UIKit.UITYPE.BACKGROUND})
    self.level = level
end
function GameUIPveHomeNew:onEnter()
    self.visible_count = 1
    self:CreateTop()
    self.bottom = self:CreateBottom()
    display.newNode():addTo(self):schedule(function()
        local star = User:GetStageStarByIndex(self.level)
        self.stars:setString(string.format("%d/%d", star, User:GetStageTotalStars()))
        self.strenth_current:setString(User:GetResValueByType("stamina"))
        self.gem_label:setString(string.formatnumberthousands(User:GetGemValue()))

        local index = 1
        local stage_name = self.level.."_"..index
        while stages[stage_name] do
            local stage = stages[stage_name]
            if star >= tonumber(stage.needStar) and not User:IsStageRewardedByName(stage_name) then
                self:TipsOnReward()
                return
            end
            index = index + 1
            stage_name = self.level.."_"..index
        end
        self:TipsOnReward(false)
    end, 1)
end
function GameUIPveHomeNew:CreateTop()
    local top_bg = display.newSprite("head_bg.png")
        :align(display.TOP_CENTER, window.cx, window.top)
        :addTo(self)
    local size = top_bg:getContentSize()
    top_bg:setTouchEnabled(true)

    local btn = cc.ui.UIPushButton.new({normal = "pve_btn_up_60x48.png",
        pressed = "pve_btn_down_60x48.png"}):addTo(top_bg)
        :pos(88, size.height/2 + 10)
        :onButtonClicked(function()
            UIKit:newGameUI("GameUIPveSelect", self.level):AddToCurrentScene(true)
        end)
    display.newSprite("coordinate_128x128.png"):addTo(btn):scale(0.4)
     
    UIKit:ttfLabel({
        text = string.format(_("第%d章"), self.level),
        size = 22,
        color = 0xffedae,
    }):addTo(top_bg):align(display.LEFT_CENTER, 130, size.height/2 + 10)

    local star = display.newSprite("tmp_pve_star_bg.png"):addTo(top_bg):pos(size.width - 210, 55):scale(0.6)
                 display.newSprite("tmp_pve_star.png"):addTo(star):pos(32,32)

    self.stars = UIKit:ttfLabel({
        text = string.format("%d/%d", User:GetStageStarByIndex(self.level), User:GetStageTotalStars()),
        size = 20,
        color = 0xffedae,
        shadow = true,
    }):addTo(top_bg):align(display.LEFT_CENTER, size.width - 210 + 25, 55)



    local reward_btn = cc.ui.UIPushButton.new(
        {normal = "back_ground_box.png", pressed = "back_ground_box.png"}
        ,{})
        :addTo(top_bg, 1):align(display.CENTER, size.width - 80, 55):scale(0.8)
        :onButtonClicked(function(event)
            UIKit:newGameUI("GameUIPveReward", self.level):AddToCurrentScene(true)
        end)

    self.reward_icon = display.newSprite("bottom_icon_package_66x66.png"):addTo(reward_btn):scale(1.3)

    local button = cc.ui.UIPushButton.new(
        {normal = "gem_btn_up_196x68.png", pressed = "gem_btn_down_196x68.png"},
        {scale9 = false}
    ):onButtonClicked(function(event)
        UIKit:newGameUI("GameUIStore"):AddToCurrentScene(true)
    end):addTo(top_bg):pos(top_bg:getContentSize().width - 130, -20)
    local gem_icon = display.newSprite("gem_icon_62x61.png"):addTo(button):pos(60, 3)
    light_gem():addTo(gem_icon, 1022):pos(62/2, 61/2)

    self.gem_label = UIKit:ttfLabel({
        text = string.formatnumberthousands(City:GetUser():GetGemValue()),
        size = 20,
        color = 0xffd200,
    }):addTo(button):align(display.CENTER, -30, 8)


    local pve_back = display.newSprite("back_ground_pve.png"):addTo(top_bg)
        :align(display.LEFT_TOP, 40, 16):flipX(true)
    local size = pve_back:getContentSize()
    self.pve_back = pve_back
    self.strenth_icon = display.newSprite("dragon_lv_icon.png"):addTo(pve_back):pos(size.width - 20, 25)
    local add_btn = cc.ui.UIPushButton.new(
        {normal = "add_btn_up.png",pressed = "add_btn_down.png"}
        ,{})
        :addTo(pve_back):align(display.CENTER, 25, 25)
        :onButtonClicked(function ( event )
            WidgetUseItems.new():Create({
                item_name = "stamina_1"
            }):AddToCurrentScene()
        end)
    display.newSprite("+.png"):addTo(add_btn)

    self.strenth_current = UIKit:ttfLabel({
        text = User:GetResValueByType("stamina"),
        size = 20,
        color = 0xffedae,
        shadow = true,
    }):addTo(pve_back):align(display.RIGHT_CENTER, size.width / 2, 25)

    
    UIKit:ttfLabel({
        text = string.format("/%d", User:GetResProduction("stamina").limit),
        size = 20,
        color = 0xffedae,
        shadow = true,
    }):addTo(pve_back):align(display.LEFT_CENTER, size.width / 2, 25)
end
function GameUIPveHomeNew:CreateBottom()
    local bottom_bg = WidgetHomeBottom.new(City):addTo(self)
        :align(display.BOTTOM_CENTER, display.cx, display.bottom)

    self.chat = WidgetChat.new():addTo(bottom_bg)
        :align(display.CENTER, bottom_bg:getContentSize().width/2, bottom_bg:getContentSize().height-11)

    self.change_map = WidgetChangeMap.new(WidgetChangeMap.MAP_TYPE.PVE):addTo(self)

    return bottom_bg
end
function GameUIPveHomeNew:ChangeChatChannel(channel_index)
    self.chat:ChangeChannel(channel_index)
end
function GameUIPveHomeNew:TipsOnReward(enable)
    if enable == false then self.reward_icon:stopAllActions(); return end
    if self.reward_icon:getNumberOfRunningActions() > 0 then return end
    self.reward_icon:runAction(UIKit:ShakeAction(true,2))
end


return GameUIPveHomeNew













