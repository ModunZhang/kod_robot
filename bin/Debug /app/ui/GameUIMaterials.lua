--
-- Author: gaozhou
-- Date: 2014-08-18 14:33:28
--
local window = import("..utils.window")
local GameUIEquip = import(".GameUIEquip")
local WidgetManufacture = import("..widget.WidgetManufacture")
local GameUIMaterials = UIKit:createUIClass("GameUIMaterials", "GameUIWithCommonHeader")

function GameUIMaterials:ctor(toolShop, blackSmith)
    GameUIMaterials.super.ctor(self, toolShop:BelongCity(), _("制造材料"), blackSmith)
    self.dragon_map = {}
    self.toolShop = toolShop
    self.blackSmith = blackSmith
end
function GameUIMaterials:OnMoveInStage()
    GameUIMaterials.super.OnMoveInStage(self)
    self.euip_view = GameUIEquip.new(self, self.blackSmith)
    self.euip_view:Init()
    self:TabButtons()
end
function GameUIMaterials:onExit()
    self.euip_view:UnInit()
    GameUIMaterials.super.onExit(self)
end
function GameUIMaterials:TabButtons()
    local tab_params = {}
    if self.toolShop:IsUnlocked() then
        table.insert(tab_params, {
            label = _("制造材料"),
            tag = "manufacture",
            default = true,
        })
    end
    if self.blackSmith:IsUnlocked() then
        table.insert(tab_params, {
            label = _("红龙装备"),
            tag = "redDragon",
            default = not self.toolShop:IsUnlocked()
        })
        table.insert(tab_params, {
            label = _("蓝龙装备"),
            tag = "blueDragon",
        })
        table.insert(tab_params, {
            label = _("绿龙装备"),
            tag = "greenDragon",
        })
    end
    self:CreateTabButtons(tab_params,
        function(tag)
            if tag == 'manufacture' then
                self.euip_view:HideAll()

                if self.toolShop:IsUnlocked() then
                    self.manufacture = WidgetManufacture.new(self.toolShop):addTo(self:GetView())
                end
            else
                if self.manufacture then
                    self.manufacture:removeFromParent()
                    self.manufacture = nil
                end
                if self.blackSmith:IsUnlocked() then
                    self.euip_view:SwitchToDragon(tag)
                end
            end
        end):pos(window.cx, window.bottom + 34)
end


return GameUIMaterials















