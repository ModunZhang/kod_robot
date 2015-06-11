local window = import("..utils.window")
local WidgetMaterials = import("..widget.WidgetMaterials")
local WidgetCitizen = import("..widget.WidgetCitizen")
local UIListView = import(".UIListView")


local WidgetResources = import('..widget.WidgetResources')

local GameUIResourceOverview = UIKit:createUIClass("GameUIResourceOverview","GameUIWithCommonHeader")

function GameUIResourceOverview:ctor(city)
    GameUIResourceOverview.super.ctor(self,city,_("资源总览"))
end

function GameUIResourceOverview:onEnter()
    GameUIResourceOverview.super.onEnter(self)
    self:CreateTabButtons({
        {
            label = _("资源"),
            tag = "resource",
            default = true
        },
        {
            label = _("材料"),
            tag = "material",
        },
        {
            label = _("城民"),
            tag = "citizen",
        },
    }, function(tag)
        if tag == 'resource' then
            self.resource_layer:setVisible(true)
        else
            self.resource_layer:setVisible(false)
        end
        if tag == 'material' then
            self.material_layer:setVisible(true)
        else
            self.material_layer:setVisible(false)
        end
        if tag == 'citizen' then
            self.citizen_layer:setVisible(true)
        else
            self.citizen_layer:setVisible(false)
        end
    end):pos(window.cx, window.bottom + 34)
end
function GameUIResourceOverview:CreateBetweenBgAndTitle()
    GameUIResourceOverview.super.CreateBetweenBgAndTitle(self.material_layer)
    -- 资源
    self.resource_layer = WidgetResources.new():addTo(self:GetView())
    -- 材料
    self.material_layer = WidgetMaterials.new(self.city,self.city:GetFirstBuildingByType("materialDepot")):addTo(self:GetView())
    -- 城民
    self.citizen_layer = WidgetCitizen.new(self.city):addTo(self:GetView())
end
function GameUIResourceOverview:onExit()
    GameUIResourceOverview.super.onExit(self)

end
function GameUIResourceOverview:OnResourceChanged(resource_manager)
    GameUIResourceOverview.super.OnResourceChanged(self,resource_manager)
end

return GameUIResourceOverview



