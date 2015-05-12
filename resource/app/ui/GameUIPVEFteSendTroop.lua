local GameUIPVEFteSendTroop = UIKit:createUIClass("GameUIPVEFteSendTroop", "GameUIPVESendTroop")



function GameUIPVEFteSendTroop:ctor(...)
	GameUIPVEFteSendTroop.super.ctor(self, ...)
    self.__type  = UIKit.UITYPE.BACKGROUND
end


-- fte
local promise = import("..utils.promise")
local WidgetFteArrow = import("..widget.WidgetFteArrow")
function GameUIPVEFteSendTroop:PormiseOfFte()
    return self:PromiseOfMax():next(function()
        return self:PromiseOfAttack()
    end)
end
function GameUIPVEFteSendTroop:PromiseOfMax()
    local r = self.max_btn:getCascadeBoundingBox()
    self:GetFteLayer():SetTouchObject(self.max_btn)

    WidgetFteArrow.new(_("点击最大")):addTo(self:GetFteLayer()):TurnLeft()
        :align(display.LEFT_CENTER, r.x + r.width, r.y + r.height/2)

    local p = promise.new()
    self.max_btn:onButtonClicked(function()
        self:GetFteLayer():removeFromParent()
        p:resolve()
    end)
    return p
end
function GameUIPVEFteSendTroop:PromiseOfAttack()
    local r = self.march_btn:getCascadeBoundingBox()
    self:GetFteLayer():SetTouchObject(self.march_btn)

    WidgetFteArrow.new(_("点击进攻")):addTo(self:GetFteLayer()):TurnRight()
    :align(display.RIGHT_CENTER, r.x - 20, r.y + r.height/2)

    return UIKit:PromiseOfOpen("GameUIReplayNew")
end

return GameUIPVEFteSendTroop
