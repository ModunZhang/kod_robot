local WidgetRecruitSoldier = import("..widget.WidgetRecruitSoldier")
local GameUIFteBarracks = UIKit:createUIClass('GameUIFteBarracks',"GameUIBarracks")


function GameUIFteBarracks:ctor(...)
	GameUIFteBarracks.super.ctor(self, ...)
	self.__type  = UIKit.UITYPE.BACKGROUND
end

--fte
local WidgetFteArrow = import("..widget.WidgetFteArrow")
function GameUIFteBarracks:Find()
    return self.soldier_map["swordsman"]
end
function GameUIFteBarracks:PromiseOfFte()
    self.list_view:getScrollNode():setTouchEnabled(false)
    self.list_view.touchNode_:setTouchEnabled(false)
    self:Find():setTouchSwallowEnabled(true)

    self:GetFteLayer():SetTouchObject(self:Find())
    local r = self:Find():getCascadeBoundingBox()
    WidgetFteArrow.new(_("点击招募步兵")):addTo(self:GetFteLayer()):TurnLeft()
    :align(display.LEFT_CENTER, r.x + r.width + 10, r.y + r.height/2)
    
    return WidgetRecruitSoldier:PormiseOfOpen():next(function(ui)
        ui:removeNodeEventListener(ui._nextScriptEventHandleIndex_)
        self:GetFteLayer():removeFromParent()
        return ui:PormiseOfFte()
    end):next(function()
        return self:PromsieOfExit("GameUIFteBarracks")
    end)
end
function GameUIFteBarracks:FindSpecial()
    return self.soldier_map["skeletonWarrior"]
end
function GameUIFteBarracks:PromiseOfFteSpecial()
    self.special_list_view:getScrollNode():setTouchEnabled(false)
    self.special_list_view.touchNode_:setTouchEnabled(false)
    self:FindSpecial():setTouchSwallowEnabled(true)

    self:GetFteLayer():SetTouchObject(self:FindSpecial())
    local r = self:FindSpecial():getCascadeBoundingBox()
    WidgetFteArrow.new(_("点击查看")):addTo(self:GetFteLayer()):TurnLeft()
    :align(display.LEFT_CENTER, r.x + r.width + 10, r.y + r.height/2)


    return WidgetRecruitSoldier:PormiseOfOpen():next(function(ui)
        ui.__type = UIKit.UITYPE.BACKGROUND
        ui:removeNodeEventListener(ui._nextScriptEventHandleIndex_)
        function ui:GetRecruitSpecialTime()
            return true
        end
        self:GetFteLayer():removeFromParent()
        return ui:PromiseOfFteSpecial()
    end):next(function()
        return self:PromsieOfExit("GameUIFteBarracks")
    end)
end
function GameUIFteBarracks:GetRecruitSpecialTime()
    return true, nil
end


return GameUIFteBarracks