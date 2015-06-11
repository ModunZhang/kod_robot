local GameUIFteUpgradeTechnology = UIKit:createUIClass('GameUIFteUpgradeTechnology',"GameUIUpgradeTechnology")

function GameUIFteUpgradeTechnology:ctor(...)
	GameUIFteUpgradeTechnology.super.ctor(self, ...)
	self.__type  = UIKit.UITYPE.BACKGROUND
end
--fte
local mockData = import("..fte.mockData")
local WidgetFteArrow = import("..widget.WidgetFteArrow")
function GameUIFteUpgradeTechnology:Find()
    return self.upgrade_button.button
end
function GameUIFteUpgradeTechnology:PromiseOfFte(p)
    self:GetFteLayer():SetTouchObject(self:Find())
    local r = self:Find():getCascadeBoundingBox()
    WidgetFteArrow.new(_("开始研发")):addTo(self:GetFteLayer()):TurnRight()
    :align(display.RIGHT_CENTER, r.x - 10, r.y + r.height/2)

    self:Find():removeEventListenersByEvent("CLICKED_EVENT")
    self:Find():onButtonClicked(function()
    	self:Find():setButtonEnabled(false)
    	self:LeftButtonClicked()
    	UIKit:GetUIInstance("GameUIFteAcademy"):LeftButtonClicked()
    	mockData.Research()
    	p:resolve()
    end)
end


return GameUIFteUpgradeTechnology