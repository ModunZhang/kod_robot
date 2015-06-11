local SpriteConfig = import("..sprites.SpriteConfig")
local WidgetPVEResource = import("..widget.WidgetPVEResource")
local WidgetPVEQuarrier = class("WidgetPVEQuarrier", WidgetPVEResource)

function WidgetPVEQuarrier:ctor(...)
    WidgetPVEQuarrier.super.ctor(self, ...)
end
function WidgetPVEQuarrier:GetTitle()
    return string.format(_("废弃的石匠小屋 等级%d"), self:GetPVEMap():GetIndex())
end

return WidgetPVEQuarrier















