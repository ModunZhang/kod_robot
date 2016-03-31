local GameUIDragonEyrieDetailFte = UIKit:createUIClass("GameUIDragonEyrieDetailFte", "GameUIDragonEyrieDetail")


function GameUIDragonEyrieDetailFte:ctor(...)
    GameUIDragonEyrieDetailFte.super.ctor(self,...)
    self.__type  = UIKit.UITYPE.BACKGROUND
end
function GameUIDragonEyrieDetailFte:BuildUI()
    self.tab_buttons:SelectButtonByTag("skill")
end

-- fte
local check = import("..fte.check")
local mockData = import("..fte.mockData")
local DiffFunction = import("..utils.DiffFunction")
local promise = import("..utils.promise")
local cocos_promise = import("..utils.cocos_promise")
local WidgetFteArrow = import("..widget.WidgetFteArrow")
function GameUIDragonEyrieDetailFte:FindSkillBtn()
    return self.firstSkillBtn
end
function GameUIDragonEyrieDetailFte:PromiseOfFte()
    return self:PromiseOfLearnSkill()
end
function GameUIDragonEyrieDetailFte:PromiseOfLearnSkill()
    local p = promise.new()
    local r = self:FindSkillBtn():getCascadeBoundingBox()
    self:GetFteLayer():SetTouchObject(self:FindSkillBtn())
    WidgetFteArrow.new(_("点击技能")):addTo(self:GetFteLayer())
    :TurnLeft():align(display.LEFT_CENTER, r.x + r.width + 10, r.y + r.height/2)

    self:FindSkillBtn():removeEventListenersByEvent("CLICKED_EVENT")
    self:FindSkillBtn():onButtonClicked(function()
        UIKit:PromiseOfOpen("GameUIDragonSkillFte"):next(function(ui)
            ui:PromiseOfFte():next(function()
                self:LeftButtonClicked()
                p:resolve()
            end)
        end)
        UIKit:newGameUI("GameUIDragonSkillFte",self.building,self.firstSkillData):AddToCurrentScene(true)
    end)
    return p
end


return GameUIDragonEyrieDetailFte
