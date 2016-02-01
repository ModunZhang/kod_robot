local UILib = import(".UILib")
local GameUILevelUp = UIKit:createUIClass("GameUILevelUp", "UIAutoClose")
local playerLevel = GameDatas.PlayerInitData.playerLevel

function GameUILevelUp:ctor(cur_level, next_level)
    GameUILevelUp.super.ctor(self)
    self.cur_level = cur_level + 1
    self.next_level = next_level
    assert(self.cur_level)
    assert(self.next_level)
    self:AddClickOutFunc(handler(self, self.HandleNext))

    self.bg = cc.ui.UIPushButton.new({normal = "player_levelup_bg.png"}, nil, {})
        :align(display.CENTER, display.cx, display.cy)
        :onButtonClicked(handler(self, self.HandleNext))
    local size = self.bg:getCascadeBoundingBox()
    self:addTouchAbleChild(self.bg)
    UIKit:ttfLabel({
        text = _("恭喜你达到"),
        size = 18,
        color = 0x00fff5
    }):addTo(self.bg):align(display.CENTER, 0, size.height/2 - 55)

    self.level = UIKit:ttfLabel({
        text = string.format(_("等级 %d"), self.cur_level),
        size = 57,
        color = 0xf7f7f7
    }):addTo(self.bg):align(display.CENTER, 0, size.height/2 - 100)
    self:Play(self.cur_level)
end
function GameUILevelUp:HandleNext()
    self.cur_level = self.cur_level + 1
    if self.cur_level > self.next_level then
        self:LeftButtonClicked()
    else
        self:Play(self.cur_level)
    end
end
local scale_map = {
    wood = 0.5,
    stone = 0.5,
    iron = 0.5,
    food = 0.5,
    coin = 0.5,
    gem = 0.8,
}
function GameUILevelUp:Play(level)
    app:GetAudioManager():PlayeEffectSoundWithKey("HOORAY")
    self.bg:scale(1):hide()
    local size = self.bg:getCascadeBoundingBox()
    self.level:setString(string.format(_("等级 %d"), level))
    for k,v in pairs(self.rewards_map or {}) do
        v.icon:removeFromParent()
        v.label:removeFromParent()
    end
    self.rewards_map = {}
    local rewards_array = LuaUtils:table_map(string.split(playerLevel[level].rewards, ","), function(k,v)
        local type_, name, count = unpack(string.split(v, ":"))
        return k,{type = type_, name = name, count = tonumber(count)}
    end)
    self.rewards_map = {}
    local rewards = {
        {
            1,2,3,
        },
        {
            1,2,3,
        }
    }
    local index = 1
    local start_x, start_y, w, h = -size.width/2 + 80, -size.height/2 + 130, 150, 60
    for row,rows in ipairs(rewards) do
        for col,_ in ipairs(rows) do
            local x,y = start_x + (col-1) * w, start_y + (row-1) * h

            local item = rewards_array[index]

            self.rewards_map[item.name] = self.rewards_map[item.name] or {}

            self.rewards_map[item.name].icon = display.newSprite(UILib.resource[item.name])
                :addTo(self.bg):scale(scale_map[item.name])
                :align(display.LEFT_CENTER, x, y)

            self.rewards_map[item.name].label = UIKit:ttfLabel({
                text = GameUtils:formatNumber(item.count),
                size = 16,
                color = 0xffedae
            }):addTo(self.bg):align(display.LEFT_CENTER, x + 50, y)

            index = index + 1
        end
    end

    self.bg:stopAllActions()
    self.bg:scale(0.3):show()
    transition.scaleTo(self.bg, {
        scale = 1,
        time = 0.3,
        easing = "backout",
        onComplete = function()

        end,
    })
end

return GameUILevelUp




