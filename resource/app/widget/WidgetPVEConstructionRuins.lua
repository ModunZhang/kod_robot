local SpriteConfig = import("..sprites.SpriteConfig")
local WidgetPVEDialog = import("..widget.WidgetPVEDialog")
local WidgetPVEConstructionRuins = class("WidgetPVEConstructionRuins", WidgetPVEDialog)

function WidgetPVEConstructionRuins:ctor(...)
    WidgetPVEConstructionRuins.super.ctor(self, ...)
end
function WidgetPVEConstructionRuins:GetTitle()
    return string.format("%s %s%d", _('建筑废墟'), _('等级'), self:GetPVEMap():GetIndex())
end
function WidgetPVEConstructionRuins:GetDesc()
    return self:GetObject():IsSearched()
        and _('你又花费了数小时搜索建筑废墟, 却一无所获。')
        or _('废弃的建筑残骸, 不知道是否能找到一些有价值的东西, 是否愿意花费3点体力搜索这里?')
end
function WidgetPVEConstructionRuins:SetUpButtons()
    return self:GetObject():IsSearched() and
        { { label = _("离开"), icon = "pve_icon_leave.png", } } or
        { { 
            label = _("搜索"), 
            icon = "alliacne_search_29x33.png",
            callback = function()
            if self:UseStrength(3) then
                local rollback = self:Search()
                self:GetRewardsFromServer():fail(function()
                    rollback()
                end)
                self:removeFromParent()
            end
        end }, { label = _("离开"), icon = "pve_icon_leave.png", } }
end

return WidgetPVEConstructionRuins

















