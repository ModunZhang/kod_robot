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
	app:GetAudioManager():PlayGameMusic("MainScene")
	self.bottom_layer = self:CreateOneLayer():addTo(self,GLOBAL_ZORDER.BOTTOM)
	self.ui_layer = self:CreateOneLayer():addTo(self,GLOBAL_ZORDER.UI)
	display.newSprite("splash_beta_logo_467x113.png")
		:align(display.TOP_CENTER, display.cx, display.top - 80)
		:addTo(self.ui_layer)
	self:CreateBottomAnimate()
end

function GameUISplashBeta:CreateBottomAnimate()
	local sp = self:CreateBgSprite():align(display.LEFT_BOTTOM, 0, 0):addTo(self.bottom_layer)
	local fist_x = -(sp:getCascadeBoundingBox().width - display.width)
	local speed = math.abs(fist_x/SPEED_TIME)
	self.bg_sprite_speed =  speed
	local sequence = transition.sequence({
        cc.MoveTo:create(SPEED_TIME, cc.p(fist_x, 0)),
        cc.CallFunc:create(handler(self, self.OnBgSpriteStop)),
        cc.MoveBy:create(display.width/speed, cc.p(-display.width, 0)),
        cc.CallFunc:create(function()
            sp:removeFromParent()
        end),
    })
    sp:runAction(sequence)
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