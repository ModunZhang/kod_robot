local GameUIFteHospital = UIKit:createUIClass('GameUIFteHospital',"GameUIHospital")


function GameUIFteHospital:ctor(...)
    GameUIFteHospital.super.ctor(self, ...)
    self.__type  = UIKit.UITYPE.BACKGROUND
end

--fte
local mockData = import("..fte.mockData")
local WidgetFteArrow = import("..widget.WidgetFteArrow")
function GameUIFteHospital:Find()
    return self.treat_all_button
end
function GameUIFteHospital:PromiseOfFte()
    self:GetFteLayer():SetTouchObject(self:Find())
    local r = self:Find():getCascadeBoundingBox()
    local arrow = WidgetFteArrow.new(_("点击治愈")):addTo(self:GetFteLayer()):TurnRight()
        :align(display.RIGHT_CENTER, r.x - 10, r.y + r.height/2)

    local name, count
    for k,v in pairs(DataManager:getFteData().woundedSoldiers) do
        if v > 0 then
            name, count = k, v
            break
        end
    end
    assert(name)
    assert(count > 0)

    self:Find():removeEventListenersByEvent("CLICKED_EVENT")
    self:Find():onButtonClicked(function()
        arrow:removeFromParent()
        self:Find():setButtonEnabled(false)
        mockData.TreatSoldier(name, count)
    end)

    return self.city:GetUser():PromiseOfBeginTreat():next(function()
        return self:PromsieOfExit("GameUIFteHospital")
    end)
end


return GameUIFteHospital


