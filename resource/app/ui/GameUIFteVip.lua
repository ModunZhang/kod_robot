local GameUIFteVip = UIKit:createUIClass('GameUIFteVip',"GameUIVip")



function GameUIFteVip:ctor(...)
	GameUIFteVip.super.ctor(self, ...)
	self.__type  = UIKit.UITYPE.BACKGROUND
end



-- fte
local WidgetFteArrow = import("..widget.WidgetFteArrow")
local WidgetFteMark = import("..widget.WidgetFteMark")
function GameUIFteVip:FindActiveBtn()
    return self.active_button
end
function GameUIFteVip:PromiseOfFte()
    self:GetFteLayer():SetTouchObject(self:FindActiveBtn())
    local r = self:FindActiveBtn():getCascadeBoundingBox()
    WidgetFteArrow.new(_("激活VIP")):addTo(self:GetFteLayer())
    :TurnUp():align(display.TOP_CENTER, r.x + r.width/2, r.y - 20)

    return WidgetUseItems:PromiseOfOpen("vipActive"):next(function(ui)
        self:GetFteLayer():removeFromParent()
        return ui:PromiseOfFte()
    end):next(function()
        return self:PromsieOfExit("GameUIFteVip")
    end)
end


return GameUIFteVip