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



    -- UILib.loadPveAnimation()
    -- self.box = ccs.Armature:create("lanse"):addTo(self)
    --     :align(display.CENTER, 0, display.height):scale(0.25)

    -- local mid = self.box:getParent():convertToNodeSpace(cc.p(display.cx - 50, display.cy))
    -- local time = 0.4
    -- local m = transition.create(cc.MoveTo:create(time, mid), {easing = "backOut"})
    -- local s = transition.create(cc.ScaleTo:create(time, 0.7), {easing = nil})
    -- self.box:runAction(transition.sequence{
    --     cc.Spawn:create(m, s),
    --     cc.CallFunc:create(function()
    --         self.box:getAnimation():playWithIndex(0, -1, 0)
    --     end),
    -- })

    -- local emitter = cc.ParticleSystemQuad:create("particles/Upsidedown.plist"):addTo(self)
    -- emitter:pos(display.cx,display.cy)




    -- display.newSprite("barracks.png"):addTo(self):pos(display.cx, display.cy)
    


    -- local emitter = cc.ParticleSystemQuad:createWithTotalParticles(2):addTo(self)
    --     emitter:setDuration(-1)
    --     emitter:setEmitterMode(0)
    --     emitter:setPositionType(2)
    --     emitter:setAngle(45)
    --     emitter:setPosVar(cc.p(0,0))
    --     emitter:setLife(3)
    --     emitter:setLifeVar(0)
    --     emitter:setStartSize(25)
    --     emitter:setEndSize(35)
    --     emitter:setGravity(cc.p(0,0))
    --     emitter:setSpeed(25)
    --     emitter:setSpeedVar(0)
    --     emitter:setStartColor(cc.c4f(1))
    --     emitter:setEndColor(cc.c4f(1,1,1,0))
    --     emitter:setEmissionRate(1)
    --     emitter:setBlendAdditive(false)
    --     emitter:setTexture(cc.Director:getInstance():getTextureCache():addImage("z.png"))
    --     emitter:updateWithNoTime()
    --     emitter:pos(display.cx + 50,display.cy + 50)


    -- display.newSprite("my_keep_1.png"):addTo(self):pos(display.cx, display.cy)


    -- local emitter = cc.ParticleSun:createWithTotalParticles(50)
    -- emitter:setPosVar(cc.p(30,0))
    -- emitter:setSpeed(60)
    -- emitter:setStartSize(70)
    -- emitter:setAngleVar(0)
    -- emitter:setEmissionRate(emitter:getTotalParticles()/emitter:getLife())
    -- emitter:setTexture(cc.Director:getInstance():getTextureCache():addImage("fire.png"))
    -- emitter:addTo(self):pos(display.cx, display.cy-30)

    
    -- local emitter = cc.ParticleFire:createWithTotalParticles(20)
    -- emitter:setPosVar(cc.p(30,0))
    -- emitter:setLife(1)
    -- emitter:setLifeVar(0.5)
    -- emitter:setStartSize(70)
    -- emitter:setStartSizeVar(10)
    -- emitter:setSpeed(50)
    -- emitter:setSpeedVar(50)
    -- emitter:setEmissionRate(emitter:getTotalParticles()/emitter:getLife())
    -- emitter:setTexture(cc.Director:getInstance():getTextureCache():addImage("fire.png"))
    -- emitter:addTo(self):pos(display.cx, display.cy-30)

    







    -- local emitter = cc.ParticleSnow:createWithTotalParticles(100):addTo(self)
    -- local pos_x, pos_y = emitter:getPosition()
    -- emitter:setPosition(pos_x, pos_y - 110)
    -- emitter:setLife(3)
    -- emitter:setLifeVar(1)

    -- -- gravity
    -- emitter:setGravity(cc.p(0, -10))

    -- -- speed of particles
    -- emitter:setSpeed(130)
    -- emitter:setSpeedVar(30)

    -- local startColor = emitter:getStartColor()
    -- startColor.r = 0.9
    -- startColor.g = 0.9
    -- startColor.b = 0.9
    -- emitter:setStartColor(startColor)

    -- local startColorVar = emitter:getStartColorVar()
    -- startColorVar.b = 0.1
    -- emitter:setStartColorVar(startColorVar)

    -- emitter:setEmissionRate(emitter:getTotalParticles() / emitter:getLife())

    -- emitter:setTexture(cc.Director:getInstance():getTextureCache():addImage("+.png"))





    -- local emitter = cc.ParticleFire:createWithTotalParticles(10):addTo(self)
    -- emitter:setTexture(cc.Director:getInstance():getTextureCache():addImage("+.png"))
    -- emitter:pos(display.cx,display.cy)
    -- emitter:setPositionType(2)
    -- emitter:setEmissionRate(3)


    -- WidgetFteMark.new():Size(100, 200):addTo(self):pos(display.cx, display.cy)

    -- GameUINpc:PromiseOfSay({words = _("领主大人，光靠城市基本的资源产出，无法满足我们的发展需求。。。"), npc = "man"},
    --         {words = _("我倒是知道一个地方，有些危险，但有着丰富的物资，也许我们尝试着探索。。。"), npc = "man"})

    -- GameUINpc:PromiseOfSay(
    --     {words = _("太好了, 你终于醒过来了, 觉醒者...我的名字叫赛琳娜，我们寻找那你这样的觉醒者已经很长时间了..."), brow = "smile", npc = "man"},
    --     {words = "我建议你最好别乱动, 你刚刚在同黑龙作战的过程中受了伤, 伤口还没复原..."},
    --     {words = "我知道你好友很多疑问, 不过首先, 我们需要前往寻找一个安全的地方?", npc = "man"})

    -- GameUINpc:PromiseOfSay({words = "太好了，你终于醒过来了，觉醒者。。。我的名字叫赛琳娜，我们寻找那你这样的觉醒者已经很长时间了。。。,太好了，你终于醒过来了，觉醒者。。。我的名字叫赛琳娜，我们寻找那你这样的觉醒者已经很长时间了。。。"})
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

    -- UIKit:newGameUI("GameUIPveGetRewards", 0, display.height):AddToCurrentScene(true)
    -- :AddClickOutFunc(function(ui)
    --     ui:LeftButtonClicked()
    -- end)
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
    display.addImageAsync("splash_logo_515x92.png",function()
        display.addImageAsync("splash_beta_bg_3987x1136.jpg",function()end)
    end)
end



function LogoScene:onExit()
    cc.Director:getInstance():getTextureCache():removeTextureForKey("batcat_logo_368x390.png")
end

return LogoScene







