local SpriteConfig = import("..sprites.SpriteConfig")
local WidgetPVEDialog = import("..widget.WidgetPVEDialog")
local WidgetPVEWarriorsTomb = class("WidgetPVEWarriorsTomb", WidgetPVEDialog)

function WidgetPVEWarriorsTomb:ctor(...)
    WidgetPVEWarriorsTomb.super.ctor(self, ...)
end
function WidgetPVEWarriorsTomb:GetTitle()
    return string.format("%s %s%d", _('勇士之墓'), _('等级'), self:GetPVEMap():GetIndex())
end
function WidgetPVEWarriorsTomb:GetDesc()
    return self:GetObject():IsSearched()
        and _('陵墓之中仿佛有几个人形虚影正在向你招手, 你不禁背心一凉, 还是赶紧离开吧')
        or _('你发现一些未被安葬的战士的遗骸, 是否花费10个金龙币将他们安葬?')
end
function WidgetPVEWarriorsTomb:SetUpButtons()
    return self:GetObject():IsSearched() and
        { { label = _("离开"), icon = "pve_icon_leave.png", } } or
        {
            {
                label = _("安葬"), 
                callback = function()
                    if self:HasGem(10) then
                        local rollback = self:Search()
                        self:GetRewardsFromServer(nil, 10):fail(function()
                            rollback()
                        end)
                        self:removeFromParent()
                    end
                end
            },
            {
                label = _("离开"),
                icon = "pve_icon_leave.png",
            }
        }
end

return WidgetPVEWarriorsTomb



















