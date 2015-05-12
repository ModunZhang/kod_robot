local SpriteConfig = import("..sprites.SpriteConfig")
local WidgetPVEDialog = import("..widget.WidgetPVEDialog")
local WidgetPVECrashedAirship = class("WidgetPVECrashedAirship", WidgetPVEDialog)

function WidgetPVECrashedAirship:ctor(...)
    WidgetPVECrashedAirship.super.ctor(self, ...)
end
function WidgetPVECrashedAirship:GetTitle()
    return string.format("%s %s%d", _("坠毁的飞艇"), _("等级"), self:GetPVEMap():GetIndex())
end
function WidgetPVECrashedAirship:GetDesc()
    if self:GetObject():IsSearched() then
        return _("一艘飞艇的残骸, 可惜里面的物资早已被人洗劫一空。")
    elseif self:GetObject():Searched() == 1 then
        return _("强盗眼看不是你的对手, 想要烧毁这里的物资, 如果不阻拦他们那就得不到任何东西。")
    end
    return _("你发现了一艘坠毁的飞艇, 其中的有大量的物资, 但当你走近时却发现那里已经被强盗占领。")
end
function WidgetPVECrashedAirship:SetUpButtons()
    return self:GetObject():IsSearched() and
        { { label = _("离开"), icon = "pve_icon_leave.png", } } or
        { { label = _("进攻"), icon = "pve_icon_fight.png", callback = function() self:Fight() end }, { label = _("离开"), icon = "pve_icon_leave.png", } }
end

return WidgetPVECrashedAirship















