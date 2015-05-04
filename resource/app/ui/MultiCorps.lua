local Corps = import(".Corps")
local cocos_promise = import("..utils.cocos_promise")
local WidgetDialog = import("..widget.WidgetDialog")
local BattleObject = import(".BattleObject")
local MultiCorps = class("MultiCorps", BattleObject)
function MultiCorps:ctor()
    MultiCorps.super.ctor(self)
    local corps = {}
	local corps1 = Corps.new("lancer", 4, 1, 50, 100):addTo(self):pos(100, 0)
    local corps2 = Corps.new("swordsman", 4, 2, 50, 100):addTo(self):pos(0, 0)
    local corps3 = Corps.new("ranger", 4, 2, 50, 100):addTo(self):pos(-100, 0)
    table.insert(corps, corps1)
    table.insert(corps, corps2)
    table.insert(corps, corps3)
    self.corps = corps
end
function MultiCorps:OnAnimationPlayEnd(ani_name, func)
    self.corps[1]:OnAnimationPlayEnd(ani_name, func)
end
function MultiCorps:PromiseOfSay(...)
    if self.dialog then
        self.dialog:removeFromParent()
        self.dialog = nil
    end
    local point = self:convertToWorldSpace(cc.p(0, 0))
    self.dialog = WidgetDialog.new(...):addTo(display.getRunningScene()):pos(point.x, point.y)
    self.dialog:StartDialog()
    return self.dialog:PromiseOfDialogEnded(#{...}):next(function()
            return self
        end)
end
function MultiCorps:PromiseOfShoutUp()
    if self.dialog then
        self.dialog:removeFromParent()
        self.dialog = nil
    end
    return cocos_promise.defer(function() return self end)
end
function MultiCorps:PlayAnimation(ani, loop_time)
    for _, v in pairs(self.corps) do
        v:PlayAnimation(ani, loop_time)
    end
end
function MultiCorps:Say(...)
    local args = {...}
    return function(object)
        return object:PromiseOfSay(unpack(args))
    end
end
function MultiCorps:ShoutUp()
    return function(object)
        return object:PromiseOfShoutUp()
    end
end
return MultiCorps







