--
-- Author: dannyhe
-- Date: 2014-08-05 17:34:54
--
require("app.ui.GameGlobalUIUtils")
local UILib = import("app.ui.UILib")
local GameUINpc = import("app.ui.GameUINpc")
local WidgetFteArrow = import("app.widget.WidgetFteArrow")
local WidgetFteMark = import("app.widget.WidgetFteMark")
local WidgetDirectionSelect = import("app.widget.WidgetDirectionSelect")
local LogoScene = class("LogoScene", function()
    return display.newScene("LogoScene")
end)
function LogoScene:ctor()
    self:loadSplashResources()
end

function LogoScene:onEnter()
    self.layer = cc.LayerColor:create(cc.c4b(255,255,255,255)):addTo(self)
    self.sprite = display.newScale9Sprite("batcat_logo_368x390.png", display.cx, display.cy):addTo(self.layer)
    self:performWithDelay(function() self:beginAnimate() end,0.5)
    -- WidgetFteMark.new():Size(100, 200):addTo(self):pos(display.cx, display.cy)

    -- GameUINpc:PromiseOfSay({words = _("领主大人，光靠城市基本的资源产出，无法满足我们的发展需求。。。"), npc = "man"},
    --         {words = _("我倒是知道一个地方，有些危险，但有着丰富的物资，也许我们尝试着探索。。。"), npc = "man"})

    -- GameUINpc:PromiseOfSay(
    --     {words = _("太好了, 你终于醒过来了, 觉醒者...我的名字叫赛琳娜，我们寻找那你这样的觉醒者已经很长时间了..."), brow = "smile", npc = "man"},
    --     {words = "我建议你最好别乱动, 你刚刚在同黑龙作战的过程中受了伤, 伤口还没复原..."},
    --     {words = "我知道你好友很多疑问, 不过首先, 我们需要前往寻找一个安全的地方?", npc = "man"})

    -- GameUINpc:PromiseOfSayImportant({words = "太好了，你终于醒过来了，觉醒者。。。我的名字叫赛琳娜，我们寻找那你这样的觉醒者已经很长时间了。。。,太好了，你终于醒过来了，觉醒者。。。我的名字叫赛琳娜，我们寻找那你这样的觉醒者已经很长时间了。。。"})
    -- :next(function()
    --     return GameUINpc:PromiseOfLeave()
    -- end):next(function()
    --     print("hello")
    -- end)

    -- WidgetFteArrow.new("点击建筑: 龙巢")
    -- WidgetFteArrow.new("点击设置: 巨龙在城市驻防, 如果敌军入侵, 巨龙会自动带领士兵进行防御")
    -- :addTo(self):align(display.CENTER, display.cx, display.cy)
    -- -- :TurnLeft()
    -- -- :TurnRight()
    -- -- :TurnDown()
    -- :TurnUp(-150)

    -- WidgetFteArrow.new(_("建造住宅, 提升城民上限"))
    --     :addTo(self)
    --     :align(display.LEFT_CENTER, display.cx, display.cy)
    --     :TurnUp()


    --     WidgetDirectionSelect.new():addTo(self)
    --     :pos(display.cx, display.cy):EnableDirection(true, false, true)


    -- UIKit:newGameUI("GameUIReplayNew"):AddToCurrentScene(true)
end

function LogoScene:beginAnimate()
    local action = cc.Spawn:create({cc.ScaleTo:create(checknumber(2),1.5),cca.fadeTo(1.5,255/2)})
    self.sprite:runAction(action)
    local sequence = transition.sequence({
        cc.FadeOut:create(1),
        cc.CallFunc:create(function()
            self:performWithDelay(function()
                self.sprite:removeFromParent(true)
                app:enterScene("MainScene")
            end, 0.5)
        end),
    })
    self.layer:runAction(sequence)
end
--预先加载登录界面使用的大图
function LogoScene:loadSplashResources()
    --加载splash界面使用的图片
    display.addImageAsync("splash_beta_logo_467x113.png",function()
        display.addImageAsync("splash_beta_bg_3987x1136.jpg",function()end)
    end)
end



function LogoScene:onExit()
    cc.Director:getInstance():getTextureCache():removeTextureForKey("batcat_logo_368x390.png")
end

return LogoScene






