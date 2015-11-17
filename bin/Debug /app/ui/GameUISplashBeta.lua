--
-- Author: Danny He
-- Date: 2015-04-02 17:56:17
--
local GameUISplashBeta = UIKit:createUIClass('GameUISplashBeta')
local GLOBAL_ZORDER = {
    BOTTOM = 0,
    UI     = 2,
}

local MaxZorder = 10000
local SPEED_TIME = 50
function GameUISplashBeta:ctor()
    GameUISplashBeta.super.ctor(self,{type = UIKit.UITYPE.BACKGROUND})
end

function GameUISplashBeta:onEnter()
    GameUISplashBeta.super.onEnter(self)
    app:GetAudioManager():PlayGameMusicOnSceneEnter("MainScene",true)
    self.bottom_layer = self:CreateOneLayer():addTo(self,GLOBAL_ZORDER.BOTTOM)
    self.ui_layer = self:CreateOneLayer():addTo(self,GLOBAL_ZORDER.UI)
    self.logo = display.newSprite("splash_logo_515x92.png")
        :align(display.TOP_CENTER, display.cx, display.top - 100)
        :addTo(self.ui_layer)
    self:CreateBottomAnimate()
end
-- 仅仅显示背景图
function GameUISplashBeta:CreateNormalBg()
    local sp = self:CreateBgSprite():align(display.LEFT_BOTTOM, 0, 0):addTo(self.bottom_layer)
end

function GameUISplashBeta:CreateBottomAnimate()
    self.sprite = self:CreateBgSprite():align(display.LEFT_BOTTOM, 0, 0):addTo(self.bottom_layer)
    if app:GetGameDefautlt():IsPassedSplash() then
    	self:RunNormal()
    end
end
function GameUISplashBeta:RunNormal()
	local fist_x = -(self.sprite:getCascadeBoundingBox().width - display.width)
	local speed = math.abs(fist_x/SPEED_TIME)
	self.bg_sprite_speed =  speed
	local sequence = transition.sequence({
        cc.MoveTo:create(SPEED_TIME, cc.p(fist_x, 0)),
        cc.CallFunc:create(handler(self, self.OnBgSpriteStop)),
        cc.MoveBy:create(display.width/speed, cc.p(-display.width, 0)),
        cc.CallFunc:create(function()
            self.sprite :removeFromParent()
        end),
    })
    self.sprite:runAction(sequence)
end
function GameUISplashBeta:RunFte(func)
    self.label = UIKit:ttfLabel({
        size = 22,
        color = 0x265158,
        align = cc.ui.TEXT_ALIGN_CENTER,
        dimensions = cc.size(display.width, 0),
    }):addTo(self.bottom_layer,1):opacity(0)
        :align(display.CENTER, display.cx, display.height - 120)

	local is_skip = false
 --    local skip = cc.ui.UIPushButton.new({normal = "skip.png",pressed = "skip.png"})
	-- :addTo(self.bottom_layer, 1000000):scale(0.8)
	-- :align(display.RIGHT_TOP, display.width, display.height)
	-- :onButtonClicked(function(event)
 --        event.target:setButtonEnabled(false)
 --        if type(func) == "function" then
 --        	is_skip = true
 --        	func()
 --        end
 --    end):hide()
    display.newNode():addTo(self):runAction(transition.sequence{
        cc.CallFunc:create(function() self.logo:fadeOut(1) end),
        cc.DelayTime:create(1),
        cc.DelayTime:create(1),

        cc.CallFunc:create(function()
            self.label:setString(_("很久很久以前，一位英勇的国王统一了大陆\n从此人类迎来百年的和平..."))
            self.label:fadeIn(1)
        end),
        cc.DelayTime:create(1),
        cc.DelayTime:create(0.7),
        cc.CallFunc:create(function()
        	local fist_x = -(self.sprite:getCascadeBoundingBox().width - display.width)
    		local speed = math.abs(fist_x/SPEED_TIME)
    		self.bg_sprite_speed =  speed
            self.sprite:runAction(transition.sequence({
                cc.MoveTo:create(SPEED_TIME, cc.p(fist_x, 0)),
            }))
            -- skip:opacity(0):show():fadeIn(0.5)
        end),
        cc.DelayTime:create(3),
        cc.CallFunc:create(function() self.label:fadeOut(1) end),
        cc.DelayTime:create(1),

        cc.DelayTime:create(2),

        cc.CallFunc:create(function()
            self.label:setString(_("直到某一天，王国遭到了邪恶的黑龙的突然袭击\n它横行肆虐，吞噬人类..."))
            self.label:fadeIn(1)
        end),
        cc.DelayTime:create(1),
        cc.DelayTime:create(8),
        cc.CallFunc:create(function() self.label:fadeOut(1) end),
        cc.DelayTime:create(1),

        cc.DelayTime:create(2.5),

        cc.CallFunc:create(function()
            self.label:setString(_("人类组织起联军，誓要将黑龙彻底消灭\n但一番激战后，联军却几乎全军覆灭..."))
            self.label:fadeIn(1)
        end),
        cc.DelayTime:create(1),
        cc.DelayTime:create(9),
        cc.CallFunc:create(function() self.label:fadeOut(1) end),
        cc.DelayTime:create(1),

        cc.DelayTime:create(3),

        cc.CallFunc:create(function()
            self.label:setString(_("然而，有一位勇士却被黑龙神秘的选中\n他的心脏被黑龙夺走，却得以重生..."))
            self.label:fadeIn(1)
        end),
        cc.DelayTime:create(1),
        cc.DelayTime:create(6),
        cc.CallFunc:create(function() self.label:fadeOut(1) end),
        cc.DelayTime:create(1),

        cc.DelayTime:create(4.5),

        cc.CallFunc:create(function()
            self.label:setString(_("复活后的勇士发现自己竟然能够听懂龙语\n现在，人类的命运都背负在他的身上..."))
            self.label:fadeIn(1)
        end),
        cc.DelayTime:create(1),
        cc.DelayTime:create(7),
        cc.CallFunc:create(function()
        	if type(func) == "function" and not is_skip then
                func()
            end
        end),
        cc.CallFunc:create(function() self.label:fadeOut(1) end),
        cc.DelayTime:create(1),
    })
end

function GameUISplashBeta:OnBgSpriteStop()
    local sp2 = self:CreateBgSprite():align(display.LEFT_BOTTOM, display.width - 4, 0)
        :addTo(self.bottom_layer,self:GetMaxZorder())
    local x = -(sp2:getCascadeBoundingBox().width - display.width)
    local sequence = transition.sequence({
        cc.MoveTo:create(math.abs((x - display.width + 4) /self.bg_sprite_speed), cc.p(x, 0)),
        cc.CallFunc:create(handler(self, self.OnBgSpriteStop)),
        cc.MoveBy:create(display.width/self.bg_sprite_speed, cc.p(-display.width, 0)),
        cc.CallFunc:create(function()
            sp2:removeFromParent()
        end),
    })
    sp2:runAction(sequence)
end

function GameUISplashBeta:GetUILayer()
    return self.ui_layer
end

function GameUISplashBeta:CreateBgSprite()
    local sp = display.newSprite("splash_beta_bg_3987x1136.jpg")
    sp:scale(display.height/1136)
    return sp
end

function GameUISplashBeta:CreateOneLayer()
    local layer = display.newLayer()
    return layer
end

function GameUISplashBeta:GetMaxZorder()
    local ret = MaxZorder
    MaxZorder = MaxZorder - 1
    return ret
end

return GameUISplashBeta


