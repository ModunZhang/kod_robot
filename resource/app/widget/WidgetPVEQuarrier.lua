local SpriteConfig = import("..sprites.SpriteConfig")
local WidgetPVEResource = import("..widget.WidgetPVEResource")
local WidgetPVEQuarrier = class("WidgetPVEQuarrier", WidgetPVEResource)

function WidgetPVEQuarrier:ctor(...)
    WidgetPVEQuarrier.super.ctor(self, ...)
end
function WidgetPVEQuarrier:GetTitle()
    return string.format("%s %s%d", _("废弃的石匠小屋"), _("等级"), self:GetPVEMap():GetIndex())
end

return WidgetPVEQuarrier















