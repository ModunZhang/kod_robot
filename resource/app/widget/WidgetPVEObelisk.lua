local SpriteConfig = import("..sprites.SpriteConfig")
local WidgetPVEDialog = import("..widget.WidgetPVEDialog")
local WidgetPVEObelisk = class("WidgetPVEObelisk", WidgetPVEDialog)

function WidgetPVEObelisk:ctor(...)
    WidgetPVEObelisk.super.ctor(self, ...)
    if self:GetObject():IsUnSearched() then
        local rollback = self:Search()
        self:GetRewardsFromServer():fail(function()
            rollback()
        end)
    end
end
function WidgetPVEObelisk:GetTitle()
    return string.format("%s %s%d", _('方尖碑'), _('等级'), self:GetPVEMap():GetIndex())
end
function WidgetPVEObelisk:GetDesc()
    return _('你发现一座用你从未见过的石头雕刻的石碑。你上前仔细观察一番, 石碑上突然闪现一个神秘的符文没入你的身体, 让你感觉身体中充满了力量。')
end
function WidgetPVEObelisk:SetUpButtons()
    return { { label = _("离开") } }
end

return WidgetPVEObelisk




















