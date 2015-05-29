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

    WidgetFteArrow.new(_("点击最大")):addTo(self:GetFteLayer())
    :TurnDown():align(display.CENTER_BOTTOM, r.x + r.width/2, r.y + 70)

    local p = promise.new()
    self.max_btn:onButtonClicked(function()
        self.max_btn:setButtonEnabled(false)
        self:GetFteLayer():removeFromParent()
        p:resolve()
    end)
    return p
end
function GameUIPVEFteSendTroop:PromiseOfAttack()
    local r = self.march_btn:getCascadeBoundingBox()
    self:GetFteLayer():SetTouchObject(self.march_btn)

    WidgetFteArrow.new(_("点击进攻")):addTo(self:GetFteLayer())
    :TurnDown():align(display.CENTER_BOTTOM, r.x + r.width/2, r.y + 70)

    return UIKit:PromiseOfOpen("GameUIReplayNew"):next(function(ui)
        ui:DestroyFteLayer()
        ui:DoFte()
        return UIKit:PromiseOfClose("GameUIReplayNew")
    end)
end

return GameUIPVEFteSendTroop
