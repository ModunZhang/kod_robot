local SpriteConfig = import("..sprites.SpriteConfig")
local WidgetPVEResource = import("..widget.WidgetPVEResource")
local WidgetPVEWoodcutter = class("WidgetPVEWoodcutter", WidgetPVEResource)

function WidgetPVEWoodcutter:ctor(...)
    WidgetPVEWoodcutter.super.ctor(self, ...)
end
function WidgetPVEWoodcutter:GetTitle()
    return string.format(_("废弃的木工小屋 等级%d"), self:GetPVEMap():GetIndex())
end

return WidgetPVEWoodcutter















