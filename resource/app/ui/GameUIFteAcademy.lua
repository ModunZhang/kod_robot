local GameUIFteAcademy = UIKit:createUIClass('GameUIFteAcademy',"GameUIAcademy")


function GameUIFteAcademy:ctor(...)
    GameUIFteAcademy.super.ctor(self, ...)
    self.__type  = UIKit.UITYPE.BACKGROUND
end

--fte
local promise = import("..utils.promise")
local WidgetFteArrow = import("..widget.WidgetFteArrow")
function GameUIFteAcademy:Find()
    return self:GetItemByTag(self:GetTech().index)
end
function GameUIFteAcademy:PromiseOfFte()
    self.scrollView:getScrollNode():setTouchEnabled(false)
    self.scrollView.touchNode_:setTouchEnabled(false)
    self:Find():setTouchSwallowEnabled(true)

    self:GetFteLayer():SetTouchObject(self:Find())
    local r = self:Find():getCascadeBoundingBox()
    local arrow = WidgetFteArrow.new(_("查看详情")):addTo(self:GetFteLayer())
        :TurnRight():align(display.RIGHT_CENTER, r.x - 10, r.y + r.height/2)

    local p = promise.new()
    self:Find():removeEventListenersByEvent("CLICKED_EVENT")
    self:Find():onButtonClicked(function()
        arrow:removeFromParent()
        self:Find():setButtonEnabled(false)
        local techui = UIKit:newGameUI("GameUIFteUpgradeTechnology", self:GetTech()):AddToCurrentScene(true)
        techui.__type  = UIKit.UITYPE.BACKGROUND
        techui:PromiseOfFte(p)
    end)
    return p
end
function GameUIFteAcademy:GetTech()
    local t
    for tech_name,tech in pairs(self.city:GetUser().productionTechs) do
        if tech_name == "forestation" then
            t = tech
        end
    end
    return t
end


return GameUIFteAcademy




