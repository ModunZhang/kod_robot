local WidgetResources = import('..widget.WidgetResources')
local GameUIWarehouse = UIKit:createUIClass('GameUIWarehouse',"GameUIUpgradeBuilding")

function GameUIWarehouse:ctor(city,building)
    GameUIWarehouse.super.ctor(self,city,_("仓库"),building)
end

function GameUIWarehouse:OnMoveInStage()
    GameUIWarehouse.super.OnMoveInStage(self)
    self:CreateTabButtons({
        {
            label = _("资源"),
            tag = "resource",
        },
    },function(tag)
        if tag == 'resource' then
            if not self.resource_layer then
                self.resource_layer = WidgetResources.new():addTo(self:GetView())
            end
            self.resource_layer:setVisible(true)
        else
            if self.resource_layer then
                self.resource_layer:setVisible(false)
            end
        end
    end):pos(display.cx, display.top - 924)

end
function GameUIWarehouse:onExit()
    GameUIWarehouse.super.onExit(self)
end

return GameUIWarehouse

