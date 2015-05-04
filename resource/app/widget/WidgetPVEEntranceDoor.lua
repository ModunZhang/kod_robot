local SpriteConfig = import("..sprites.SpriteConfig")
local WidgetPVEDialog = import("..widget.WidgetPVEDialog")
local WidgetPVEEntranceDoor = class("WidgetPVEEntranceDoor", WidgetPVEDialog)

function WidgetPVEEntranceDoor:ctor(...)
    WidgetPVEEntranceDoor.super.ctor(self, ...)
end
function WidgetPVEEntranceDoor:GetTitle()
    return string.format("%s %s%d", _('异界之门'), _('等级'), self:GetPVEMap():GetIndex())
end
function WidgetPVEEntranceDoor:GetDesc()
    return self:GetObject():IsSearched() 
    and _('在没有什么能阻挡你前进了, 你可以直接前往下一个关卡。')
    or _('你能感觉到一个一场强大的生物驻守在这里, 阻挡着你继续前进, 但想要前往下一关卡必须击败它。')
end
function WidgetPVEEntranceDoor:SetUpButtons()
    return self:GetObject():IsSearched() and
        { { label = _("传送"), callback = function() self:GotoNext() end }, { label = _("离开") } } or
        { { label = _("进攻"), callback = function() self:Fight() end }, { label = _("离开") } }
end

return WidgetPVEEntranceDoor















