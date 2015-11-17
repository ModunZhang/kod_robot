local GameUINpc = import("app.ui.GameUINpc")
local utf8 = import("..utils.utf8")
local promise = import("..utils.promise")
local cocos_promise = import("..utils.cocos_promise")
local FteScene = class("FteScene", function()
    return display.newScene("FteScene")
end)

function FteScene:ctor()
end
function FteScene:onEnter()
    app:GetAudioManager():PlayGameMusicOnSceneEnter("MyCityScene",false)
end
function FteScene:onEnterTransitionFinish()
    display.newSprite("fte_background.jpg"):addTo(self):align(display.BOTTOM_CENTER, display.cx, 0)

    local emitter = cc.ParticleSystemQuad:create("particles/FireWall.plist"):addTo(self):pos(display.cx, 0)
    emitter:setPositionType(2)
    emitter:setPosVar(cc.p(display.width,0))
    for i = 1, 1000 do
        emitter:update(0.1)
    end



    printLog("Info", "Check MessageDialog :%s",self.__cname)
    local message = UIKit:getMessageDialogWillShow()
    if message then
        message:AddToScene(self,true)
        UIKit:clearMessageDialogWillShow()
    end

    local text = _("数周之后…")
    self.several = UIKit:ttfLabel({
        text = "",
        size = 30,
        color = 0xffedae,
    }):addTo(self):align(display.CENTER, display.cx, display.cy):hide()
    self.npc = UIKit:newGameUI('GameUINpc',
        {words = _("太好了，你终于醒过来了，觉醒者。。。我的名字叫赛琳娜，我们寻找那你这样的觉醒者已经很长时间了。。。"), brow = "smile"},
        {words = _("我建议你最好别乱动，你刚刚在同黑龙作战的过程中受了伤，伤口还没复原。。。")},
        {words = _("我知道你好友很多疑问，不过首先，我们需要前往寻找一个安全的地方？")}):AddToScene(self, true)

    self.npc:PromiseOfDialogEndWithClicked(3):next(function()
        return GameUINpc:PromiseOfLeave()
    end):next(function()
        return UIKit:newGameUI('GameUISelectTerrain'):AddToScene(self, true):PromiseOfSelectDragon()
    end):next(function()
        UIKit:GetUIInstance("GameUISelectTerrain"):removeFromParent()
        self.several:show()
    end):next(self:PormiseOfSchedule(1, function(percent)
        self.several:setString(utf8.substr(text, 1, math.ceil(utf8.len(text) * percent)))
    end)):next(cocos_promise.delay(1)):next(function()
        if GLOBAL_FTE then
            app:EnterMyCityFteScene()
        else
            app:EnterUserMode()
            app:EnterMyCityScene()
        end
    end)
    self.npc:StartDialog()
    self.npc.ui_map.background:hide()
end
function FteScene:PormiseOfSchedule(time, func)
    return function()
        return cocos_promise.promiseOfSchedule(self, time, 0.1, func)
    end
end


return FteScene



