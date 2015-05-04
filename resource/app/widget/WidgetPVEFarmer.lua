local SpriteConfig = import("..sprites.SpriteConfig")
local WidgetPVEResource = import("..widget.WidgetPVEResource")
local WidgetPVEFarmer = class("WidgetPVEFarmer", WidgetPVEResource)

function WidgetPVEFarmer:ctor(...)
    WidgetPVEFarmer.super.ctor(self, ...)
end
function WidgetPVEFarmer:GetTitle()
    return string.format("%s %s%d", _('废弃的农夫小屋'), _('等级'), self:GetPVEMap():GetIndex())
end


return WidgetPVEFarmer















