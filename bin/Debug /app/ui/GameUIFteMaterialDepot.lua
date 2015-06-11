local GameUINpc = import("..ui.GameUINpc")
local promise = import("..utils.promise")
local cocos_promise = import("..utils.cocos_promise")
local MaterialManager = import("..entity.MaterialManager")
local GameUIFteMaterialDepot = UIKit:createUIClass("GameUIFteMaterialDepot", "GameUIMaterialDepot")
function GameUIFteMaterialDepot:ctor(...)
    GameUIFteMaterialDepot.super.ctor(self,...)
    self.__type  = UIKit.UITYPE.BACKGROUND
end


--fte
local mockData = import("..fte.mockData")
local WidgetFteArrow = import("..widget.WidgetFteArrow")
function GameUIFteMaterialDepot:Find()
	return self.info_layer.material_box_table[MaterialManager.MATERIAL_TYPE.SOLDIER]["soulStone"]:GetButton()
end
function GameUIFteMaterialDepot:PromiseOfFte()
	self.info_layer.material_listview:getScrollNode():setTouchEnabled(false)
    self.info_layer.material_listview.touchNode_:setTouchEnabled(false)
    self:Find():setTouchSwallowEnabled(true)
    self:Find():removeEventListenersByEvent("CLICKED_EVENT")
    self:Find():onButtonClicked(function()
        self:Find():setButtonEnabled(false)
        self:GetFteLayer():removeFromParent()
        self:GetFteLayer()

        local ui = UIKit:newWidgetUI("WidgetMaterialDetails",MaterialManager.MATERIAL_TYPE.SOLDIER,"soulStone",0):AddToCurrentScene()
        ui.__type = UIKit.UITYPE.BACKGROUND

        ui:Find().button:removeEventListenersByEvent("CLICKED_EVENT")
        ui:Find().button:onButtonClicked(function()
            app:EnterPVEFteScene(1)
        end)
        ui:GetFteLayer():SetTouchObject(ui:Find())
	    local r = ui:Find():getCascadeBoundingBox()
	    WidgetFteArrow.new(_("点击查看")):addTo(ui:GetFteLayer()):TurnUp()
	    :align(display.TOP_CENTER, r.x + r.width/2, r.y - 10)

	    mockData.CheckMaterials()
    end)


    return cocos_promise.defer():next(function()
        return GameUINpc:PromiseOfSay(
            {words = _("果然没有...不过也碍事...我的探子已经找到了他们的一处聚集地,请大人随我来"), npc = "man"}
        ):next(function()

        	self:GetFteLayer():SetTouchObject(self:Find())
		    local r = self:Find():getCascadeBoundingBox()
		    WidgetFteArrow.new(_("点击查看")):addTo(self:GetFteLayer()):TurnDown()
		    :align(display.BOTTOM_CENTER, r.x + r.width/2, r.y + r.height + 10)

		    return GameUINpc:PromiseOfLeave()
        end)
    end):next(function()
    	return promise.new()
    end)
end



return GameUIFteMaterialDepot

