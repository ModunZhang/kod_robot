local PVESceneNew = import(".PVESceneNew")
local PVESceneNewFte = class("PVESceneNewFte", PVESceneNew)

function PVESceneNewFte:ctor(...)
    PVESceneNewFte.super.ctor(self, ...)
end
function PVESceneNewFte:OpenUI(building)
    if self.pve_name == building:GetPveName() then
        UIKit:newGameUI("GameUIPveAttackFte", self.user, building:GetPveName()):AddToCurrentScene(true)
    end
end

--
local check = import("..fte.check")
local mockData = import("..fte.mockData")
local promise = import("..utils.promise")
local cocos_promise = import("..utils.cocos_promise")
local WidgetFteArrow = import("..widget.WidgetFteArrow")
local WidgetFteMark = import("..widget.WidgetFteMark")
local GameUINpc = import("..ui.GameUINpc")
function PVESceneNewFte:onEnterTransitionFinish()
    if GLOBAL_FTE then
    self:RunFte()
    end
end
function PVESceneNewFte:RunFte()
    self.touch_layer:removeFromParent()
    self:GetFteLayer():LockAll()
    local p = cocos_promise.defer()
    if not check("FightWithNpc1_1") then
        p:next(function()
            self:GetFteLayer():UnlockAll()
            return self:PromiseOfFindNpc1()
                :next(function(npc_ui)
                    return npc_ui:PormiseOfFte()
                end)
                :next(function()
                    return self:PromiseOfIntroduce()
                end):next(function()
                self:DestoryMark()
                return self:PromiseOfExit()
                end):next(function()
                return promise.new()
                end)
        end)
    end
    if not check("FightWithNpc1_2") then
        p:next(function()
            self:GetFteLayer():UnlockAll()
            return self:PromiseOfFindNpc2()
                :next(function(npc_ui)
                    return npc_ui:PormiseOfFte()
                end)
        end)
    end
    if not check("FightWithNpc1_3") then
        p:next(function()
            self:GetFteLayer():UnlockAll()
            return self:PromiseOfFindNpc3()
                :next(function(npc_ui)
                    return npc_ui:PormiseOfFte()
                end):next(function()
                    return self:PromiseOfIntroduce1()
                end):next(function()
                    return self:PromiseOfExit()
                end)
        end)
    end
end
function PVESceneNewFte:PromiseOfFindNpc1()
    self:GetFteLayer():Enable()
    local x,y = self:GetSceneLayer():GetNpcByIndex(1):getPosition()
    self.pve_name = self:GetSceneLayer():GetNpcByIndex(1):GetPveName()
    WidgetFteArrow.new(_("点击关卡")):addTo(self:GetSceneLayer():GetFteLayer())
        :TurnDown():align(display.BOTTOM_CENTER, x, y + 100)

    return UIKit:PromiseOfOpen("GameUIPveAttackFte"):next(function(ui)
        self:GetSceneLayer():GetFteLayer():removeAllChildren()
        return ui
    end)
end
function PVESceneNewFte:PromiseOfFindNpc2()
    self:GetFteLayer():Enable()
    local x,y = self:GetSceneLayer():GetNpcByIndex(2):getPosition()
    self.pve_name = self:GetSceneLayer():GetNpcByIndex(2):GetPveName()
    WidgetFteArrow.new(_("点击关卡")):addTo(self:GetSceneLayer():GetFteLayer())
        :TurnDown():align(display.BOTTOM_CENTER, x, y + 100)

    return UIKit:PromiseOfOpen("GameUIPveAttackFte"):next(function(ui)
        self:GetSceneLayer():GetFteLayer():removeAllChildren()
        return ui
    end)
end
function PVESceneNewFte:PromiseOfFindNpc3()
    self:GetFteLayer():Enable()
    local x,y = self:GetSceneLayer():GetNpcByIndex(3):getPosition()
    self.pve_name = self:GetSceneLayer():GetNpcByIndex(3):GetPveName()
    WidgetFteArrow.new(_("点击关卡")):addTo(self:GetSceneLayer():GetFteLayer())
        :TurnDown():align(display.BOTTOM_CENTER, x, y + 100)

    return UIKit:PromiseOfOpen("GameUIPveAttackFte"):next(function(ui)
        self:GetSceneLayer():GetFteLayer():removeAllChildren()
        return ui
    end)
end
function PVESceneNewFte:PromiseOfIntroduce()
    self:GetFteLayer():Enable()
    return GameUINpc:PromiseOfSay(
        {
            words = _("领主大人，探索会消耗体力值，但击败敌军可以获得资源和材料…"),
            npc = "man",
            callback = function(npc_ui)
                local r = self:GetHomePage().pve_back:getCascadeBoundingBox()
                npc_ui.ui_map.background:FocusOnRect(r)
                self:GetMark():Size(r.width, r.height):pos(r.x + r.width/2, r.y + r.height/2)
            end
        }
    ):next(function()
        self:GetFteLayer():Disable()
        return GameUINpc:PromiseOfLeave()
    end)
end
function PVESceneNewFte:PromiseOfIntroduce1()
    self:GetFteLayer():Enable()
    return GameUINpc:PromiseOfSay(
        {words = _("亡灵兵种属性极高而且没有维护费用,有了特殊材料,我们就可以招募他们了."), npc = "man"}
    ):next(function()
        return GameUINpc:PromiseOfLeave()
    end)
end
function PVESceneNewFte:PromiseOfExit()
    self:GetFteLayer():Reset()
    local r = self:GetHomePage().change_map:GetWorldRect()
    self:GetHomePage().change_map.btn:removeEventListenersByEvent("CLICKED_EVENT")
    self:GetHomePage().change_map.btn:onButtonClicked(function()
        app:EnterMyCityFteScene()
    end)
    self:GetHomePage():GetFteLayer():SetTouchRect(r)
    WidgetFteArrow.new(_("返回城市")):addTo(self:GetHomePage():GetFteLayer())
        :TurnDown(false):align(display.LEFT_BOTTOM, r.x + 20, r.y + r.width + 20)
end
function PVESceneNewFte:GetMark()
    if not self.mark then
        self.mark = WidgetFteMark.new():addTo(self):zorder(4000)
    end
    return self.mark
end
function PVESceneNewFte:DestoryMark()
    self.mark:removeFromParent()
    self.mark = nil
end

return PVESceneNewFte
























