local SpriteConfig = import("..sprites.SpriteConfig")
local WidgetPVEResource = import("..widget.WidgetPVEResource")
local WidgetPVEWoodcutter = class("WidgetPVEWoodcutter", WidgetPVEResource)

function WidgetPVEWoodcutter:ctor(...)
    WidgetPVEWoodcutter.super.ctor(self, ...)
end
function WidgetPVEWoodcutter:GetTitle()
    return string.format("%s %s%d", _('废弃的木工小屋'), _('等级'), self:GetPVEMap():GetIndex())
end

return WidgetPVEWoodcutter















