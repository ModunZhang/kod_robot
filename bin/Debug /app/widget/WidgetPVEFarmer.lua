local SpriteConfig = import("..sprites.SpriteConfig")
local WidgetPVEResource = import("..widget.WidgetPVEResource")
local WidgetPVEFarmer = class("WidgetPVEFarmer", WidgetPVEResource)

function WidgetPVEFarmer:ctor(...)
    WidgetPVEFarmer.super.ctor(self, ...)
end
function WidgetPVEFarmer:GetTitle()
    return string.format(_("废弃的农夫小屋 等级%d"), self:GetPVEMap():GetIndex())
end


return WidgetPVEFarmer















