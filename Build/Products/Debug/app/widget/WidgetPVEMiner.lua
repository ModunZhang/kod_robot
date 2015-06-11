local promise = import("..utils.promise")
local SpriteConfig = import("..sprites.SpriteConfig")
local WidgetPVEResource = import("..widget.WidgetPVEResource")
local WidgetPVEMiner = class("WidgetPVEMiner", WidgetPVEResource)

function WidgetPVEMiner:ctor(...)
    WidgetPVEMiner.super.ctor(self, ...)
end
function WidgetPVEMiner:GetTitle()
    return string.format(_("废弃的矿工小屋 等级%d"), self:GetPVEMap():GetIndex())
end
return WidgetPVEMiner


















