--
-- Author: dannyhe
-- Date: 2014-08-05 17:34:54
--
local LogoScene = class("LogoScene", function()
    return display.newScene("LogoScene")
end)
function LogoScene:ctor()
    self:loadSplashResources()
end
function createSoldier(name, x, y, s)
    display.newSprite("tmp_shrine_open_icon_96x96.png"):addTo(display.getRunningScene()):pos(x, y)
    UIKit:CreateSoldierIdle45Ani(name):scale(s or 1):addTo(display.getRunningScene()):pos(x, y)
end
function LogoScene:onEnter()
    --关闭屏幕锁定定时器
    if ext.disableIdleTimer then
        ext.disableIdleTimer(true)
    end
    
    self.layer = cc.LayerColor:create(cc.c4b(255,255,255,255)):addTo(self)
    self.sprite = display.newSprite("batcat_logo_368x507.png", display.cx, display.cy):addTo(self.layer)
    self:performWithDelay(function() self:beginAnimate() end,0.5)
    -- createSoldier("ballista_3", display.cx, display.cy, 0.5)
    -- createSoldier("catapult_3", display.cx + 100, display.cy, 0.5)
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
    display.addImageAsync("splash_logo_516x92.png",function()
        display.addImageAsync("splash_beta_bg_3987x1136.jpg",function()end)
    end)
end

function LogoScene:onExit()
    cc.Director:getInstance():getTextureCache():removeTextureForKey("batcat_logo_368x507.png")
end

return LogoScene





