local SpriteConfig = import("..sprites.SpriteConfig")
local WidgetPVEDialog = import("..widget.WidgetPVEDialog")
local WidgetPVECamp = class("WidgetPVECamp", WidgetPVEDialog)

function WidgetPVECamp:ctor(...)
    WidgetPVECamp.super.ctor(self, ...)
end
function WidgetPVECamp:GetTitle()
    return string.format("%s %s%d", _('野外营地'), _('等级'), self:GetPVEMap():GetIndex())
end
function WidgetPVECamp:GetDesc()
    if self:GetObject():IsSearched() then
        return _('你看到营地有火光, 走到近前却是空空荡荡。你感觉纳闷, 这里怎么如此眼熟。')
    elseif self:GetObject():Searched() == 1 then
        return _('你击败了部队的主力, 但部队剩下的士兵向你发起了冲锋。')
    end
    return _('你大胆地闯入了一支不明身份部队的营地, 一场战斗一触即发。')
end
function WidgetPVECamp:SetUpButtons()
    return self:GetObject():IsSearched() and
        { { label = _("离开") } } or
        { { label = _("进攻"), callback = function() self:Fight() end }, { label = _("离开") } }
end

return WidgetPVECamp



















