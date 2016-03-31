local GameUIDragonSkillFte = UIKit:createUIClass("GameUIDragonSkillFte", "GameUIDragonSkill")


function GameUIDragonSkillFte:ctor(...)
    GameUIDragonSkillFte.super.ctor(self,...)
    self.__type  = UIKit.UITYPE.BACKGROUND
end

-- fte
local check = import("..fte.check")
local mockData = import("..fte.mockData")
local DiffFunction = import("..utils.DiffFunction")
local promise = import("..utils.promise")
local cocos_promise = import("..utils.cocos_promise")
local WidgetFteArrow = import("..widget.WidgetFteArrow")
function GameUIDragonSkillFte:FindLearnBtn()
    return self.upgradeButton
end
function GameUIDragonSkillFte:PromiseOfFte()
    local p = promise.new()
    local r = self:FindLearnBtn():getCascadeBoundingBox()
    self:GetFteLayer():SetTouchObject(self:FindLearnBtn())
    WidgetFteArrow.new(_("点击学习")):addTo(self:GetFteLayer())
    :TurnDown():align(display.BOTTOM_CENTER, r.x + r.width/2, r.y + r.height + 10)

    self:FindLearnBtn():removeEventListenersByEvent("CLICKED_EVENT")
    self:FindLearnBtn():onButtonClicked(function()
        self:LeftButtonClicked()
        p:resolve()
    end)

    return p
end



return GameUIDragonSkillFte
