local window = import("..utils.window")
local WidgetMaterials = import("..widget.WidgetMaterials")

local MaterialManager = import("..entity.MaterialManager")

local GameUIMaterialDepot = UIKit:createUIClass("GameUIMaterialDepot", "GameUIUpgradeBuilding")
function GameUIMaterialDepot:ctor(city,building,default_tab)
    GameUIMaterialDepot.super.ctor(self, city, _("材料库房"),building,default_tab)
end

function GameUIMaterialDepot:OnMoveInStage()
    GameUIMaterialDepot.super.OnMoveInStage(self)
    self:CreateTabButtons({
        {
            label = _("信息"),
            tag = "info",
        },
    },function(tag)
        if tag == 'info' then
            if not self.info_layer then
                self.info_layer = WidgetMaterials.new(self.city,self.building):addTo(self:GetView())
            end
            self.info_layer:setVisible(true)
        else
            if self.info_layer then
                self.info_layer:setVisible(false)
            end
        end
    end):pos(window.cx, window.bottom + 34)
end

return GameUIMaterialDepot

