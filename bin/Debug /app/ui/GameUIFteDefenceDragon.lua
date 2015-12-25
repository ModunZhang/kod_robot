local GameUIFteDefenceDragon = UIKit:createUIClass("GameUIFteDefenceDragon", "GameUIAllianceSendTroops")
local DiffFunction = import("..utils.DiffFunction")




function GameUIFteDefenceDragon:ctor(...)
    local delta = DiffFunction(DataManager:getFteData(), {{"soldiers.swordsman_1", 10}})
    DataManager:setFteUserDeltaData(delta)


    GameUIFteDefenceDragon.super.ctor(self, ...)
    self.__type  = UIKit.UITYPE.BACKGROUND

end

local mockData = import("..fte.mockData")
local WidgetFteArrow = import("..widget.WidgetFteArrow")
function GameUIFteDefenceDragon:Find()
    return self.march_btn
end
function GameUIFteDefenceDragon:OnMoveInStage()
	GameUIFteDefenceDragon.super.OnMoveInStage(self)

	local r = self:Find():getCascadeBoundingBox()
    self:GetFteLayer():SetTouchObject(self:Find())
    WidgetFteArrow.new(_("点击按钮：驻防")):addTo(self:GetFteLayer())
    :TurnRight():align(display.RIGHT_CENTER, r.x - 10, r.y + r.height/2)

    self:Find():removeEventListenersByEvent("CLICKED_EVENT")
    self:Find():onButtonClicked(function()
        local delta = DiffFunction(DataManager:getFteData(), {{"soldiers.swordsman_1", 0}})
        DataManager:setFteUserDeltaData(delta)
        self:DestroyFteLayer()
        self:LeftButtonClicked()
    end)
end

return GameUIFteDefenceDragon