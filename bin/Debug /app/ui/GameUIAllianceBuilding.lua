local WidgetAllianceBuildingUpgrade = import("..widget.WidgetAllianceBuildingUpgrade")
local GameUIAllianceBuilding = UIKit:createUIClass('GameUIAllianceBuilding', "GameUIWithCommonHeader")



function GameUIAllianceBuilding:ctor(city,title,default_tab,building)
    GameUIAllianceBuilding.super.ctor(self, city, title)
    self.default_tab = default_tab
    self.building = building
end

function GameUIAllianceBuilding:CreateTabButtons(param, cb)
    table.insert(param,1, {
        label = _("升级"),
        tag = "upgrade",
        default = "upgrade" == self.default_tab,
    })
    return GameUIAllianceBuilding.super.CreateTabButtons(self,param,function(tag)
        if tag == "upgrade" then
            self.upgrade_layer:setVisible(true)
        else
            self.upgrade_layer:setVisible(false)
        end
        cb(tag)
    end)
end

function GameUIAllianceBuilding:OnMoveInStage()
    GameUIAllianceBuilding.super.OnMoveInStage(self)
    self.upgrade_layer = WidgetAllianceBuildingUpgrade.new(self.building):addTo(self:GetView())
end

return GameUIAllianceBuilding




