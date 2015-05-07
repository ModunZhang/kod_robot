local SpriteConfig = import("..sprites.SpriteConfig")
local WidgetPVEDialog = import(".WidgetPVEDialog")
local WidgetPVEStartAirship = class("WidgetPVEStartAirship", WidgetPVEDialog)

function WidgetPVEStartAirship:ctor(...)
    WidgetPVEStartAirship.super.ctor(self, ...)
end
function WidgetPVEStartAirship:GetTitle()
    return _("飞艇")
end
function WidgetPVEStartAirship:GetDesc()
    return _('手下向你汇报, 飞艇一切准备就绪, "长官希望前往何处?"')
end
function WidgetPVEStartAirship:GetBrief()
    return _("起点")
end
function WidgetPVEStartAirship:SetUpButtons()
    return
        {
            {
                label = _("传送"), 
                icon = "pve_icon_through.png",
                callback = function()
                    UIKit:newWidgetUI("WidgetPVESelectStage",self.user):AddToCurrentScene(true)
                    self:removeFromParent()
                end
            },
            {
                label = _("离开"),
                icon = "pve_icon_leave.png",
            }
        }
end

return WidgetPVEStartAirship




















