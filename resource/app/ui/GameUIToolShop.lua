--
-- Author: gaozhou
-- Date: 2014-08-18 14:33:28
--
local window = import("..utils.window")
local WidgetManufacture = import("..widget.WidgetManufacture")
local GameUIToolShop = UIKit:createUIClass("GameUIToolShop", "GameUIUpgradeBuilding")

function GameUIToolShop:ctor(city, toolShop, default_tab)
    GameUIToolShop.super.ctor(self, city, _("工具作坊"), toolShop, default_tab)
    self.tool_shop_city = city
    self.toolShop = toolShop
end
function GameUIToolShop:OnMoveInStage()
    GameUIToolShop.super.OnMoveInStage(self)
    self:TabButtons()
end
function GameUIToolShop:onExit()
    GameUIToolShop.super.onExit(self)
end
function GameUIToolShop:TabButtons()
    self:CreateTabButtons({
        {
            label = _("制作"),
            tag = "manufacture",
        }
    },
    function(tag)
        if tag == 'upgrade' then
            if self.manufacture then
                self.manufacture:removeFromParent()
                self.manufacture = nil
            end
        elseif tag == "manufacture" then
            self.manufacture = WidgetManufacture.new(self.toolShop):addTo(self:GetView())
        end
    end):pos(window.cx, window.bottom + 34)
end




return GameUIToolShop




